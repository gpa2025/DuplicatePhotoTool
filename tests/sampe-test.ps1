<#
.SYNOPSIS
    Basic sanity tests for Duplicate Photo Tool.

.DESCRIPTION
    This script performs lightweight checks to ensure the main components
    of the Duplicate Photo Tool are present and functional.

    These are NOT full Pester tests — just quick validation helpers.
#>

Write-Host "Running Duplicate Photo Tool sanity checks..." -ForegroundColor Cyan

# ============================
# 1. Check required files exist
# ============================

$RequiredFiles = @(
    "..\src\Find-DuplicatePhotos.ps1",
    "..\src\DuplicatePhotoTool-GUI.ps1",
    "..\src\Register-DuplicatePhotoScanTask.ps1"
)

foreach ($file in $RequiredFiles) {
    if (Test-Path $file) {
        Write-Host "[OK] $file found." -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $file missing!" -ForegroundColor Red
    }
}

# ============================
# 2. Check PowerShell version
# ============================

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Host "[OK] PowerShell 7+ detected." -ForegroundColor Green
} else {
    Write-Host "[WARN] PowerShell 7+ recommended." -ForegroundColor Yellow
}

# ============================
# 3. Test import of main script
# ============================

try {
    . "..\src\Find-DuplicatePhotos.ps1" -ErrorAction Stop
    Write-Host "[OK] Main script loads without syntax errors." -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error loading main script:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ============================
# 4. Test GUI script loads
# ============================

try {
    Get-Content "..\src\DuplicatePhotoTool-GUI.ps1" | Out-Null
    Write-Host "[OK] GUI script readable." -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] GUI script unreadable!" -ForegroundColor Red
}

# ============================
# 5. Final message
# ============================

Write-Host "Sanity checks complete." -ForegroundColor Cyan
