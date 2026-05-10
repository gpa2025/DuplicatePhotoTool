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

    [switch]$DryRun,

    [ValidateRange(1,16)]
    [int]$ThrottleLimit = 4,

    [ValidateSet("INFO","WARN","ERROR")]
    [string]$LogLevel = "INFO"
)

$LogFile = Join-Path $DuplicateRoot "scan_log.txt"

# ============================
# Utility Functions
# ============================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] [$Level] $Message"

    if ($Level -eq "ERROR" -or
       ($Level -eq "WARN" -and $LogLevel -in "INFO","WARN") -or
       ($Level -eq "INFO" -and $LogLevel -eq "INFO")) {

        $color = switch ($Level) {
            "INFO"  { "Green" }
            "WARN"  { "Yellow" }
            "ERROR" { "Red" }
        }

        Write-Host $line -ForegroundColor $color
        Add-Content -Path $LogFile -Value $line
    }
}

# ============================
# Start Timer
# ============================

$Timer = [System.Diagnostics.Stopwatch]::StartNew()

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
# Compute Hashes (parallel with caching)
# ============================

# Snapshot cache for read-only use inside parallel blocks
$CacheSnapshot = $ChecksumCache

Write-Log "Using $ThrottleLimit core(s) for hashing." "INFO"

# Split files into batches — one per core to avoid per-file runspace overhead
$batchSize = [Math]::Ceiling($Files.Count / $ThrottleLimit)
$batches = [System.Collections.Generic.List[object[]]]::new()
for ($i = 0; $i -lt $Files.Count; $i += $batchSize) {
    $end = [Math]::Min($i + $batchSize - 1, $Files.Count - 1)
    $batches.Add($Files[$i..$end])
}

$script:batchNum = 0
$totalBatches = $batches.Count

$HashResults = $batches | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $cache      = $using:CacheSnapshot
    $results    = [System.Collections.Generic.List[PSCustomObject]]::new()
    $batchFiles = $_

    foreach ($File in $batchFiles) {
        $key  = $File.FullName
        $hash = $null

        if ($cache.ContainsKey($key)) {
            $entry = $cache[$key]
            if ($entry.LastWriteTime -eq $File.LastWriteTimeUtc.ToString() -and
                $entry.Length -eq $File.Length) {
                $hash = $entry.Hash
            }
        }

        if (-not $hash) {
            $hash = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash
        }

        $results.Add([PSCustomObject]@{
            Path          = $File.FullName
            Hash          = $hash
            LastWriteTime = $File.LastWriteTimeUtc.ToString()
            Length        = $File.Length
            CacheHit      = ($null -ne $cache[$key] -and $cache[$key].Hash -eq $hash)
        })
    }

    # Report batch completion
    $done = [System.Threading.Interlocked]::Increment([ref]$using:script:batchNum)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [INFO] Batch $done/$($using:totalBatches) complete ($($batchFiles.Count) files)." -ForegroundColor Green

    $results
}

# Log progress summary after hashing
$cached = ($HashResults | Where-Object { $_.CacheHit }).Count
$hashed = ($HashResults | Where-Object { -not $_.CacheHit }).Count
Write-Log "Hashing complete: $hashed hashed, $cached from cache." "INFO"

# Update cache with any new/changed hashes and log newly hashed files
foreach ($result in $HashResults) {
    if (-not $result.CacheHit) {
        Write-Log "Hashed: $($result.Path)" "INFO"
        $ChecksumCache[$result.Path] = @{
            Hash          = $result.Hash
            LastWriteTime = $result.LastWriteTime
            Length        = $result.Length
        }
    }
}

# Save cache
$ChecksumCache | ConvertTo-Json -Depth 3 | Set-Content $CachePath

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

    $Original = $Group.Group[0].Path

    $Duplicates = $Group.Group | Where-Object { $_.Path -ne $Original }

    foreach ($Dup in $Duplicates) {

        # Safety check — never move the original
        if ([System.IO.Path]::GetFullPath($Dup.Path) -eq [System.IO.Path]::GetFullPath($Original)) {
            Write-Log "Skipping original: $($Dup.Path)" "WARN"
            continue
        }

        $relative = [System.IO.Path]::GetRelativePath($Source, $Dup.Path)
        $dest = Join-Path $DuplicateRoot $relative
        $destDir = Split-Path $dest -Parent

        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        if ($DryRun) {
            Write-Log "[DryRun] Would move: $($Dup.Path) → $dest (original kept: $Original)" "WARN"
        } else {
            Move-Item -Path $Dup.Path -Destination $dest -Force
            Write-Log "Moved duplicate: $($Dup.Path) → $dest (original kept: $Original)" "INFO"
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

$Timer.Stop()
$elapsed = $Timer.Elapsed
$elapsedStr = if ($elapsed.TotalMinutes -ge 1) {
    "{0}m {1}s" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds
} else {
    "{0:N1}s" -f $elapsed.TotalSeconds
}

Write-Log "Scan complete in $elapsedStr. $($Groups.Count) duplicate group(s) found, $($Report.Count) file(s) processed." "INFO"
