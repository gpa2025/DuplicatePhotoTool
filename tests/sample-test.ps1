<#
.SYNOPSIS
    Functional tests for Duplicate Photo Tool.

.DESCRIPTION
    Creates controlled temp environments to validate duplicate detection,
    selection modes, dry-run behavior, and CSV reporting.
#>

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
$MainScript = Join-Path $ScriptRoot "..\src\Find-DuplicatePhotos.ps1"
$PassCount  = 0
$FailCount  = 0

function Assert {
    param([string]$Name, [bool]$Condition)
    if ($Condition) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:PassCount++
    } else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        $script:FailCount++
    }
}

function New-TestEnv {
    $tmp = Join-Path $env:TEMP "DPT_Test_$(Get-Random)"
    $src = Join-Path $tmp "source"
    $dup = Join-Path $tmp "duplicates"
    New-Item -ItemType Directory -Path $src, $dup -Force | Out-Null
    return @{ Root = $tmp; Source = $src; Duplicates = $dup }
}

function Remove-TestEnv($env) {
    Remove-Item $env.Root -Recurse -Force -ErrorAction SilentlyContinue
}

# ============================
# Test 1: Detects duplicates and produces CSV
# ============================

Write-Host "`n--- Test 1: Duplicate detection + CSV report ---" -ForegroundColor Cyan
$env1 = New-TestEnv

$content = "duplicate-content"
Set-Content (Join-Path $env1.Source "photo1.jpg") $content
Set-Content (Join-Path $env1.Source "photo2.jpg") $content
Set-Content (Join-Path $env1.Source "unique.jpg") "unique-content"

& $MainScript -Source $env1.Source -DuplicateRoot $env1.Duplicates -DryRun | Out-Null

$csv = Join-Path $env1.Duplicates "duplicate_report.csv"
Assert "CSV report created"        (Test-Path $csv)

$rows = Import-Csv $csv
Assert "CSV has 1 duplicate entry" ($rows.Count -eq 1)
Assert "CSV Original field set"    ($rows[0].Original -ne "")
Assert "CSV Duplicate field set"   ($rows[0].Duplicate -ne "")
Assert "CSV Hash field set"        ($rows[0].Hash -ne "")

Remove-TestEnv $env1

# ============================
# Test 2: DryRun does not move files
# ============================

Write-Host "`n--- Test 2: DryRun does not move files ---" -ForegroundColor Cyan
$env2 = New-TestEnv

Set-Content (Join-Path $env2.Source "a.jpg") "same"
Set-Content (Join-Path $env2.Source "b.jpg") "same"

& $MainScript -Source $env2.Source -DuplicateRoot $env2.Duplicates -DryRun | Out-Null

$movedFiles = Get-ChildItem $env2.Duplicates -Recurse -File | Where-Object { $_.Name -notmatch '^(duplicate_report\.csv|checksum_cache\.db|scan_log_.*\.txt)$' }
Assert "DryRun: no files moved" ($movedFiles.Count -eq 0)
Assert "DryRun: source files intact" ((Get-ChildItem $env2.Source -File).Count -eq 2)

Remove-TestEnv $env2

# ============================
# Test 3: First file is always kept
# ============================

Write-Host "`n--- Test 3: First file encountered is kept ---" -ForegroundColor Cyan
$env3 = New-TestEnv

$first  = Join-Path $env3.Source "aaa_first.jpg"
$second = Join-Path $env3.Source "zzz_second.jpg"
Set-Content $first  "same-content" -NoNewline
Set-Content $second "same-content" -NoNewline

& $MainScript -Source $env3.Source -DuplicateRoot $env3.Duplicates -DryRun | Out-Null

$csv3 = Import-Csv (Join-Path $env3.Duplicates "duplicate_report.csv")
Assert "First kept: second file is the duplicate" ($csv3[0].Duplicate -like "*zzz_second.jpg")
Assert "First kept: first file is the original"   ($csv3[0].Original  -like "*aaa_first.jpg")

Remove-TestEnv $env3

# ============================
# Test 4: Log includes original path
# ============================

Write-Host "`n--- Test 4: Log includes original path ---" -ForegroundColor Cyan
$env4 = New-TestEnv

Set-Content (Join-Path $env4.Source "copy1.jpg") "data" -NoNewline
Set-Content (Join-Path $env4.Source "copy2.jpg") "data" -NoNewline

& $MainScript -Source $env4.Source -DuplicateRoot $env4.Duplicates -DryRun | Out-Null
$csv4 = Import-Csv (Join-Path $env4.Duplicates "duplicate_report.csv")
Assert "Log shows original path" ($csv4[0].Original -match "copy(1|2)\.jpg")

Remove-TestEnv $env4

# ============================
# Test 5: No duplicates produces empty CSV
# ============================

Write-Host "`n--- Test 5: No duplicates ---" -ForegroundColor Cyan
$env5 = New-TestEnv

Set-Content (Join-Path $env5.Source "unique1.jpg") "aaa"
Set-Content (Join-Path $env5.Source "unique2.jpg") "bbb"

& $MainScript -Source $env5.Source -DuplicateRoot $env5.Duplicates -DryRun | Out-Null

$csv5 = Join-Path $env5.Duplicates "duplicate_report.csv"
$rows5 = if (Test-Path $csv5) { Import-Csv $csv5 } else { @() }
Assert "No duplicates: CSV is empty" ($rows5.Count -eq 0)

Remove-TestEnv $env5

# ============================
# Test 6: Checksum cache is created
# ============================

Write-Host "`n--- Test 6: Checksum cache created ---" -ForegroundColor Cyan
$env6 = New-TestEnv

Set-Content (Join-Path $env6.Source "img.jpg") "data"

& $MainScript -Source $env6.Source -DuplicateRoot $env6.Duplicates -DryRun | Out-Null

Assert "Cache file exists" (Test-Path (Join-Path $env6.Duplicates "checksum_cache.db"))

Remove-TestEnv $env6

# ============================
# Summary
# ============================

Write-Host "`n=============================" -ForegroundColor Cyan
Write-Host "Results: $PassCount passed, $FailCount failed" -ForegroundColor $(if ($FailCount -eq 0) { "Green" } else { "Red" })
Write-Host "=============================" -ForegroundColor Cyan

if ($FailCount -gt 0) { exit 1 }
