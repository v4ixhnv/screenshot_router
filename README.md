# Screenshot Router

A lightweight Windows AutoHotkey (v2) utility that intercepts screenshot captures and gives you a single-key HUD to immediately organize them into designated folders.

---

## The Problem

Windows Snipping Tool dumps every capture into `Pictures\Screenshots`. Over time, that directory fills with hundreds of unsorted files like `Screenshot (142).png`, making it frustrating to find project assets, course notes, bug reports, or reference designs later.

## How It Works

1. Press **PrintScreen**.
2. Take your snip using the native Windows overlay (`Win + Shift + S`).
3. As soon as the file is saved, a quick dialog appears on top:
   - Press **`1`**, **`2`**, **`3`**, etc., to immediately move and rename the image to a predefined folder.
   - Press **`0`** to browse for any custom destination folder.
   - Press **`Esc`** to leave it in the default Screenshots directory.
4. The file is moved and renamed using a clean timestamp format (e.g. `snap_20261120_143022.png`) to avoid accidental overwrites.

---

## Features

- **Keyboard-driven**: Route captures in one keystroke without touching the mouse.
- **Configurable presets**: Define your own folders and key bindings via `config.ini`.
- **Conflict protection**: Automatically appends counters if multiple screenshots occur in the same second.
- **System tray controls**: Quick access to edit configuration, open the source screenshot folder, reload, or exit.
- **Lightweight**: Minimal CPU and memory usage via AutoHotkey v2.

---

## Requirements

- **Windows 10** or **Windows 11**
- [AutoHotkey v2.0+](https://www.autohotkey.com/v2/)
  - Install via Windows Package Manager:
    ```powershell
    winget install AutoHotkey.AutoHotkey
    ```
- **Windows Snipping Tool Setup**:
  - Open **Windows Settings** > **Accessibility** > **Keyboard**.
  - Enable **"Use the Print screen button to open screen snipping"** (or keep the default Snipping Tool auto-save behavior enabled).

---

## Setup & Usage

### 1. Run Directly
Double-click `screenshot_router.ahk` to launch the script.

### 2. Auto-Start with Windows
To run the router automatically every time you log in:
- Run `scripts\install_startup.bat` (creates a shortcut in your Windows Startup directory).
- To disable auto-start, run `scripts\uninstall_startup.bat`.

---

## Configuration

When first run, `screenshot_router.ahk` creates a `config.ini` file in the project folder (based on `config.example.ini`).

Example `config.ini`:

```ini
[Settings]
; Leave blank to use %USERPROFILE%\Pictures\Screenshots
ScreenshotSourceDir =
FilePrefix = snap_
TimestampFormat = yyyyMMdd_HHmmss
TimeoutMs = 15000

[Presets]
; Key = Label | Destination Directory
1 = College / Lab | %USERPROFILE%\Pictures\SortedScreenshots\College
2 = Projects      | %USERPROFILE%\Pictures\SortedScreenshots\Projects
3 = UI & Refs     | %USERPROFILE%\Pictures\SortedScreenshots\References
```

You can right-click the green "H" tray icon in your Windows taskbar and choose **"Edit Config (config.ini)"** at any time, then select **"Reload Script"** to apply changes.

---

## Repository Structure

```
screenshot-router/
├── .github/
│   └── workflows/
│       └── lint.yml
├── scripts/
│   ├── install_startup.bat
│   └── uninstall_startup.bat
├── .gitignore
├── config.example.ini
├── LICENSE
├── README.md
└── screenshot_router.ahk
```

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
