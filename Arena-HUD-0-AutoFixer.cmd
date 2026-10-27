@echo off
cd /d "%~dp0"
title Arena HUD 0 AutoFixer - 15s Checks / 60s Status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Arena-HUD-0-AutoFixer.ps1"
echo.
echo Monitor ended. Press any key to close.
pause >nul
