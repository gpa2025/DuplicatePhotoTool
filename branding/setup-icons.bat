@echo off
REM Quick icon setup for GPA DPT
REM This batch file helps convert SVG to ICO or use online tools

echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  GPA DPT - Icon Setup Helper                       ║
echo ╚════════════════════════════════════════════════════╝
echo.

REM Check if icon already exists
if exist logo-icon.ico (
    echo [OK] logo-icon.ico already exists
    echo.
    echo Re-run Setup-DPT.ps1 to apply custom icons to shortcuts:
    echo   powershell -ExecutionPolicy Bypass -File ..\Setup-DPT.ps1
    echo.
    pause
    exit /b 0
)

echo [HELP] Convert SVG to ICO using one of these methods:
echo.
echo Method 1 - Using ImageMagick (if installed):
echo   magick.exe convert -background none logo-icon.svg ^
echo     -define icon:auto-resize=256,128,96,64,48,32,16 logo-icon.ico
echo.
echo Method 2 - Online converter (no installation needed):
echo   1. Visit: https://convertio.co/svg-ico/
echo   2. Upload: logo-icon.svg
echo   3. Download: logo-icon.ico
echo   4. Place in: branding\ folder
echo   5. Re-run setup script
echo.
echo Method 3 - Free alternative tools:
echo   • https://icoconvert.com/
echo   • https://www.freeconvert.com/svg-to-ico
echo.
pause
