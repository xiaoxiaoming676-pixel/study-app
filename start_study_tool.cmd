@echo off
setlocal
cd /d "%~dp0"
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" "overlay\tools\study\gui.py"
) else (
  py -3 "overlay\tools\study\gui.py"
)
if errorlevel 1 pause
