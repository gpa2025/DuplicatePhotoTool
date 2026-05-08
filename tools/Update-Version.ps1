<#
.SYNOPSIS
    Bumps the project version (Semantic Versioning).

.PARAMETER Part
    major | minor | patch

.EXAMPLE
    .\Update-Version.ps1 -Part minor
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major","minor","patch")]
    [string]$Part
)

$versionFile = Join-Path $PSScriptRoot "..\VERSION"

if (-not (Test-Path $versionFile)) {
    Write-Host "VERSION file not found." -ForegroundColor Red
    exit
}

$current = Get-Content $versionFile
$parts = $current.Split(".")

$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

switch ($Part) {
    "major" { $major++; $minor = 0; $patch = 0 }
    "minor" { $minor++; $patch = 0 }
    "patch" { $patch++ }
}

$newVersion = "$major.$minor.$patch"
$newVersion | Set-Content $versionFile

Write-Host "Version updated: $current → $newVersion" -ForegroundColor Green
