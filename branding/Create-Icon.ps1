<#
.SYNOPSIS
    Convert SVG logo to ICO format for Windows shortcuts

.DESCRIPTION
    Creates an ICO file from the SVG logo for use in shortcuts.
    Requires ImageMagick or provides instructions for online conversion.

.NOTES
    GPA DPT - Logo Converter
#>

# Navigate to branding directory
$BrandingPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $BrandingPath

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "   GPA DPT - Icon Converter" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$SvgFile = "logo-icon.svg"
$IcoFile = "logo-icon.ico"

# Check if ICO already exists
if (Test-Path $IcoFile) {
    Write-Host "[OK] $IcoFile already exists" -ForegroundColor Green
    Write-Host ""
    Write-Host "If you want to regenerate it, delete the file first." -ForegroundColor Yellow
    exit 0
}

# Check if ImageMagick is available
$MagickPath = "magick.exe"
$MagickExists = $null -ne (Get-Command $MagickPath -ErrorAction SilentlyContinue)

if ($MagickExists) {
    Write-Host "[*] Converting SVG to ICO using ImageMagick..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        & $MagickPath convert -background none "$SvgFile" `
            -define "icon:auto-resize=256,128,96,64,48,32,16" "$IcoFile"
        
        if (Test-Path $IcoFile) {
            Write-Host "[SUCCESS] Icon created: $IcoFile" -ForegroundColor Green
            Write-Host ""
            Write-Host "The shortcut will now display the custom icon!" -ForegroundColor Green
            exit 0
        }
    }
    catch {
        Write-Host "[ERROR] Conversion failed: $_" -ForegroundColor Red
    }
}

# Fallback: Online conversion instructions
Write-Host "[INFO] ImageMagick not found. Use online converter instead:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION 1 - Quick Online Conversion:" -ForegroundColor Cyan
Write-Host "  1. Visit: https://convertio.co/svg-ico/" -ForegroundColor Gray
Write-Host "  2. Upload this file: $SvgFile" -ForegroundColor Gray
Write-Host "  3. Download as: $IcoFile" -ForegroundColor Gray
Write-Host "  4. Place in this folder: $BrandingPath" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 2 - Install ImageMagick:" -ForegroundColor Cyan
Write-Host "  1. Download from: https://imagemagick.org" -ForegroundColor Gray
Write-Host "  2. Run this script again" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 3 - Alternative Tools:" -ForegroundColor Cyan
Write-Host "  • https://icoconvert.com/" -ForegroundColor Gray
Write-Host "  • https://www.freeconvert.com/svg-to-ico" -ForegroundColor Gray
Write-Host ""

Write-Host "After creating the ICO file, re-run the setup script:" -ForegroundColor Yellow
Write-Host "  > powershell -ExecutionPolicy Bypass -File ..\Setup-DPT.ps1" -ForegroundColor Gray
Write-Host ""
