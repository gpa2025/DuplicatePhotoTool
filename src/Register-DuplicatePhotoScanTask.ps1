<#
.SYNOPSIS
    Registers a Windows Scheduled Task to run the Duplicate Photo Tool automatically.

.DESCRIPTION
    Creates or updates a scheduled task that runs Find-DuplicatePhotos.ps1
    at a specified time and with specified parameters.

.PARAMETER ScriptPath
    Full path to Find-DuplicatePhotos.ps1

.PARAMETER Source
    Folder to scan

.PARAMETER DuplicateRoot
    Folder where duplicates will be moved

.PARAMETER Time
    Time of day to run the task (HH:mm)

.EXAMPLE
    .\Register-DuplicatePhotoScanTask.ps1 `
        -ScriptPath "D:\GitRepo\DuplicatePhotoTool\src\Find-DuplicatePhotos.ps1" `
        -Source "D:\Pictures" `
        -DuplicateRoot "D:\Duplicates" `
        -Time "02:00"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,

    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$DuplicateRoot,

    [Parameter(Mandatory=$true)]
    [string]$Time
)

# ============================
# Validate Inputs
# ============================

if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: ScriptPath does not exist." -ForegroundColor Red
    exit
}

if (-not (Test-Path $Source)) {
    Write-Host "ERROR: Source folder does not exist." -ForegroundColor Red
    exit
}

if (-not (Test-Path $DuplicateRoot)) {
    Write-Host "DuplicateRoot does not exist. Creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DuplicateRoot -Force | Out-Null
}

# ============================
# Build Task Action
# ============================

$Action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Source `"$Source`" -DuplicateRoot `"$DuplicateRoot`""

# ============================
# Build Trigger
# ============================

try {
    $Trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date $Time)
}
catch {
    Write-Host "ERROR: Invalid time format. Use HH:mm (e.g., 02:00)" -ForegroundColor Red
    exit
}

# ============================
# Register Task
# ============================

$TaskName = "DuplicatePhotoScan"

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -RunLevel Highest -Force

Write-Host "Scheduled task '$TaskName' created successfully." -ForegroundColor Green
Write-Host "It will run daily at $Time." -ForegroundColor Green
