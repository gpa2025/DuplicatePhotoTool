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

$LogFile = Join-Path $DuplicateRoot ("scan_log_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".txt")

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
# Load LiteDB
# ============================

$LibPath = Join-Path $PSScriptRoot "..\lib\LiteDB.dll"
if (-not (Test-Path $LibPath)) {
    Write-Error "LiteDB.dll not found at $LibPath. Please place LiteDB.dll in the lib\ folder."
    exit 1
}
Add-Type -Path $LibPath

# ============================
# Open Database
# ============================

$DbPath  = Join-Path $PSScriptRoot "checksum_cache.db"
$db      = [LiteDB.LiteDatabase]::new("Filename=$DbPath;Connection=shared")
$colFiles = $db.GetCollection[LiteDB.BsonDocument]("files")
$colScans = $db.GetCollection[LiteDB.BsonDocument]("scan_history")
$colFiles.EnsureIndex("path")  # index on path for fast lookups

# ============================
# Scan Files
# ============================

Write-Log "Scanning source folder: $Source" "INFO"

$Files = Get-ChildItem -Path $Source -Recurse -File -ErrorAction SilentlyContinue

Write-Log "Found $($Files.Count) files." "INFO"

# ============================
# Compute Hashes (parallel with caching)
# ============================

# ============================
# Build cache snapshot from DB
# ============================

Write-Log "Loading index database..." "INFO"
$CacheSnapshot = @{}
$allDocs = $colFiles.FindAll()
foreach ($doc in $allDocs) {
    $CacheSnapshot[$doc["path"].AsString] = @{
        Hash          = $doc["hash"].AsString
        LastWriteTime = $doc["lastWriteTime"].AsString
        Length        = $doc["length"].AsInt64
    }
}
Write-Log "Index loaded: $($CacheSnapshot.Count) entries." "INFO"

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

# Update DB with new/changed hashes
$db.BeginTrans() | Out-Null
foreach ($result in $HashResults) {
    if (-not $result.CacheHit) {
        Write-Log "Hashed: $($result.Path)" "INFO"
        $doc = [LiteDB.BsonDocument]::new()
        $doc["path"]          = [LiteDB.BsonValue]::new($result.Path)
        $doc["hash"]          = [LiteDB.BsonValue]::new($result.Hash)
        $doc["lastWriteTime"] = [LiteDB.BsonValue]::new($result.LastWriteTime)
        $doc["length"]        = [LiteDB.BsonValue]::new([long]$result.Length)
        $colFiles.Upsert($doc) | Out-Null
    }
}
$db.Commit() | Out-Null

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

    # Sort group by path for deterministic original selection
    # Prefer files inside $Source over files inside $DuplicateRoot
    $sorted = $Group.Group | Sort-Object {
        $p = $_.Path
        # Files inside DuplicateRoot are always duplicates, never originals
        if ($p.StartsWith($DuplicateRoot, [System.StringComparison]::OrdinalIgnoreCase)) { 1 } else { 0 }
    }, { $_.Path }

    $Original = $sorted[0].Path

    # Safety check — original must be inside Source, not DuplicateRoot
    if ($Original.StartsWith($DuplicateRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Log "WARNING: All copies of hash $($Group.Name) are in DuplicateRoot — skipping group." "WARN"
        continue
    }

    $Duplicates = $sorted | Select-Object -Skip 1

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

# Save scan history to DB
$scanDoc = [LiteDB.BsonDocument]::new()
$scanDoc["scanDate"]       = [LiteDB.BsonValue]::new((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
$scanDoc["source"]         = [LiteDB.BsonValue]::new($Source)
$scanDoc["filesFound"]     = [LiteDB.BsonValue]::new([int]$Files.Count)
$scanDoc["duplicateGroups"]= [LiteDB.BsonValue]::new([int]$Groups.Count)
$scanDoc["filesMoved"]     = [LiteDB.BsonValue]::new([int]$Report.Count)
$scanDoc["elapsedSeconds"] = [LiteDB.BsonValue]::new([double]$elapsed.TotalSeconds)
$scanDoc["dryRun"]         = [LiteDB.BsonValue]::new([bool]$DryRun)
$colScans.Insert($scanDoc) | Out-Null

$db.Dispose()

Write-Log "Scan complete in $elapsedStr. $($Groups.Count) duplicate group(s) found, $($Report.Count) file(s) processed." "INFO"
