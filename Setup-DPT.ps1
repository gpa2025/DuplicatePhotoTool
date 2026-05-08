<#
.SYNOPSIS
    Setup script for GPA Solutions - GPA DPT (Duplicate Photo Tool)

.DESCRIPTION
    This installer:
    - Validates PowerShell 7+ availability
    - Creates Start Menu shortcuts with custom icons
    - Creates Desktop shortcuts with custom icons
    - Registers the scheduled scan task
    - Validates folder structure
    - Sets up logging and cache directories

.PARAMETER SourcePath
    Default source folder for photo scans (default: D:\Pictures)

.PARAMETER DuplicateRoot
    Default root folder for duplicate storage (default: D:\Duplicates)

.PARAMETER ScanTime
    Daily scan time in 24-hour format HH:mm (default: 02:00)

.NOTES
    GPA Solutions - GPA DPT
    Duplicate Photo Tool - Setup Script
    Version: 1.0
#>

param(
    [string]$SourcePath = "D:\Pictures",
    [string]$DuplicateRoot = "D:\Duplicates",
    [string]$ScanTime = "02:00"
)

# =====================================
# GPA DPT Installation Banner
# =====================================
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   GPA SOLUTIONS - GPA DPT" -ForegroundColor Cyan
Write-Host "   Duplicate Photo Tool Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# =====================================
# 1. Validate PowerShell 7+
# =====================================
Write-Host "[1/6] Checking PowerShell 7+ availability..." -ForegroundColor Yellow

$pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)

if (-not $pwsh) {
    Write-Host "[ERROR] PowerShell 7 not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PowerShell 7+ from:" -ForegroundColor Yellow
    Write-Host "   https://aka.ms/powershell" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

$PwshVersion = & pwsh.exe -NoProfile -Command '$PSVersionTable.PSVersion.Major'
Write-Host "[OK] PowerShell $PwshVersion detected" -ForegroundColor Green

# =====================================
# 2. Define paths and validate structure
# =====================================
Write-Host "[2/6] Validating folder structure..." -ForegroundColor Yellow

$Root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src      = Join-Path $Root "src"
$Branding = Join-Path $Root "branding"
$Gui      = Join-Path $Src "DuplicatePhotoTool-GUI.ps1"
$Main     = Join-Path $Src "Find-DuplicatePhotos.ps1"

# Prefer ICO file, fall back to SVG
$IconPathIco = Join-Path $Branding "logo-icon.ico"
$IconPathSvg = Join-Path $Branding "logo-icon.svg"
$IconPath = ""

if (Test-Path $IconPathIco) {
    $IconPath = $IconPathIco
} elseif (Test-Path $IconPathSvg) {
    $IconPath = $IconPathSvg
}

# Verify critical files exist
$CriticalFiles = @($Gui, $Main)
$MissingFiles = @()

foreach ($File in $CriticalFiles) {
    if (-not (Test-Path $File)) {
        $MissingFiles += $File
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Host "[ERROR] Missing critical files:" -ForegroundColor Red
    foreach ($File in $MissingFiles) {
        Write-Host "   - $File" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[OK] Folder structure validated" -ForegroundColor Green

# =====================================
# 3. Create Start Menu folder & shortcuts
# =====================================
Write-Host "[3/6] Creating shortcuts..." -ForegroundColor Yellow

$StartMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\GPA Solutions"
$Desktop   = [Environment]::GetFolderPath("Desktop")

try {
    if (-not (Test-Path $StartMenu)) {
        New-Item -ItemType Directory -Path $StartMenu -Force -ErrorAction Stop | Out-Null
    }
    Write-Host "[OK] Start Menu directory ready" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to create Start Menu directory: $_" -ForegroundColor Red
    exit 1
}

# =====================================
# 4. Create shortcuts function & execute
# =====================================
$WScript = New-Object -ComObject WScript.Shell

function New-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetScript,
        [string]$IconPath = "",
        [string]$Description = ""
    )

    try {
        $Shortcut = $WScript.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "pwsh.exe"
        $Shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$TargetScript`""
        $Shortcut.WorkingDirectory = Split-Path -Parent $TargetScript
        
        if ($Description -ne "") {
            $Shortcut.Description = $Description
        }
        
        if ($IconPath -ne "" -and (Test-Path $IconPath)) {
            try {
                $Shortcut.IconLocation = $IconPath
            } catch {
                # Icon setting failed - not critical
            }
        }
        
        $Shortcut.Save()
        return $true
    } catch {
        return $false
    }
}

# Create Start Menu shortcut
$StartMenuLink = "$StartMenu\GPA's Duplicate Picture Tool.lnk"
if (Test-Path $StartMenuLink) {
    Remove-Item $StartMenuLink -Force -ErrorAction SilentlyContinue
}

if (New-Shortcut -ShortcutPath $StartMenuLink `
                 -TargetScript $Gui `
                 -IconPath $IconPath `
                 -Description "GPA's Duplicate Picture Tool - Fast multi-threaded duplicate detection") {
    Write-Host "[OK] Start Menu shortcut created" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to create Start Menu shortcut" -ForegroundColor Red
}

# Create Desktop shortcut
$DesktopLink = "$Desktop\GPA's Duplicate Picture Tool.lnk"
if (Test-Path $DesktopLink) {
    Remove-Item $DesktopLink -Force -ErrorAction SilentlyContinue
}

if (New-Shortcut -ShortcutPath $DesktopLink `
                 -TargetScript $Gui `
                 -IconPath $IconPath `
                 -Description "GPA's Duplicate Picture Tool - Fast multi-threaded duplicate detection") {
    Write-Host "[OK] Desktop shortcut created" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Failed to create Desktop shortcut" -ForegroundColor Red
}

# =====================================
# 5. Register Scheduled Task
# =====================================
Write-Host "[5/6] Registering scheduled task..." -ForegroundColor Yellow

$TaskName = "GPA_DPT_DailyDuplicateScan"

$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop | Out-Null
        Write-Host "[OK] Removed existing scheduled task" -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Could not remove existing task" -ForegroundColor Yellow
    }
}

$Action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$Main`" -Source `"$SourcePath`" -DuplicateRoot `"$DuplicateRoot`""

try {
    [DateTime]$ScanTimeObj = [DateTime]::ParseExact($ScanTime, "HH:mm", $null)
    $Trigger = New-ScheduledTaskTrigger -Daily -At $ScanTimeObj
    
    Register-ScheduledTask -TaskName $TaskName `
                          -Action $Action `
                          -Trigger $Trigger `
                          -Description "GPA DPT - Daily automatic duplicate photo scan" `
                          -Force `
                          -ErrorAction Stop | Out-Null
    Write-Host "[OK] Scheduled task registered (Daily at $ScanTime)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Could not register scheduled task: $_" -ForegroundColor Red
}

# =====================================
# 6. Create AppData directories
# =====================================
Write-Host "[6/6] Setting up directories..." -ForegroundColor Yellow

$AppDataPath = Join-Path $env:APPDATA "GPA Solutions\DPT"
$LogPath = Join-Path $AppDataPath "logs"
$CachePath = Join-Path $AppDataPath "cache"

foreach ($Dir in @($AppDataPath, $LogPath, $CachePath)) {
    if (-not (Test-Path $Dir)) {
        try {
            New-Item -ItemType Directory -Path $Dir -ErrorAction Stop | Out-Null
            Write-Host "[OK] Created directory: $Dir" -ForegroundColor Green
        } catch {
            Write-Host "[WARN] Could not create directory: $Dir" -ForegroundColor Yellow
        }
    }
}

# =====================================
# Installation Summary
# =====================================
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "   GPA DPT Installation Complete" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "SHORTCUTS:" -ForegroundColor Cyan
Write-Host "  Start Menu: $StartMenuLink" -ForegroundColor Gray
Write-Host "  Desktop:   $DesktopLink" -ForegroundColor Gray
Write-Host ""

Write-Host "SCHEDULED TASK:" -ForegroundColor Cyan
Write-Host "  Task Name: $TaskName" -ForegroundColor Gray
Write-Host "  Schedule:  Daily at $ScanTime" -ForegroundColor Gray
Write-Host "  Source:    $SourcePath" -ForegroundColor Gray
Write-Host "  Destination: $DuplicateRoot" -ForegroundColor Gray
Write-Host ""

Write-Host "DIRECTORIES:" -ForegroundColor Cyan
Write-Host "  Logs:  $LogPath" -ForegroundColor Gray
Write-Host "  Cache: $CachePath" -ForegroundColor Gray
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Launch GPA DPT from Start Menu or Desktop" -ForegroundColor Gray
Write-Host "  2. Configure source and duplicate folders" -ForegroundColor Gray
Write-Host "  3. Run your first scan" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $IconPathIco)) {
    Write-Host "ICON SETUP (OPTIONAL):" -ForegroundColor Cyan
    Write-Host "  Convert SVG to ICO for custom shortcut icons:" -ForegroundColor Gray
    Write-Host "  > powershell -File .\branding\convert-to-ico.ps1" -ForegroundColor Gray
    Write-Host "  Or visit: https://convertio.co/svg-ico/" -ForegroundColor Gray
    Write-Host ""
}

$null = Read-Host "Press Enter to exit"
