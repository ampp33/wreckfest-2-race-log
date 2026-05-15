#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Wreckfest 2 Race Log Sidecar — Setup"
echo "============================================================"
echo

# ── Python ────────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "[ERROR] python3 not found. Install it via your package manager:"
    echo "        Ubuntu/Debian : sudo apt install python3 python3-pip"
    echo "        Fedora        : sudo dnf install python3 python3-pip"
    echo "        Arch          : sudo pacman -S python python-pip"
    exit 1
fi
echo "[OK] $(python3 --version) found"

# ── Tesseract ─────────────────────────────────────────────────────────────────
echo
echo "[1/2] Installing Tesseract OCR..."

if command -v tesseract &>/dev/null; then
    echo "[OK] Tesseract already installed — skipping."
else
    if command -v apt-get &>/dev/null; then
        echo "     Detected: apt (Debian / Ubuntu)"
        sudo apt-get update -qq
        sudo apt-get install -y tesseract-ocr

    elif command -v dnf &>/dev/null; then
        echo "     Detected: dnf (Fedora / RHEL)"
        sudo dnf install -y tesseract

    elif command -v pacman &>/dev/null; then
        echo "     Detected: pacman (Arch Linux)"
        sudo pacman -S --noconfirm tesseract tesseract-data-eng

    elif command -v zypper &>/dev/null; then
        echo "     Detected: zypper (openSUSE)"
        sudo zypper install -y tesseract-ocr tesseract-ocr-traineddata-english

    elif command -v brew &>/dev/null; then
        echo "     Detected: Homebrew (macOS)"
        brew install tesseract

    else
        echo "[ERROR] No supported package manager found (apt, dnf, pacman, zypper, brew)."
        echo "        Install Tesseract manually: https://tesseract-ocr.github.io/tessdoc/Installation.html"
        exit 1
    fi

    echo "[OK] Tesseract installed."
fi

# ── Python packages ───────────────────────────────────────────────────────────
echo
echo "[2/2] Installing Python packages..."

# Prefer a venv so we don't pollute the system Python
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "     Created virtual environment at ./.venv"
fi

source .venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt

echo "[OK] Python packages installed (virtual environment: .venv)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo "============================================================"
echo " Setup complete!"
echo
echo " Next steps:"
echo "   1. Edit config.json with your API key and username"
echo "   2. Activate the venv: source .venv/bin/activate"
echo "   3. Run:  python test_ocr.py --help"
echo "   4. Run:  python sidecar.py"
echo "============================================================"
