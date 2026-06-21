$src = "c:\Users\Gabriel\Documents\GitHub\Lufia\lib\loveframes\skins\moon\images\font_page.png"
Add-Type -AssemblyName System.Drawing
$dir  = Split-Path $src
$name = [System.IO.Path]::GetFileNameWithoutExtension($src)

$orig = [System.Drawing.Bitmap]::FromFile($src)
foreach ($scale in 2,3,4) {
    $w = $orig.Width  * $scale
    $h = $orig.Height * $scale
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($orig, 0, 0, $w, $h)
    $g.Dispose()
    $out = Join-Path $dir "$name${scale}x.png"
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Salvo: $out ($w x $h)"
}
$orig.Dispose()
