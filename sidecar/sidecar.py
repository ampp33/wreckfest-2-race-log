import sys, os, subprocess

def _use_venv():
    here = os.path.dirname(os.path.abspath(__file__))
    venv_py = os.path.join(here, ".venv",
                           "Scripts" if sys.platform == "win32" else "bin",
                           "python.exe" if sys.platform == "win32" else "python3")
    if os.path.exists(venv_py) and os.path.abspath(sys.executable) != os.path.abspath(venv_py):
        sys.exit(subprocess.call([venv_py] + sys.argv))
_use_venv()

"""
Wreckfest Race Log — screenshot sidecar.

Captures the screen at a configurable interval, classifies the Wreckfest UI
screen, and collects race context across screens:

  event screen  → saves track + variation
  tune screen   → saves tuning settings
  results screen → combines stored context + result row, submits to the API

Run as normal user — no admin rights needed (unlike the memory approach).

Usage:
    python sidecar.py [--config path/to/config.json]
"""

import argparse
import json
import sys
import time

import ocr_extractor as ocr
import api_client
from screen_capture import capture_loop


def load_config(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _slug(text: str) -> str:
    """Very rough text → slug for matching; real slugs come from config.json."""
    import re
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def main() -> None:
    parser = argparse.ArgumentParser(description="Wreckfest Race Log sidecar")
    parser.add_argument("--config", default="config.json")
    args = parser.parse_args()

    config = load_config(args.config)
    username: str        = config.get("username", "Ampp33")
    interval_s: float    = config.get("capture_interval_s", 1.0)
    monitor_idx: int     = config.get("monitor_index", 1)
    regions: dict | None = config.get("regions")
    if regions:
        regions = {k: tuple(v) for k, v in regions.items()}

    # Track mappings: human-readable text → slug used by the web app
    track_map: dict[str, str] = config.get("track_name_to_slug", {})
    var_map:   dict[str, str] = config.get("variation_name_to_slug", {})

    print(f"Wreckfest Race Log sidecar — capturing every {interval_s}s")
    print(f"Username: {username}   Monitor: {monitor_idx}")
    print("Press Ctrl-C to stop.\n")

    # Accumulated context across screens
    ctx: dict = {}
    last_screen: str = "unknown"
    last_submitted_key: tuple | None = None

    try:
        for img, capture_ms in capture_loop(interval_s, monitor_idx):
            t0 = time.perf_counter()

            screen = ocr.classify_screen(img)
            if screen != last_screen:
                print(f"[{_ts()}] Screen: {last_screen} → {screen}")
            last_screen = screen

            if screen == "event":
                data = ocr.extract_event_screen(img, regions)
                ctx["track"]     = data["track"]
                ctx["variation"] = data["variation"]
                print(f"  Track: {data['track']!r}  Variation: {data['variation']!r}")

            elif screen == "tune":
                data = ocr.extract_tune_screen(img, regions)
                ctx["tune"] = data
                print(f"  Tune: {data}")

            elif screen == "results":
                row = ocr.extract_results_screen(img, username, regions)
                if row:
                    key = (row.get("total_time_ms"), row.get("place"),
                           ctx.get("track"), ctx.get("variation"))
                    if key == last_submitted_key:
                        pass  # same result still on screen, skip
                    else:
                        _submit(config, ctx, row, track_map, var_map)
                        last_submitted_key = key

            elapsed_ms = (time.perf_counter() - t0) * 1000
            if elapsed_ms > 800:
                print(f"  [warn] OCR took {elapsed_ms:.0f}ms — "
                      "consider increasing capture_interval_s")

    except KeyboardInterrupt:
        print("\nStopped.")
        sys.exit(0)


def _submit(config: dict, ctx: dict, row: dict,
            track_map: dict, var_map: dict) -> None:
    track_text = ctx.get("track", "")
    var_text   = ctx.get("variation", "")
    tune       = ctx.get("tune", {})

    # Map display names → slugs (try exact match, then slug-ified version)
    track_slug = (track_map.get(track_text)
                  or track_map.get(track_text.upper())
                  or _slug(track_text))
    var_slug   = (var_map.get(var_text)
                  or var_map.get(var_text.upper())
                  or _slug(var_text))

    # Tuning: use the four slider values joined so the web app can store them
    # The 'tuning' column is an integer, so map the four positions to a code.
    # Simple scheme: encode as 4 digits (0/1/2 per slider) → int
    slider_names = ["suspension", "gear_ratio", "differential", "brake_balance"]
    tuning_digits = ""
    for sname in slider_names:
        val = tune.get(sname, "")
        labels = ocr.SLIDER_LABELS.get(sname, [])
        try:
            tuning_digits += str(labels.index(val))
        except ValueError:
            tuning_digits += "1"  # default to middle
    tuning_int = int(tuning_digits) if tuning_digits else 1111

    print(f"\n[{_ts()}] Submitting race …")
    print(f"  track={track_slug}  variation={var_slug}")
    print(f"  place={row.get('place')}  total={row.get('total_time')}  "
          f"lap={row.get('best_lap')}  car={row.get('car')}  tuning={tuning_int}")

    try:
        result = api_client.submit_race(
            config         = config,
            track_slug     = track_slug,
            variation_slug = var_slug,
            vehicle_name   = row.get("car", ""),
            place          = row.get("place", 0),
            lap_time_ms    = row.get("lap_time_ms", 0),
            total_time_ms  = row.get("total_time_ms", 0),
            tuning         = tuning_int,
        )
        if result.get("success"):
            print(f"  ✓ Submitted!  race_id={result.get('race_id')}\n")
        else:
            print(f"  ✗ API error: {result.get('error')}\n")
    except Exception as e:
        print(f"  ✗ HTTP error: {e}\n")


def _ts() -> str:
    return time.strftime("%H:%M:%S")


if __name__ == "__main__":
    main()
