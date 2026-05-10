# GPA Duplicate Photo Tool

**Version:** 1.0.1  
**Author:** Built by Gianpaolo, with engineering assistance from Amazon Q.  
**License:** MIT — see [LICENSE](LICENSE)

A fast, multi-threaded PowerShell-based duplicate photo detection and cleanup tool for Windows.

---

## 🚀 Features

### 🔍 Parallel SHA256 Hashing
Uses PowerShell 7 `ForEach-Object -Parallel` with batched processing across up to 16 CPU cores for maximum throughput on large photo libraries.

### ⚡ Checksum Cache
Stores file metadata + hash in `checksum_cache.json` inside the duplicate output folder. Unchanged files are skipped on re-scans — no re-hashing needed.

### 🛡 Safe Duplicate Detection
Only exact SHA256 duplicates are moved. The original file is always kept in place. Every move is logged with the original file location.

### 📁 Folder Structure Preservation
Duplicates are moved into a mirrored directory tree under your chosen output folder.

### 📊 CSV Report + Scan Log
Every duplicate move is recorded in `duplicate_report.csv` with original path, duplicate path, destination, and hash. A full `scan_log.txt` is also written to the output folder and viewable directly from the GUI.

### ⏱ Scan Timer
Elapsed time is logged at the end of every scan with a summary of duplicate groups found and files processed.

### 🎨 GUI Launcher
A dark-themed WPF interface with:
- Splash screen with branding
- Context-sensitive help in the status bar
- Live MM:SS timer display
- Dry Run checkbox
- CPU cores slider (1–16)
- View Log button — opens `scan_log.txt` in a built-in log viewer

### ⏰ Scheduled Task Wrapper
Automate duplicate scans on any schedule via Windows Task Scheduler.

### 🔧 Setup & Uninstall Scripts
One-command install and uninstall — creates Start Menu and Desktop shortcuts, registers the scheduled task, and sets up AppData directories.

---

## 📦 Repository Structure

```
DuplicatePhotoTool/
├── src/
│   ├── Find-DuplicatePhotos.ps1
│   ├── DuplicatePhotoTool-GUI.ps1
│   └── Register-DuplicatePhotoScanTask.ps1
├── branding/
│   ├── logo-icon.ico
│   ├── logo-icon.svg
│   └── Generate-Icon.ps1
├── docs/
│   └── usage.md
├── tests/
│   └── sample-test.ps1
├── tools/
│   └── Update-Version.ps1
├── Setup-DPT.ps1
├── Uninstall-DPT.ps1
├── README.md
├── CHANGELOG.md
├── VERSION
└── LICENSE
```

---

## 🛠 Requirements

- **PowerShell 7+**
- **Windows 10/11**
- Git (optional)

---

## ▶️ Install

```powershell
pwsh -ExecutionPolicy Bypass -File .\Setup-DPT.ps1
```

Installs shortcuts, registers the scheduled task, and creates AppData directories.

## 🗑 Uninstall

```powershell
pwsh -ExecutionPolicy Bypass -File .\Uninstall-DPT.ps1
```

---

## 💻 Usage

### GUI
Launch from the Desktop or Start Menu shortcut, or run directly:
```powershell
.\src\DuplicatePhotoTool-GUI.ps1
```

### Command Line

Basic scan:
```powershell
.\src\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates"
```

Dry run (no files moved):
```powershell
.\src\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates" -DryRun
```

Specify CPU cores:
```powershell
.\src\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates" -ThrottleLimit 8
```

### Scheduled Task
```powershell
.\src\Register-DuplicatePhotoScanTask.ps1 `
    -ScriptPath "D:\GitRepo\DuplicatePhotoTool\src\Find-DuplicatePhotos.ps1" `
    -Source "D:\Pictures" `
    -DuplicateRoot "D:\Duplicates" `
    -Time "02:00"
```

---

## 🧪 Tests

```powershell
pwsh -File .\tests\sample-test.ps1
```

Runs 6 functional tests covering duplicate detection, dry run, CSV reporting, cache creation, and original file protection.

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for full release history.
