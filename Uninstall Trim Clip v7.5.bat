@echo off
setlocal
title Uninstall Trim Clip v7.5

set "TARGET=%USERPROFILE%\TrimClip"
set "KEY=HKCU\Software\Classes\SystemFileAssociations\.mp4\shell\TrimClip"

reg delete "%KEY%" /f >nul 2>nul
del /Q "%TARGET%\Trim Clip.ps1" >nul 2>nul

rem Remove the folder only if it is empty.
rmdir "%TARGET%" >nul 2>nul

echo Trim Clip v7.5 has been removed.
echo.
pause
