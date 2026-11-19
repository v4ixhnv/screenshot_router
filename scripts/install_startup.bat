@echo off
setlocal
set "PROJECT_DIR=%~dp0.."
set "TARGET_SCRIPT=%PROJECT_DIR%\screenshot_router.ahk"
set "SHORTCUT_PATH=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ScreenshotRouter.lnk"

echo Creating startup shortcut...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%TARGET_SCRIPT%'; $s.WorkingDirectory = '%PROJECT_DIR%'; $s.Save()"

if exist "%SHORTCUT_PATH%" (
    echo [OK] Screenshot Router has been added to Windows Startup.
) else (
    echo [ERROR] Could not create shortcut.
)
pause
