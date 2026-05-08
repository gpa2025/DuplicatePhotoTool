<#
.SYNOPSIS
    Generates logo-icon.ico using .NET System.Drawing — no ImageMagick required.
#>

Add-Type -AssemblyName System.Drawing

$OutputPath = Join-Path $PSScriptRoot "logo-icon.ico"

function New-DptBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode   = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $navy  = [System.Drawing.Color]::FromArgb(255, 15,  23,  42)
    $cyan  = [System.Drawing.Color]::FromArgb(255,  0, 217, 255)
    $cyan2 = [System.Drawing.Color]::FromArgb(153,  0, 217, 255)   # 60% opacity
    $green = [System.Drawing.Color]::FromArgb(255, 16, 185, 129)
    $white = [System.Drawing.Color]::White

    $s = $size / 256.0   # scale factor

    # Background with rounded rect
    $g.Clear($navy)
    $radius = [int](32 * $s)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $radius*2, $radius*2, 180, 90)
    $path.AddArc($size - $radius*2, 0, $radius*2, $radius*2, 270, 90)
    $path.AddArc($size - $radius*2, $size - $radius*2, $radius*2, $radius*2, 0, 90)
    $path.AddArc(0, $size - $radius*2, $radius*2, $radius*2, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush($navy)), $path)

    # Helper: scaled rect
    function SR($x,$y,$w,$h) {
        New-Object System.Drawing.RectangleF(($x*$s),($y*$s),($w*$s),($h*$s))
    }

    $penCyan  = New-Object System.Drawing.Pen($cyan,  [float](4*$s))
    $penCyan2 = New-Object System.Drawing.Pen($cyan2, [float](4*$s))
    $penW     = New-Object System.Drawing.Pen($white, [float](3*$s))
    $penW.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $penW.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

    $brushCyan  = New-Object System.Drawing.SolidBrush($cyan)
    $brushCyan2 = New-Object System.Drawing.SolidBrush($cyan2)
    $brushGreen = New-Object System.Drawing.SolidBrush($green)
    $brushWhite = New-Object System.Drawing.SolidBrush($white)

    # --- Back photo frame (offset 35,35) ---
    $g.DrawRectangle($penCyan2, [float](80*$s), [float](80*$s), [float](100*$s), [float](100*$s))
    $g.DrawLine($penCyan2, [float](80*$s), [float](100*$s), [float](180*$s), [float](100*$s))
    $g.FillEllipse($brushCyan2, [float](95*$s), [float](113*$s), [float](24*$s), [float](24*$s))

    # --- Front photo frame (offset 45,45, size 100x100) ---
    $g.DrawRectangle($penCyan, [float](45*$s), [float](45*$s), [float](100*$s), [float](100*$s))
    $g.DrawLine($penCyan, [float](45*$s), [float](65*$s), [float](145*$s), [float](65*$s))
    $g.FillEllipse($brushCyan, [float](58*$s), [float](78*$s), [float](24*$s), [float](24*$s))

    # Mountain triangle on front frame
    $tri = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new([float](120*$s), [float](125*$s)),
        [System.Drawing.PointF]::new([float](145*$s), [float](90*$s)),
        [System.Drawing.PointF]::new([float](145*$s), [float](125*$s))
    )
    $g.FillPolygon($brushCyan, $tri)

    # --- Green checkmark circle (center ~140,135) ---
    $cx = [float](140*$s); $cy = [float](135*$s); $cr = [float](18*$s)
    $g.FillEllipse($brushGreen, $cx-$cr, $cy-$cr, $cr*2, $cr*2)

    # Checkmark path
    $g.DrawLine($penW, $cx-[float](8*$s), $cy,              $cx-[float](2*$s), $cy+[float](6*$s))
    $g.DrawLine($penW, $cx-[float](2*$s), $cy+[float](6*$s), $cx+[float](8*$s), $cy-[float](3*$s))

    $g.Dispose()
    return $bmp
}

# Build ICO with 4 sizes
$sizes = @(256, 64, 32, 16)
$bitmaps = $sizes | ForEach-Object { New-DptBitmap $_ }

# Write ICO file manually (ICONDIR + ICONDIRENTRY + PNG data per size)
$stream = New-Object System.IO.MemoryStream

# We'll encode each size as PNG into a byte array
$pngArrays = foreach ($bmp in $bitmaps) {
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    ,$ms.ToArray()
    $ms.Dispose()
}

$writer = New-Object System.IO.BinaryWriter($stream)

# ICONDIR header
$writer.Write([uint16]0)              # reserved
$writer.Write([uint16]1)              # type = ICO
$writer.Write([uint16]$sizes.Count)  # image count

# Calculate offsets: header(6) + entries(16 * count)
$dataOffset = 6 + 16 * $sizes.Count

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz = $sizes[$i]
    $w  = if ($sz -ge 256) { 0 } else { $sz }   # 0 means 256 in ICO spec
    $h  = $w
    $writer.Write([byte]$w)           # width
    $writer.Write([byte]$h)           # height
    $writer.Write([byte]0)            # color count
    $writer.Write([byte]0)            # reserved
    $writer.Write([uint16]1)          # color planes
    $writer.Write([uint16]32)         # bits per pixel
    $writer.Write([uint32]$pngArrays[$i].Length)
    $writer.Write([uint32]$dataOffset)
    $dataOffset += $pngArrays[$i].Length
}

foreach ($png in $pngArrays) {
    $writer.Write($png)
}

$writer.Flush()
[System.IO.File]::WriteAllBytes($OutputPath, $stream.ToArray())
$stream.Dispose()

foreach ($bmp in $bitmaps) { $bmp.Dispose() }

Write-Host "[OK] Icon created: $OutputPath" -ForegroundColor Green
