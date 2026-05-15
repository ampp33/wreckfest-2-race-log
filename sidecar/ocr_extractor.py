"""
Wreckfest screenshot OCR extractor.

Supports three screen types:

  event   — pre-race lobby: extracts track name + variation
  tune    — tune tab: detects active position on each slider
  results — race results table: extracts your row by username

Regions are defined for a 3840x2152 reference resolution and auto-scaled to
whatever resolution the actual screenshot is.  Override them in config.json →
"regions" if the defaults don't align after looking at the debug crops.
"""

from __future__ import annotations
import re
import numpy as np
import cv2
from PIL import Image
import pytesseract

# ─── Reference resolution & regions ───────────────────────────────────────────
# All (x1, y1, x2, y2) values are in 3840x2152 space.
# Call scale_regions(regions, img) to get pixel-accurate values for any image.

BASE_W, BASE_H = 3840, 2152

DEFAULT_REGIONS: dict[str, tuple[int, int, int, int]] = {
    # ── Classification anchors ─────────────────────────────────────────────────
    # "RESULTS" big text, top-left
    "classify_results": (0,   0,   600,  180),
    # "SUSPENSION" header in the tune panel
    "classify_tune":    (0,   380, 600,  510),
    # "TRACK LENGTH" / "SURFACE" stats block, left panel
    "classify_event":   (0,   550, 600,  830),

    # ── Event / pre-race screen ───────────────────────────────────────────────
    # Broad left panel: we OCR it and parse out the track + variation lines
    "event_panel":      (50,  190, 1200, 650),

    # ── Tune screen — slider track strips ─────────────────────────────────────
    # These are NARROW horizontal strips (≈30px tall) that contain only the
    # slider dots.  The active dot is a filled white circle = larger bright blob.
    "slider_suspension":    (55, 442, 840, 472),
    "slider_gear_ratio":    (55, 577, 840, 607),
    "slider_differential":  (55, 794, 840, 824),
    "slider_brake_balance": (55, 968, 840, 998),

    # ── Results screen ────────────────────────────────────────────────────────
    "results_table":    (900, 160, 3840, 1100),
}

SLIDER_LABELS: dict[str, list[str]] = {
    "suspension":    ["soft",     "standard", "stiff"],
    "gear_ratio":    ["short",    "standard", "long"],
    "differential":  ["open",     "limited",  "locked"],
    "brake_balance": ["rear",     "middle",   "front"],
}

_TESS_BLOCK  = "--oem 1 --psm 6"   # block of text
_TESS_LINE   = "--oem 1 --psm 7"   # single line
_TESS_SPARSE = "--oem 1 --psm 11"  # sparse text (mixed layout)


# ─── Region scaling ────────────────────────────────────────────────────────────

def scale_regions(regions: dict, img: Image.Image) -> dict:
    """Scale regions from the 3840x2152 reference to img's actual resolution."""
    w, h = img.size
    sx, sy = w / BASE_W, h / BASE_H
    scaled = {}
    for name, (x1, y1, x2, y2) in regions.items():
        scaled[name] = (
            int(x1 * sx), int(y1 * sy),
            int(x2 * sx), int(y2 * sy),
        )
    return scaled


# ─── Image helpers ─────────────────────────────────────────────────────────────

def load_image(path: str) -> Image.Image:
    return Image.open(path).convert("RGB")


def _crop(img: Image.Image, region: tuple) -> Image.Image:
    return img.crop(region)


def _to_gray(img: Image.Image) -> np.ndarray:
    return np.array(img.convert("L"))


def _preprocess(img: Image.Image, scale: float = 2.0) -> Image.Image:
    """
    Scale up + Otsu binarisation.

    Otsu's method auto-selects the threshold from the image histogram —
    much more robust than a hard-coded value across different monitors / HDR.
    """
    gray = _to_gray(img)
    if scale != 1.0:
        h, w = gray.shape
        gray = cv2.resize(gray, (int(w * scale), int(h * scale)),
                          interpolation=cv2.INTER_CUBIC)
    # Otsu picks the optimal split between dark background and bright text
    _, thresh = cv2.threshold(gray, 0, 255,
                              cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return Image.fromarray(thresh)


def _ocr(img: Image.Image, config: str = _TESS_BLOCK,
         scale: float = 2.0) -> str:
    processed = _preprocess(img, scale)
    return pytesseract.image_to_string(processed, config=config).strip()


def _ocr_with_data(img: Image.Image, scale: float = 2.0) -> list[dict]:
    """Word list with bounding boxes, filtered to confident detections."""
    processed = _preprocess(img, scale)
    raw = pytesseract.image_to_data(
        processed,
        output_type=pytesseract.Output.DICT,
        config=_TESS_SPARSE,
    )
    words = []
    for i, text in enumerate(raw["text"]):
        text = text.strip()
        conf = int(raw["conf"][i])
        if text and conf > 20:
            words.append({
                "text":   text,
                "left":   int(raw["left"][i]   / scale),
                "top":    int(raw["top"][i]    / scale),
                "width":  int(raw["width"][i]  / scale),
                "height": int(raw["height"][i] / scale),
                "conf":   conf,
            })
    return words


# ─── Screen classification ─────────────────────────────────────────────────────

def classify_screen(img: Image.Image,
                    regions: dict | None = None) -> str:
    """
    Returns 'event', 'tune', 'results', or 'unknown'.

    Uses three small, screen-specific anchor regions instead of one corner,
    so tune and results screens aren't misclassified as event.
    """
    r = scale_regions({**DEFAULT_REGIONS, **(regions or {})}, img)

    # Results: "RESULTS" or "CONTINUE" in the top-left
    text = _ocr(_crop(img, r["classify_results"]), scale=1.5).upper()
    if "RESULTS" in text or "CONTINUE" in text:
        return "results"

    # Tune: "SUSPENSION" header is unique to the tune panel
    text = _ocr(_crop(img, r["classify_tune"]), scale=1.5).upper()
    if "SUSPENSION" in text:
        return "tune"

    # Event: "TRACK LENGTH" or "SURFACE" in the stats block
    text = _ocr(_crop(img, r["classify_event"]), scale=1.5).upper()
    if any(kw in text for kw in ("TRACK LENGTH", "SURFACE", "GRID SIZE", "LAPS")):
        return "event"

    return "unknown"


# ─── Event screen ──────────────────────────────────────────────────────────────

def extract_event_screen(img: Image.Image,
                          regions: dict | None = None) -> dict:
    """
    OCR the whole left panel and pick out the track name + variation.

    The track name is the first long, all-caps, non-numeric line.
    The variation is the next all-caps, non-numeric line after it.
    We skip short fragments, numbers, and known UI labels.

    Using a broad region is more robust than tiny fixed-coordinate crops
    because we don't need pixel-perfect alignment.
    """
    r = scale_regions({**DEFAULT_REGIONS, **(regions or {})}, img)
    panel_text = _ocr(_crop(img, r["event_panel"]),
                      config=_TESS_BLOCK, scale=1.5)

    _SKIP = {"CUSTOM", "EVENT", "BANGER", "RACE", "Q", "E",
             "STANDINGS", "DIFFICULTY", "TUNE", "TRACK", "LENGTH",
             "SURFACE", "LAPS", "GRID", "SIZE", "GRAVEL", "TARMAC",
             "DIRT", "SNOW", "ASPHALT"}

    candidates = []
    for raw_line in panel_text.splitlines():
        line = _clean(raw_line).upper()
        if len(line) < 4:
            continue
        words = line.split()
        # Skip lines that are entirely UI chrome or numeric
        if all(w in _SKIP or w.isdigit() or w.replace("%", "").isdigit()
               for w in words):
            continue
        # Must be mostly alphabetic (track names are words, not stats)
        alpha_ratio = sum(c.isalpha() for c in line) / max(len(line), 1)
        if alpha_ratio < 0.6:
            continue
        candidates.append(line)

    track     = candidates[0] if len(candidates) > 0 else ""
    variation = candidates[1] if len(candidates) > 1 else ""
    return {"track": track, "variation": variation}


# ─── Tune screen ───────────────────────────────────────────────────────────────

def _slider_active_position(strip_img: Image.Image,
                             labels: list[str]) -> str:
    """
    Detect which slider notch is active using blob analysis.

    The active dot is a FILLED white circle — it produces a larger connected
    bright blob than the hairline tick marks at inactive positions.

    Steps:
      1. Binarise with Otsu
      2. Find connected components (blobs)
      3. Keep blobs that sit roughly on the horizontal centre line
      4. The LARGEST blob is the active dot
      5. Map its centroid X to the nearest label slot
    """
    gray  = _to_gray(strip_img)
    _, bw = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    n, labels_map, stats, centroids = cv2.connectedComponentsWithStats(bw)

    h, w = bw.shape
    mid_y = h / 2
    best_area = 0
    best_cx   = w // 2  # fallback to middle

    for i in range(1, n):  # skip background (component 0)
        area = stats[i, cv2.CC_STAT_AREA]
        cy   = centroids[i][1]
        cx   = centroids[i][0]
        # Ignore blobs far from the vertical centre (they're label text leaking in)
        if abs(cy - mid_y) > h * 0.6:
            continue
        if area > best_area:
            best_area = area
            best_cx   = cx

    relative = best_cx / max(w - 1, 1)
    n_labels  = len(labels)
    idx = min(n_labels - 1, int(round(relative * (n_labels - 1))))
    return labels[idx]


def extract_tune_screen(img: Image.Image,
                         regions: dict | None = None) -> dict:
    r = scale_regions({**DEFAULT_REGIONS, **(regions or {})}, img)
    result = {}
    for name, label_list in SLIDER_LABELS.items():
        key = f"slider_{name}"
        if key in r:
            strip = _crop(img, r[key])
            result[name] = _slider_active_position(strip, label_list)
    return result


# ─── Results screen ────────────────────────────────────────────────────────────

def extract_results_screen(img: Image.Image,
                            username: str,
                            regions: dict | None = None) -> dict | None:
    r = scale_regions({**DEFAULT_REGIONS, **(regions or {})}, img)
    table_img = _crop(img, r["results_table"])
    words = _ocr_with_data(table_img, scale=2.0)

    uname_upper = username.upper()
    hits = [w for w in words if uname_upper in w["text"].upper()]
    if not hits:
        return None

    ref_y = hits[0]["top"]
    ref_h = max(hits[0]["height"], 15)
    tolerance = ref_h * 1.2

    row_words = sorted(
        [w for w in words if abs(w["top"] - ref_y) <= tolerance],
        key=lambda w: w["left"],
    )
    row_text = " ".join(w["text"] for w in row_words)
    return _parse_results_row(row_text, username)


def _parse_results_row(row_text: str, username: str) -> dict:
    result: dict = {"raw": row_text}

    pos_m = re.match(r"^0*(\d+)\s+", row_text)
    if pos_m:
        result["place"] = int(pos_m.group(1))

    times = re.findall(r"\d{2}:\d{2}\.\d{3}", row_text)
    if times:
        result["total_time"]    = times[0]
        result["total_time_ms"] = _time_to_ms(times[0])
    if len(times) >= 2:
        result["best_lap"]    = times[1]
        result["lap_time_ms"] = _time_to_ms(times[1])

    car_text = row_text
    if pos_m:
        car_text = car_text[pos_m.end():]
    car_text = re.sub(re.escape(username), "", car_text, flags=re.IGNORECASE)
    car_text = re.sub(r"\b[A-Z]\s?\d{3}\b", "", car_text)
    for t in times:
        car_text = car_text.replace(t, "")
    result["car"] = _clean(car_text)

    return result


def _time_to_ms(t: str) -> int:
    m = re.match(r"(\d+):(\d+)\.(\d+)", t)
    if not m:
        return 0
    return (int(m.group(1)) * 60 + int(m.group(2))) * 1000 + int(m.group(3))


def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()
