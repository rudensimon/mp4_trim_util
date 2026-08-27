@echo off
setlocal EnableExtensions
title Install Trim Clip v7.4

set "TARGET=%USERPROFILE%\TrimClip"
set "KEY=HKCU\Software\Classes\SystemFileAssociations\.mp4\shell\TrimClip"

echo Installing Trim Clip v7.4...
echo.

if not exist "%TARGET%" mkdir "%TARGET%"

copy /Y "%~dp0Trim Clip.ps1" "%TARGET%\Trim Clip.ps1" >nul
if errorlevel 1 goto :install_error

if exist "%~dp0ffmpeg.exe" (
    copy /Y "%~dp0ffmpeg.exe" "%TARGET%\ffmpeg.exe" >nul
    if errorlevel 1 goto :install_error
)

reg add "%KEY%" /ve /t REG_SZ /d "Trim clip..." /f >nul
if errorlevel 1 goto :install_error

reg add "%KEY%" /v "MultiSelectModel" /t REG_SZ /d "Single" /f >nul
if errorlevel 1 goto :install_error

reg add "%KEY%\command" /ve /t REG_EXPAND_SZ /d "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%%USERPROFILE%%\TrimClip\Trim Clip.ps1\" \"%%1\"" /f >nul
if errorlevel 1 goto :install_error

if not exist "%TARGET%\ffmpeg.exe" (
    where ffmpeg.exe >nul 2>nul
    if errorlevel 1 (
        echo.
        echo FFmpeg was not found.
        echo Put a static ffmpeg.exe here:
        echo   %TARGET%
        echo.
    )
)

echo Installed successfully.
echo.
pause
exit /b 0

:install_error
echo Installation failed.
pause
exit /b 1
