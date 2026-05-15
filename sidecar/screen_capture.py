"""
Fast screen capture using mss.

mss captures the screen in ~5–15ms (much faster than PIL ImageGrab),
making it practical to poll at 1–2 fps without significant CPU impact.
"""

from __future__ import annotations
import time
from PIL import Image

try:
    import mss
    import mss.tools
    _MSS_AVAILABLE = True
except ImportError:
    _MSS_AVAILABLE = False


def capture_screen(monitor_index: int = 1) -> Image.Image:
    """
    Capture the specified monitor and return a PIL Image.

    monitor_index:
      0 = all monitors combined
      1 = primary monitor (default)
      2, 3, … = additional monitors
    """
    if not _MSS_AVAILABLE:
        raise RuntimeError(
            "mss is not installed.  Run: pip install mss"
        )
    with mss.mss() as sct:
        monitor = sct.monitors[monitor_index]
        screenshot = sct.grab(monitor)
        return Image.frombytes("RGB", screenshot.size, screenshot.bgra,
                               "raw", "BGRX")


def capture_loop(interval_s: float = 1.0,
                 monitor_index: int = 1):
    """
    Generator: yields (PIL Image, elapsed_capture_s) at the requested interval.
    The caller controls when to stop (just break out of the loop).
    """
    if not _MSS_AVAILABLE:
        raise RuntimeError("mss is not installed.  Run: pip install mss")
    with mss.mss() as sct:
        monitor = sct.monitors[monitor_index]
        while True:
            t0 = time.perf_counter()
            raw = sct.grab(monitor)
            img = Image.frombytes("RGB", raw.size, raw.bgra, "raw", "BGRX")
            elapsed = time.perf_counter() - t0

            yield img, elapsed

            # Sleep the remaining portion of the interval
            sleep_s = interval_s - (time.perf_counter() - t0)
            if sleep_s > 0:
                time.sleep(sleep_s)
