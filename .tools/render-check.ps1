param([string]$Frame='frame')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$image=New-Object System.Drawing.Bitmap 480,270
$g=[System.Drawing.Graphics]::FromImage($image)
$brushes=@{}
foreach($line in Get-Content "$PSScriptRoot/palette.csv") {
    $p=$line.Split(','); $c=[int]$p[1]
    $r=($c -band 31)*255/31; $green=(($c -shr 5) -band 31)*255/31; $b=(($c -shr 10) -band 31)*255/31
    $brushes[$p[0]]=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb([int]$r,[int]$green,[int]$b))
}
$font=New-Object System.Drawing.Font 'Consolas',7
foreach($line in Get-Content "$PSScriptRoot/$Frame.csv") {
    $p=$line.Split(',')
    switch($p[0]) {
        'tri' {
            $points=[System.Drawing.Point[]]@((New-Object System.Drawing.Point ([int]$p[1]),([int]$p[2])),(New-Object System.Drawing.Point ([int]$p[3]),([int]$p[4])),(New-Object System.Drawing.Point ([int]$p[5]),([int]$p[6])))
            $g.FillPolygon($brushes[$p[7]],$points)
        }
        'rect' { $g.FillRectangle($brushes[$p[5]],[int]$p[1],[int]$p[2],([int]$p[3]-[int]$p[1]),([int]$p[4]-[int]$p[2])) }
        'text' { $g.DrawString($p[4],$font,$brushes[$p[3]],[single]$p[1],[single]$p[2]) }
    }
}
$output=if($Frame -eq 'frame') { 'preview' } else { $Frame }
$image.Save("$PSScriptRoot/$output.png",[System.Drawing.Imaging.ImageFormat]::Png)
$font.Dispose(); $g.Dispose(); $image.Dispose()
foreach($brush in $brushes.Values) { $brush.Dispose() }
