@echo off
setlocal
set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ScreenshotRouter.lnk"

if exist "%SHORTCUT_PATH%" (
    del "%SHORTCUT_PATH%"
    echo [OK] Screenshot Router startup shortcut removed.
) else (
    echo [INFO] Shortcut was not found in Startup folder.
)
pause
