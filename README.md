<p align="center">
  <img src="assets/icon/awake_icon.png" alt="Awake app icon" width="120" />
</p>

# Awake

A lightweight Windows desktop utility built with Flutter and [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) that keeps your display awake while the app is open and automatically stops when you exit.

## Features

- **Automatic Wakelock:** Enables display wakelock immediately on launch and disables it cleanly when the window closes or exits.
- **Clear Status Feedback:** Dark Material 3 UI with a glowing `WAKELOCK ON` / `WAKELOCK OFF` badge, pulsing orb animation, and live `HH:MM:SS` awake session timer.
- **Manual Pause / Resume:** Click the center orb anytime to pause or resume wakelock without closing the app.
- **Desktop-Friendly Lifecycle:** Stays active when minimized or unfocused so your screen remains awake while working in other windows.
- **Proportional Compact Window:** Launches at `460 × 620` logical pixels and locks the `460:620` aspect ratio down to a `386 × 520` minimum size natively via Win32.

## Getting Started (Development)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (Windows desktop enabled)
- Visual Studio with the **Desktop development with C++** workload

### Run Locally

```powershell
flutter pub get
flutter run -d windows
```

### Analyze & Test

```powershell
flutter analyze
flutter test
```

## Building the Windows Installer

Awake uses [Inno Setup 6](https://jrsoftware.org/isinfo.php) to package the Windows release into a standalone per-user installer (`Awake-<version>-Setup.exe`).

1. Install Inno Setup 6 (if not already installed):
   ```powershell
   winget install --id JRSoftware.InnoSetup
   ```
2. Build the release bundle and compile the installer:
   ```powershell
   .\scripts\build_setup.ps1
   ```
3. The generated setup executable will be saved to `dist\Awake-<version>-Setup.exe`.
