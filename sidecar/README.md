# Wreckfest Race Log — Sidecar (OCR edition)

Captures the Wreckfest screen at 1 fps, reads track/tune/result info via OCR,
and automatically submits race results to your Wreckfest Race Log account.

No admin rights needed — no memory reading involved.

---

## How it works

The sidecar watches three screen types:

| Screen | What it reads |
|--------|--------------|
| **Event** (pre-race lobby) | Track name, variation |
| **Tune** tab | Active position on each slider (Suspension / Gear Ratio / Differential / Brake Balance) |
| **Results** | Your row (position, total time, best lap, car) |

When it sees a results screen it hasn't submitted yet, it combines the stored
context from the event + tune screens and posts a race entry via the API.

---

## Prerequisites

- Windows 10/11 (64-bit)
- Python 3.11 or newer — https://python.org
- **Tesseract OCR** — https://github.com/UB-Mannheim/tesseract/wiki
  - Install to the default path (`C:\Program Files\Tesseract-OCR\`)
  - Or set the `TESSDATA_PREFIX` / `pytesseract.pytesseract.tesseract_cmd` env var
- Wreckfest running in **windowed fullscreen** on your primary monitor (index 1)

---

## Setup

1. **Install Python dependencies**

   ```
   pip install -r requirements.txt
   ```

2. **Install Tesseract** (see Prerequisites above)

3. **Get your API key from the web app**

   Open Wreckfest Race Log → **API Keys** → Generate key, copy it (shown once).

4. **Edit `config.json`**

   ```json
   {
     "supabase_url":     "https://xribggiaayvvjrznbchg.supabase.co",
     "supabase_anon_key": "sb_publishable_...",
     "api_key":           "the key you just copied",
     "username":          "YourInGameUsername"
   }
   ```

   The `supabase_url` and `supabase_anon_key` values are in the app's `.env`.

5. **Test the OCR** (before running live — see below)

6. **Run the sidecar**

   ```
   python sidecar.py
   ```

---

## Testing with screenshots

Use `test_ocr.py` to verify the OCR pipeline works on real screenshots before
you run the live sidecar.  Wreckfest saves screenshots to:

```
Documents\My Games\Wreckfest\screenshots\
```

Or press `F12` in-game (Steam screenshot).

### Run the test

```
python test_ocr.py ^
    --event   "C:\path\to\event_screen.png" ^
    --tune    "C:\path\to\tune_screen.png" ^
    --results "C:\path\to\results_screen.png" ^
    --username Ampp33
```

### What it reports

```
============================================================
EVENT SCREEN  →  event_screen.png
============================================================
  ⏱  12.3 ms   CPU 4.2%   [load image]
  ⏱  38.1 ms   CPU 18.5%  [classify screen]
  ⏱  45.2 ms   CPU 22.1%  [extract track + variation]
  Track        : 'VALE FALLS CIRCUIT'
  Variation    : 'MAIN CIRCUIT'
```

### Run a continuous benchmark

```
python test_ocr.py --benchmark "C:\path\to\results.png" --runs 20
```

This simulates 20 consecutive capture + classify + extract cycles and reports
average time and CPU usage per frame.  Anything under 500ms/frame is fine for
a 1 fps polling rate.

### Debug crops

Add `--debug` to save each cropped region to `./debug_crops/` so you can
check whether the regions are correctly aligned with your screenshots:

```
python test_ocr.py --event event.png --debug
```

---

## Adjusting regions

The default regions are calibrated for **3840×2152** screenshots.  If your
resolution differs, measure the correct pixel bounding boxes and override them
in `config.json`:

```json
{
  "regions": {
    "track_name":       [55, 415, 1100, 560],
    "variation_name":   [55, 510,  700, 610],
    "slider_suspension":    [55, 440, 835, 470],
    "slider_gear_ratio":    [55, 575, 835, 605],
    "slider_differential":  [55, 790, 835, 820],
    "slider_brake_balance": [55, 965, 835, 995],
    "results_table":    [900, 160, 3840, 1100]
  }
}
```

Use the `--debug` flag on `test_ocr.py` to see the crops and verify alignment.

### Slider detection notes

Slider positions are detected via **brightness analysis**, not OCR.  The
active (selected) dot on each Wreckfest slider is a filled white circle that
produces a clear brightness peak in its column.  Inactive positions are just
tick marks.  If a slider is always reading the wrong position, the strip region
probably needs a slight vertical adjustment.

---

## Adding track/variation name mappings

When the sidecar sees a results screen it looks up the track name OCR'd from
the event screen to find the correct slug for the API.  Add entries for every
track you race to `config.json → track_name_to_slug` and `variation_name_to_slug`:

```json
"track_name_to_slug": {
  "VALE FALLS CIRCUIT": "vale-falls-circuit",
  "HELLRIDE":           "hellride"
},
"variation_name_to_slug": {
  "MAIN CIRCUIT":         "main-circuit",
  "MAIN CIRCUIT REVERSE": "main-circuit-reverse"
}
```

The sidecar falls back to a slugified version of the raw text if no mapping is
found, which often matches anyway.

---

## Files

| File | Purpose |
|------|---------|
| `sidecar.py` | Main loop — capture, classify, accumulate context, submit |
| `ocr_extractor.py` | Screen classification + OCR/image-processing extraction |
| `screen_capture.py` | Fast screen capture via `mss` |
| `api_client.py` | HTTP POST to the Supabase RPC endpoint |
| `test_ocr.py` | Offline test + benchmark for screenshot files |
| `config.json` | Your credentials + optional region overrides |
| `requirements.txt` | Python dependencies |
