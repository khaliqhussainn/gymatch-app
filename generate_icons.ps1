Add-Type -AssemblyName System.Drawing

$src    = Resolve-Path "mobile-app\assets\images\pin-icon.png"
$srcImg = [System.Drawing.Image]::FromFile($src.Path)

$sizes = @{
  "mipmap-mdpi"    = 48
  "mipmap-hdpi"    = 72
  "mipmap-xhdpi"   = 96
  "mipmap-xxhdpi"  = 144
  "mipmap-xxxhdpi" = 192
}

foreach ($folder in $sizes.Keys) {
  $size     = $sizes[$folder]
  $destPath = "mobile-app\android\app\src\main\res\$folder\ic_launcher.png"
  $absPath  = (Resolve-Path $destPath).Path

  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g   = [System.Drawing.Graphics]::FromImage($bmp)

  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

  # Fill black background
  $g.Clear([System.Drawing.Color]::Black)

  # Add padding so icon doesn't touch edges (20% padding each side)
  $padding = [int]($size * 0.15)
  $iconSize = $size - ($padding * 2)
  $rect = New-Object System.Drawing.Rectangle($padding, $padding, $iconSize, $iconSize)
  $g.DrawImage($srcImg, $rect)

  $g.Dispose()
  $bmp.Save($absPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()

  Write-Host "OK: $folder ($size x $size) - black bg"
}

$srcImg.Dispose()
Write-Host "Done - all icons generated with black background!"
