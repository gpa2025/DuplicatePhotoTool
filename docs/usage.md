# Duplicate Photo Tool — Usage Guide

This document explains how to use the Duplicate Photo Tool, including command‑line usage, GUI usage, caching behavior, logging, and scheduled automation.

---

## 📁 1. Basic Command‑Line Usage

Run a duplicate scan:

```powershell
.\src\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates"

This will:
+ Scan all files under D:\Pictures
+ Compute SHA256 hashes
+ Use checksum caching for faster re‑scans
+ Move duplicates into D:\Duplicates (mirroring folder structure)
+ Generate a CSV report

## 🧠 2. Selection Modes
Choose which file to keep when duplicates are found:

### First (default)
Keeps the first file encountered.

powershell
-SelectionMode First 

### Newest
Keeps the file with the most recent LastWriteTime.

powershell
-SelectionMode Newest

### Largest
Keeps the file with the largest file size.

powershell
-SelectionMode Largest

## 🧪 3. Dry Run Mode
Preview actions without moving any files:

powershell
-DryRun
This is recommended for first‑time scans.

## 📝 4. Logging Levels
### Control how much output you see:

INFO — everything (default)
WARN — warnings + errors
ERROR — only errors


## ⚡ 5. Checksum Cache
The tool stores a cache file:

<DuplicateRoot>\checksum_cache.json

This cache includes:
File path
SHA256 hash
LastWriteTime
File size

If a file hasn’t changed, hashing is skipped on future scans.

Delete this file to force a full re‑hash.

## 📊 6. CSV Report
After each scan, a report is saved:

<DuplicateRoot>\duplicate_report.csv

Columns include:
    Original file
    Duplicate file
    Destination path
    SHA256 hash

## 🖥 7. GUI Usage
Launch the GUI:

powershell
.\src\DuplicatePhotoTool-GUI.ps1
The GUI allows you to:

Select source folder
Select duplicate output folder
Choose selection mode
Start a scan in a new PowerShell window

## ⏰ 8. Scheduled Task Automation

Register a daily scan:
.\src\Register-DuplicatePhotoScanTask.ps1 `
    -ScriptPath "D:\GitRepo\DuplicatePhotoTool\src\Find-DuplicatePhotos.ps1" `
    -Source "D:\Pictures" `
    -DuplicateRoot "D:\Duplicates" `
    -Time "02:00" `
    -SelectionMode Newest
This creates a Windows Scheduled Task named: DuplicatePhotoScan

## 🧹 9. Folder Structure Preservation
Duplicates are moved into a mirrored directory tree under your duplicate root.

Example:

Source:        D:\Pictures\2020\Trip\IMG001.jpg
DuplicateRoot: D:\Duplicates\2020\Trip\IMG001.jpg

## 🛠 10. Requirements
PowerShell 7+

Windows 10/11 recommended

Sufficient disk space for duplicate storage

## 📄 11. License
MIT License — see LICENSE file.