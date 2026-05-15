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
OCR proof-of-concept for Wreckfest screenshots.

Tests three screen types and reports extracted values + timing so you can
judge whether the OCR pipeline is fast enough for continuous gameplay use.

Usage:
    python test_ocr.py \\
        --event  path/to/screenshot_event.png \\
        --tune   path/to/screenshot_tune.png \\
        --results path/to/screenshot_results.png \\
        --username Ampp33

Run any subset — flags you omit are just skipped.

Tip: Wreckfest saves screenshots to:
  Documents\\My Games\\Wreckfest\\screenshots\\
"""

import argparse
import json
import os
import psutil
import time
import traceback
from PIL import Image

import ocr_extractor as ocr


# ─── Timing + CPU helpers ──────────────────────────────────────────────────────

def _cpu_percent(pid: int | None = None) -> float:
    """Return current CPU usage of this process (or system-wide)."""
    proc = psutil.Process(pid or os.getpid())
    return proc.cpu_percent(interval=None)


def _timed(label: str, fn):
    """Run fn(), print elapsed time and return result."""
    # Prime cpu_percent (first call always returns 0)
    _cpu_percent()
    t0 = time.perf_counter()
    result = fn()
    elapsed = time.perf_counter() - t0
    cpu = _cpu_percent()
    print(f"  ⏱  {elapsed*1000:.1f} ms   CPU {cpu:.1f}%   [{label}]")
    return result


# ─── Crop previews ─────────────────────────────────────────────────────────────

def _save_debug_crops(img: Image.Image, regions: dict, prefix: str) -> None:
    """Save each cropped region as a small PNG so you can verify alignment."""
    debug_dir = "debug_crops"
    os.makedirs(debug_dir, exist_ok=True)
    for name, bbox in regions.items():
        try:
            crop = img.crop(bbox)
            out = os.path.join(debug_dir, f"{prefix}_{name}.png")
            crop.save(out)
        except Exception:
            pass
    print(f"  Debug crops saved to ./{debug_dir}/")


# ─── Test functions ─────────────────────────────────────────────────────────────

def _print_image_info(img, path: str, regions: dict | None) -> None:
    w, h = img.size
    print(f"  Image size   : {w}x{h}  (reference {ocr.BASE_W}x{ocr.BASE_H})")
    if w != ocr.BASE_W or h != ocr.BASE_H:
        print(f"  Scale factor : x={w/ocr.BASE_W:.3f}  y={h/ocr.BASE_H:.3f}")
    merged = {**ocr.DEFAULT_REGIONS, **(regions or {})}
    scaled = ocr.scale_regions(merged, img)
    if w != ocr.BASE_W or h != ocr.BASE_H:
        print(f"  Regions will be auto-scaled to match your image resolution.")


def test_event(path: str, regions: dict | None = None, debug: bool = False) -> None:
    print(f"\n{'='*60}")
    print(f"EVENT SCREEN  →  {path}")
    print('='*60)

    img = _timed("load image", lambda: ocr.load_image(path))
    _print_image_info(img, path, regions)

    if debug:
        merged = {**ocr.DEFAULT_REGIONS, **(regions or {})}
        scaled = ocr.scale_regions(merged, img)
        event_regions = {k: scaled[k] for k in scaled
                         if k.startswith("event_") or k.startswith("classify_")}
        _save_debug_crops(img, event_regions, "event")

    screen_type = _timed("classify screen",
                          lambda: ocr.classify_screen(img, regions))
    print(f"  Screen type  : {screen_type}")

    result = _timed("extract track + variation",
                    lambda: ocr.extract_event_screen(img, regions))
    print(f"  Track        : {result['track']!r}")
    print(f"  Variation    : {result['variation']!r}")


def test_tune(path: str, regions: dict | None = None, debug: bool = False) -> None:
    print(f"\n{'='*60}")
    print(f"TUNE SCREEN  →  {path}")
    print('='*60)

    img = _timed("load image", lambda: ocr.load_image(path))
    _print_image_info(img, path, regions)

    if debug:
        merged = {**ocr.DEFAULT_REGIONS, **(regions or {})}
        scaled = ocr.scale_regions(merged, img)
        tune_regions = {k: scaled[k] for k in scaled
                        if k.startswith("slider_") or k.startswith("classify_")}
        _save_debug_crops(img, tune_regions, "tune")

    screen_type = _timed("classify screen",
                          lambda: ocr.classify_screen(img, regions))
    print(f"  Screen type  : {screen_type}")

    result = _timed("detect slider positions",
                    lambda: ocr.extract_tune_screen(img, regions))
    for slider, value in result.items():
        print(f"  {slider:<20}: {value}")


def test_results(path: str, username: str,
                 regions: dict | None = None, debug: bool = False) -> None:
    print(f"\n{'='*60}")
    print(f"RESULTS SCREEN  →  {path}")
    print('='*60)

    img = _timed("load image", lambda: ocr.load_image(path))
    _print_image_info(img, path, regions)

    if debug:
        merged = {**ocr.DEFAULT_REGIONS, **(regions or {})}
        scaled = ocr.scale_regions(merged, img)
        results_regions = {k: scaled[k] for k in scaled
                           if "results" in k or k.startswith("classify_")}
        _save_debug_crops(img, results_regions, "results")

    screen_type = _timed("classify screen",
                          lambda: ocr.classify_screen(img, regions))
    print(f"  Screen type  : {screen_type}")

    result = _timed(f"find row for '{username}'",
                    lambda: ocr.extract_results_screen(img, username, regions))

    if result is None:
        print(f"  ⚠  Username '{username}' not found in results table.")
        print(f"     Try --debug to inspect the table crop, or adjust --regions.")
    else:
        for key, val in result.items():
            if key != "raw":
                print(f"  {key:<20}: {val!r}")
        print(f"  {'raw':<20}: {result.get('raw', '')!r}")


# ─── Continuous CPU benchmark ──────────────────────────────────────────────────

def benchmark_continuous(path: str, username: str,
                          runs: int = 10,
                          regions: dict | None = None) -> None:
    """
    Load the same image repeatedly (simulating a live capture loop) and report
    average per-iteration time + CPU so you know if it's viable in gameplay.
    """
    print(f"\n{'='*60}")
    print(f"CONTINUOUS BENCHMARK  ({runs} iterations, simulating {1} fps)")
    print('='*60)

    img = ocr.load_image(path)
    times_ms = []
    cpu_samples = []

    proc = psutil.Process()
    proc.cpu_percent()  # prime

    for i in range(runs):
        t0 = time.perf_counter()

        # Simulate a full classify + extract cycle
        screen_type = ocr.classify_screen(img)
        if screen_type == "results":
            ocr.extract_results_screen(img, username, regions)
        elif screen_type == "tune":
            ocr.extract_tune_screen(img, regions)
        elif screen_type == "event":
            ocr.extract_event_screen(img, regions)

        elapsed_ms = (time.perf_counter() - t0) * 1000
        cpu = proc.cpu_percent()
        times_ms.append(elapsed_ms)
        cpu_samples.append(cpu)
        print(f"  Run {i+1:2d}: {elapsed_ms:6.1f} ms   CPU {cpu:.1f}%")

    avg_ms = sum(times_ms) / len(times_ms)
    max_ms = max(times_ms)
    avg_cpu = sum(cpu_samples) / len(cpu_samples)
    print(f"\n  Average : {avg_ms:.1f} ms/frame")
    print(f"  Max     : {max_ms:.1f} ms/frame")
    print(f"  Avg CPU : {avg_cpu:.1f}%")
    if avg_ms < 1000:
        fps = 1000 / avg_ms
        print(f"  Capable : ~{fps:.1f} fps  (you need ~1 fps for this use case)")


# ─── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Test Wreckfest OCR extraction on screenshot files"
    )
    parser.add_argument("--event",    metavar="FILE",
                        help="Path to pre-race event screenshot")
    parser.add_argument("--tune",     metavar="FILE",
                        help="Path to tune-tab screenshot")
    parser.add_argument("--results",  metavar="FILE",
                        help="Path to race results screenshot")
    parser.add_argument("--username", default="Ampp33",
                        help="Your in-game username (default: Ampp33)")
    parser.add_argument("--regions",  metavar="JSON_FILE",
                        help="Optional JSON file overriding UI regions")
    parser.add_argument("--benchmark", metavar="FILE",
                        help="Run a continuous benchmark on this screenshot")
    parser.add_argument("--runs",     type=int, default=10,
                        help="Number of benchmark iterations (default: 10)")
    parser.add_argument("--debug",    action="store_true",
                        help="Save debug crop images to ./debug_crops/")
    args = parser.parse_args()

    regions = None
    if args.regions:
        with open(args.regions) as f:
            raw = json.load(f)
        # JSON tuples come in as lists — convert back
        regions = {k: tuple(v) for k, v in raw.items()}

    had_any = False

    if args.event:
        had_any = True
        try:
            test_event(args.event, regions=regions, debug=args.debug)
        except Exception:
            print("  ERROR:"); traceback.print_exc()

    if args.tune:
        had_any = True
        try:
            test_tune(args.tune, regions=regions, debug=args.debug)
        except Exception:
            print("  ERROR:"); traceback.print_exc()

    if args.results:
        had_any = True
        try:
            test_results(args.results, args.username,
                         regions=regions, debug=args.debug)
        except Exception:
            print("  ERROR:"); traceback.print_exc()

    if args.benchmark:
        had_any = True
        try:
            benchmark_continuous(args.benchmark, args.username,
                                 runs=args.runs, regions=regions)
        except Exception:
            print("  ERROR:"); traceback.print_exc()

    if not had_any:
        parser.print_help()


if __name__ == "__main__":
    main()
