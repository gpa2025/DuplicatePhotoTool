<#
.SYNOPSIS
    Create a basic ICO file for GPA DPT shortcuts

.DESCRIPTION
    Generates a simple ICO file programmatically when ImageMagick isn't available.

.NOTES
    GPA DPT - Basic Icon Creator
#>

param(
    [string]$OutputPath = "logo-icon.ico"
)

# Check if file already exists
if (Test-Path $OutputPath) {
    Write-Host "[OK] $OutputPath already exists" -ForegroundColor Green
    exit 0
}

Write-Host "[*] Creating basic ICO file..." -ForegroundColor Yellow

# Create a simple 32x32 ICO file with a basic design
# This is a minimal ICO structure - in a real scenario you'd use proper icon creation tools

try {
    # Create a basic bitmap data (simplified - this won't be a perfect icon)
    # For a proper solution, use ImageMagick or online converters
    $icoData = [byte[]]@(
        # ICO Header (simplified)
        0x00, 0x00, # Reserved
        0x01, 0x00, # Type (ICO)
        0x01, 0x00, # Number of images
        
        # Directory entry
        0x20, # Width (32)
        0x20, # Height (32)
        0x00, # Color count
        0x00, # Reserved
        0x01, 0x00, # Color planes
        0x20, 0x00, # Bits per pixel
        
        # Image data size (placeholder)
        0x00, 0x00, 0x00, 0x00,
        # Image data offset (placeholder)
        0x16, 0x00, 0x00, 0x00
    )
    
    # Write the basic ICO structure
    [System.IO.File]::WriteAllBytes($OutputPath, $icoData)
    
    Write-Host "[SUCCESS] Basic ICO file created: $OutputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: This is a placeholder icon. For a proper icon:" -ForegroundColor Yellow
    Write-Host "  1. Use online converter: https://convertio.co/svg-ico/" -ForegroundColor Gray
    Write-Host "  2. Upload logo-icon.svg and download as ICO" -ForegroundColor Gray
    Write-Host "  3. Replace this file" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] Failed to create ICO file: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Use online converter instead:" -ForegroundColor Yellow
    Write-Host "  https://convertio.co/svg-ico/" -ForegroundColor Cyan
}
