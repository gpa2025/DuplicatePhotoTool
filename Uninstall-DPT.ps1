<#
.SYNOPSIS
    Uninstaller for GPA Solutions - GPA DPT (Duplicate Photo Tool)

.DESCRIPTION
    Removes all components installed by Setup-DPT.ps1:
    - Start Menu shortcut
    - Desktop shortcut
    - Scheduled task
    - AppData directories (logs, cache)
#>

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   GPA SOLUTIONS - GPA DPT" -ForegroundColor Cyan
Write-Host "   Duplicate Photo Tool Uninstall" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# =====================================
# 1. Remove Start Menu shortcut
# =====================================
Write-Host "[1/4] Removing Start Menu shortcut..." -ForegroundColor Yellow

$StartMenuLink = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\GPA Solutions\GPA's Duplicate Picture Tool.lnk"
$StartMenuDir  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\GPA Solutions"

if (Test-Path $StartMenuLink) {
    Remove-Item $StartMenuLink -Force
    Write-Host "[OK] Start Menu shortcut removed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Start Menu shortcut not found" -ForegroundColor Gray
}

if (Test-Path $StartMenuDir) {
    $remaining = Get-ChildItem $StartMenuDir
    if ($remaining.Count -eq 0) {
        Remove-Item $StartMenuDir -Force
        Write-Host "[OK] Start Menu folder removed" -ForegroundColor Green
    }
}

# =====================================
# 2. Remove Desktop shortcut
# =====================================
Write-Host "[2/4] Removing Desktop shortcut..." -ForegroundColor Yellow

$DesktopLink = "$([ Environment]::GetFolderPath('Desktop'))\GPA's Duplicate Picture Tool.lnk"

if (Test-Path $DesktopLink) {
    Remove-Item $DesktopLink -Force
    Write-Host "[OK] Desktop shortcut removed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Desktop shortcut not found" -ForegroundColor Gray
}

# =====================================
# 3. Unregister Scheduled Task
# =====================================
Write-Host "[3/4] Removing scheduled task..." -ForegroundColor Yellow

$TaskName = "GPA_DPT_DailyDuplicateScan"
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($task) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "[OK] Scheduled task removed" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Could not remove scheduled task: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[SKIP] Scheduled task not found" -ForegroundColor Gray
}

# =====================================
# 4. Remove AppData directories
# =====================================
Write-Host "[4/4] Removing AppData directories..." -ForegroundColor Yellow

$AppDataPath = Join-Path $env:APPDATA "GPA Solutions\DPT"

if (Test-Path $AppDataPath) {
    try {
        Remove-Item $AppDataPath -Recurse -Force -ErrorAction Stop
        Write-Host "[OK] AppData directory removed: $AppDataPath" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Could not remove AppData directory: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[SKIP] AppData directory not found" -ForegroundColor Gray
}

# Clean up parent "GPA Solutions" folder if empty
$AppDataParent = Join-Path $env:APPDATA "GPA Solutions"
if (Test-Path $AppDataParent) {
    if ((Get-ChildItem $AppDataParent).Count -eq 0) {
        Remove-Item $AppDataParent -Force
        Write-Host "[OK] AppData parent folder removed" -ForegroundColor Green
    }
}

# =====================================
# Done
# =====================================
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "   GPA DPT Uninstall Complete" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
