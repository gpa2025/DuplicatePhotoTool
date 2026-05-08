<#
.SYNOPSIS
    Converts SVG logos to ICO format for Windows shortcuts

.DESCRIPTION
    Uses ImageMagick (if available) or provides alternatives for ICO creation
#>

param(
    [string]$SvgPath = "logo-icon.svg",
    [string]$OutputPath = "logo-icon.ico",
    [int]$Size = 256
)

# Check if ImageMagick is installed
$MagickExists = $null -ne (Get-Command magick.exe -ErrorAction SilentlyContinue)

if ($MagickExists) {
    Write-Host "Converting SVG to ICO using ImageMagick..." -ForegroundColor Cyan
    
    # Convert SVG to ICO with proper dimensions
    & magick.exe convert -background none "$SvgPath" -define icon:auto-resize=256,128,96,64,48,32,16 "$OutputPath"
    
    if (Test-Path $OutputPath) {
        Write-Host "✓ Successfully created: $OutputPath" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Failed to create ICO file" -ForegroundColor Red
    }
}
else {
    Write-Host "⚠ ImageMagick not found. Install it from: https://imagemagick.org" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Use an online SVG to ICO converter:" -ForegroundColor Yellow
    Write-Host "  https://convertio.co/svg-ico/" -ForegroundColor Cyan
}
