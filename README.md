# Author
Built by Gianpaolo, with engineering assistance from Microsoft Copilot.

# Duplicate Photo Tool

A fast, multi-threaded PowerShell-based duplicate photo detection and cleanup tool with:

- SHA256 hashing
- Checksum caching for instant re-scans
- Logging levels (INFO, WARN, ERROR)
- Duplicate selection modes:
  - Keep First
  - Keep Newest
  - Keep Largest
- CSV reporting
- Folder structure preservation
- Colorized help output
- GUI launcher (WPF)
- Scheduled Task wrapper
- Standalone script architecture

---

## 🚀 Features

### 🔍 Multi-threaded Hashing
Uses PowerShell 7 parallel processing to hash large photo libraries quickly.

### ⚡ Checksum Cache
Stores file metadata + hash to avoid re-hashing unchanged files.

### 🧠 Smart Duplicate Selection
Choose which file to keep:
- **First** (default)
- **Newest** (based on LastWriteTime)
- **Largest** (based on file size)

### 📁 Folder Structure Preservation
Duplicates are moved into a mirrored directory tree under your chosen destination.

### 📊 CSV + Log Output
Every duplicate is logged and included in a CSV report.

### 🎨 GUI Launcher
A simple WPF interface for non-technical users.

### ⏰ Scheduled Task Wrapper
Automate duplicate scans daily, weekly, or on any schedule.

---

## 📦 Repository Structure

DuplicatePhotoTool/
│
├── src/
│   ├── Find-DuplicatePhotos.ps1
│   ├── DuplicatePhotoTool-GUI.ps1
│   ├── Register-DuplicatePhotoScanTask.ps1
│
├── docs/
│   └── usage.md
│
├── tests/
│   └── sample-test.ps1
│
├── README.md
├── .gitignore
└── LICENSE


---

## 🛠 Requirements

- **PowerShell 7+**
- Windows 10/11 recommended
- Git (optional, for version control)

---

## ▶️ Usage

### Basic Scan

```powershell
.\src\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates"

- DryRun
-SelectionMode Newest
-SelectionMode Largest
-Help

## Gui Version
.\src\DuplicatePhotoTool-GUI.ps1

## Scheduled task
.\src\Register-DuplicatePhotoScanTask.ps1 -ScriptPath "D:\GitRepo\DuplicatePhotoTool\src\Find-DuplicatePhotos.ps1" -Time "02:00"

##License
MIT License -see LICENSE file.