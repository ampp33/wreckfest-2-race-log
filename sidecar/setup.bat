@echo off
setlocal enabledelayedexpansion
title Wreckfest Race Log — Sidecar Setup

echo ============================================================
echo  Wreckfest Race Log Sidecar — Setup
echo ============================================================
echo.

:: ── Python ──────────────────────────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install Python 3.11+ from https://python.org
    echo         Make sure to tick "Add Python to PATH" during installation.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo [OK] %%v found

:: ── Tesseract ────────────────────────────────────────────────────────────────
echo.
echo [1/2] Installing Tesseract OCR...

tesseract --version >nul 2>&1
if not errorlevel 1 (
    echo [OK] Tesseract already installed — skipping.
) else (
    winget --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] winget not found.
        echo         Please install Tesseract manually from:
        echo         https://github.com/UB-Mannheim/tesseract/wiki
        pause
        exit /b 1
    )
    winget install --id UB-Mannheim.TesseractOCR --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo [ERROR] Tesseract installation failed.
        echo         Try installing manually: https://github.com/UB-Mannheim/tesseract/wiki
        pause
        exit /b 1
    )
    echo [OK] Tesseract installed.
    echo      NOTE: Open a new terminal window before running the sidecar so
    echo            Tesseract appears on your PATH.
)

:: ── Python packages ──────────────────────────────────────────────────────────
echo.
echo [2/2] Installing Python packages...
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] pip install failed. See output above.
    pause
    exit /b 1
)
echo [OK] Python packages installed.

:: ── Done ─────────────────────────────────────────────────────────────────────
echo.
echo ============================================================
echo  Setup complete!
echo.
echo  Next steps:
echo    1. Edit config.json with your API key and username
echo    2. Run:  python test_ocr.py --help
echo    3. Run:  python sidecar.py
echo ============================================================
echo.
pause
