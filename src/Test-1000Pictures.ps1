<#
.SYNOPSIS
    Test runner for duplicate photo detection against first 1000 pictures.

.DESCRIPTION
    Collects first 1000 photo files from d:\pictures (recursively by subfolder),
    runs Find-DuplicatePhotos.ps1 in LIVE mode, and displays results.

.NOTES
    - Scans root folder first, then subfolders in order until 1000 files collected
    - Uses 4 CPU cores for hashing
    - Moves duplicates to d:\duplicates
    - Shows results via GUI, CLI, and CSV
#>

param(
    [string]$SourcePath = "d:\pictures",
    [string]$DuplicateRoot = "d:\duplicates",
    [int]$FilesLimit = 1000,
    [int]$Cores = 4
)

$startTime = Get-Date
Write-Host "`n════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Duplicate Photo Tool - TEST RUN" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Cyan

# ============================
# Validate paths
# ============================

if (-not (Test-Path $SourcePath)) {
    Write-Host "❌ Source path does not exist: $SourcePath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Source: $SourcePath" -ForegroundColor White
Write-Host "📁 Duplicates will move to: $DuplicateRoot" -ForegroundColor White
Write-Host "🧵 Using $Cores cores for hashing" -ForegroundColor White
Write-Host "🎯 Collecting first $FilesLimit files`n" -ForegroundColor White

# ============================
# Collect first 1000 files recursively by folder
# ============================

Write-Host "📂 Collecting files..." -ForegroundColor Yellow

$allFiles = @()

# First, get files from root
$rootFiles = @(Get-ChildItem -Path $SourcePath -File -ErrorAction SilentlyContinue)
$allFiles += $rootFiles

Write-Host "   Root folder: $($rootFiles.Count) files" -ForegroundColor Gray

# If not enough, get from subfolders in order
if ($allFiles.Count -lt $FilesLimit) {
    $subdirs = @(Get-ChildItem -Path $SourcePath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    
    foreach ($subdir in $subdirs) {
        if ($allFiles.Count -ge $FilesLimit) { break }
        
        $subFiles = @(Get-ChildItem -Path $subdir.FullName -File -Recurse -ErrorAction SilentlyContinue)
        $needed = $FilesLimit - $allFiles.Count
        $toAdd = $subFiles | Select-Object -First $needed
        $allFiles += $toAdd
        
        Write-Host "   $($subdir.Name): +$($toAdd.Count) files (total: $($allFiles.Count))" -ForegroundColor Gray
    }
}

$allFiles = $allFiles | Select-Object -First $FilesLimit

Write-Host "`n✓ Collected $($allFiles.Count) files for testing" -ForegroundColor Green

# ============================
# Create staging folder
# ============================

$stagingPath = Join-Path $env:TEMP "DPT-TestRun-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

Write-Host "📝 Creating staging folder: $stagingPath" -ForegroundColor Yellow

# Copy or symlink files (use symlink for speed, fallback to copy)
$linkCount = 0
$copyCount = 0

foreach ($file in $allFiles) {
    $dest = Join-Path $stagingPath $file.Name
    
    try {
        # Try creating symlink (fast, no disk copy)
        cmd /c mklink "$dest" "$($file.FullName)" 2>&1 | Out-Null
        $linkCount++
    } catch {
        # Fallback to copy if symlink fails
        Copy-Item -Path $file.FullName -Destination $dest -ErrorAction SilentlyContinue
        $copyCount++
    }
}

Write-Host "   Symlinks: $linkCount | Copies: $copyCount" -ForegroundColor Gray

# ============================
# Run Find-DuplicatePhotos
# ============================

Write-Host "`n🚀 Starting duplicate scan (LIVE mode)...`n" -ForegroundColor Cyan

$scriptPath = Join-Path $PSScriptRoot "Find-DuplicatePhotos.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

# Create duplicates folder
if (-not (Test-Path $DuplicateRoot)) {
    New-Item -ItemType Directory -Path $DuplicateRoot -Force | Out-Null
}

# Run the scan
& $scriptPath -Source $stagingPath -DuplicateRoot $DuplicateRoot -ThrottleLimit $Cores

# ============================
# Clean up staging folder
# ============================

Write-Host "`n🧹 Cleaning up staging folder..." -ForegroundColor Yellow
Remove-Item -Path $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Staging folder removed" -ForegroundColor Green

# ============================
# Show Results
# ============================

Write-Host "`n════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RESULTS AVAILABLE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Cyan

# 1. CSV Report
$csvPath = Join-Path $DuplicateRoot "duplicate_report.csv"
if (Test-Path $csvPath) {
    Write-Host "📊 1. CSV REPORT" -ForegroundColor Cyan
    Write-Host "   Location: $csvPath" -ForegroundColor Gray
    $csvData = Import-Csv $csvPath
    Write-Host "   Duplicates found: $($csvData.Count)" -ForegroundColor Green
    Write-Host ""
}

# 2. Database Query (CLI with clickable links)
Write-Host "📋 2. COMMAND-LINE QUERY (with clickable links)" -ForegroundColor Cyan
Write-Host "   Run this command to see detailed results with clickable file links:" -ForegroundColor Gray
Write-Host "   " -NoNewline
Write-Host ".\Query-DuplicateDatabase.ps1 -Database '$DuplicateRoot\checksum_cache.db' -Action ShowAll" -ForegroundColor Yellow
Write-Host ""

# 3. GUI - Show View Results
Write-Host "🔍 3. GUI RESULTS VIEW" -ForegroundColor Cyan
Write-Host "   Open the GUI and:" -ForegroundColor Gray
Write-Host "   - Set output folder to: $DuplicateRoot" -ForegroundColor Gray
Write-Host "   - Click '🔍 View Results' button to see all duplicates" -ForegroundColor Gray
Write-Host "   - Click '🗄️ Database' button to browse with LiteDB Studio" -ForegroundColor Gray
Write-Host ""

# 4. Log file
$logPath = Get-ChildItem -Path $DuplicateRoot -Filter "scan_log_*.txt" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

if ($logPath) {
    Write-Host "📄 4. SCAN LOG" -ForegroundColor Cyan
    Write-Host "   Location: $logPath" -ForegroundColor Gray
    Write-Host ""
}

# Summary
$elapsed = ((Get-Date) - $startTime).TotalSeconds
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Test run complete in $([math]::Round($elapsed, 1)) seconds" -ForegroundColor Green
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Cyan
