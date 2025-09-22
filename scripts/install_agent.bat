@echo off
REM install_agent.bat - One-click setup and run the agent on Windows

echo Setting up agent...

REM Change to the repo root (parent of scripts/)
cd /d "%~dp0.."

echo Current directory: %cd%
echo Looking for vm_agent.py at: %cd%\scripts\vm_agent.py

REM Check if the file exists
if not exist "%cd%\scripts\vm_agent.py" (
    echo Error: vm_agent.py not found at %cd%\scripts\vm_agent.py
    echo Please ensure the repo is copied correctly and run this .bat from the repo root.
    pause
    exit /b 1
)

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found. Installing Python...
    REM Try winget first (Windows 10/11)
    winget --version >nul 2>&1
    if not errorlevel 1 (
        echo Installing Python via winget...
        winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements
    ) else (
        echo Winget not available. Please install Python manually from https://python.org
        pause
        exit /b 1
    )
    REM Refresh PATH
    call refreshenv.cmd >nul 2>&1 || set PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts
)

REM Ensure pip is available
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo Pip not available. Installing pip...
    python -m ensurepip --upgrade
)

REM Install required packages
echo Installing dependencies...
pip install pillow

REM Run the agent
echo Starting agent on port 8000...
python scripts\vm_agent.py --port 8000

pause
