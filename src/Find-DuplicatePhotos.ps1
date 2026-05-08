<#
.SYNOPSIS
    Duplicate Photo Finder with hashing, caching, logging, and smart selection modes.

.DESCRIPTION
    Scans a source directory for duplicate photos using SHA256 hashing.
    Supports checksum caching for faster re-scans, CSV reporting, and
    duplicate selection modes (First, Newest, Largest).

.PARAMETER Source
    The root folder to scan for photos.

.PARAMETER DuplicateRoot
    The folder where duplicates will be moved.

.PARAMETER SelectionMode
    Determines which file to keep:
        - First   : Keep the first file encountered
        - Newest  : Keep the file with the latest LastWriteTime
        - Largest : Keep the file with the largest file size

.PARAMETER DryRun
    If set, no files will be moved.

.PARAMETER LogLevel
    Controls verbosity: INFO, WARN, ERROR

.EXAMPLE
    .\Find-DuplicatePhotos.ps1 -Source "D:\Pictures" -DuplicateRoot "D:\Duplicates" -SelectionMode Newest
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$DuplicateRoot,

    [ValidateSet("First","Newest","Largest")]
    [string]$SelectionMode = "First",

    [switch]$DryRun,

    [ValidateSet("INFO","WARN","ERROR")]
    [string]$LogLevel = "INFO"
)

# ============================
# Utility Functions
# ============================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    if ($Level -eq "ERROR" -or
       ($Level -eq "WARN" -and $LogLevel -in "INFO","WARN") -or
       ($Level -eq "INFO" -and $LogLevel -eq "INFO")) {

        $color = switch ($Level) {
            "INFO"  { "Green" }
            "WARN"  { "Yellow" }
            "ERROR" { "Red" }
        }

        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

# ============================
# Load or Create Checksum Cache
# ============================

$CachePath = Join-Path $DuplicateRoot "checksum_cache.json"

if (Test-Path $CachePath) {
    Write-Log "Loading checksum cache..." "INFO"
    $ChecksumCache = Get-Content $CachePath | ConvertFrom-Json -AsHashtable
} else {
    $ChecksumCache = @{}
}

# ============================
# Scan Files
# ============================

Write-Log "Scanning source folder: $Source" "INFO"

$Files = Get-ChildItem -Path $Source -Recurse -File -ErrorAction SilentlyContinue

Write-Log "Found $($Files.Count) files." "INFO"

# ============================
# Compute Hashes (with caching)
# ============================

$HashResults = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($File in $Files) {

    $key = $File.FullName
    $hash = $null

    if ($ChecksumCache.ContainsKey($key)) {
        $entry = $ChecksumCache[$key]
        if ($entry.LastWriteTime -eq $File.LastWriteTimeUtc.ToString() -and
            $entry.Length -eq $File.Length) {
            $hash = $entry.Hash
        }
    }

    if (-not $hash) {
        Write-Log "Hashing: $($File.FullName)" "INFO"
        $hash = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash
        $ChecksumCache[$key] = @{
            Hash          = $hash
            LastWriteTime = $File.LastWriteTimeUtc.ToString()
            Length        = $File.Length
        }
    }

    $HashResults.Add([PSCustomObject]@{ Path = $File.FullName; Hash = $hash })
}

# Save cache
$ChecksumCache | ConvertTo-Json | Set-Content $CachePath

# ============================
# Group by Hash
# ============================

$Groups = $HashResults | Group-Object Hash | Where-Object { $_.Count -gt 1 }

Write-Log "Found $($Groups.Count) duplicate groups." "INFO"

# ============================
# Process Duplicates
# ============================

$Report = @()

foreach ($Group in $Groups) {

    # Determine original based on selection mode
    switch ($SelectionMode) {
        "First"   { $Original = $Group.Group[0].Path }
        "Newest"  { $Original = ($Group.Group | Sort-Object { (Get-Item $_.Path).LastWriteTime } -Descending)[0].Path }
        "Largest" { $Original = ($Group.Group | Sort-Object { (Get-Item $_.Path).Length } -Descending)[0].Path }
    }

    $Duplicates = $Group.Group | Where-Object { $_.Path -ne $Original }

    foreach ($Dup in $Duplicates) {

        $relative = [System.IO.Path]::GetRelativePath($Source, $Dup.Path)
        $dest = Join-Path $DuplicateRoot $relative
        $destDir = Split-Path $dest -Parent

        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if ($DryRun) {
            Write-Log "[DryRun] Would move: $($Dup.Path) → $dest" "WARN"
        } else {
            Move-Item -Path $Dup.Path -Destination $dest -Force
            Write-Log "Moved duplicate: $($Dup.Path) → $dest" "INFO"
        }

        $Report += [PSCustomObject]@{
            Original   = $Original
            Duplicate  = $Dup.Path
            Destination = $dest
            Hash       = $Group.Name
        }
    }
}

# ============================
# Save CSV Report
# ============================

$CsvPath = Join-Path $DuplicateRoot "duplicate_report.csv"
$Report | Export-Csv -Path $CsvPath -NoTypeInformation

Write-Log "Report saved to $CsvPath" "INFO"
Write-Log "Done." "INFO"
