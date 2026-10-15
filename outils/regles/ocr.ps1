# OCR en français intégré à Windows (Windows.Media.Ocr), sans rien installer.
# Usage : powershell -NoProfile -ExecutionPolicy Bypass -File ocr.ps1 <dossier de PNG> <fichier .txt de sortie>
# Lit les PNG du dossier dans l'ordre des noms et écrit leur texte, page par page, en UTF-8.
param([string]$Dossier, [string]$Sortie)
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType=WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType=WindowsRuntime]
$null = [Windows.Globalization.Language, Windows.Globalization, ContentType=WindowsRuntime]
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op, $t) { $task = $asTask.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(); $task.Result }
$eng = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('fr-FR'))
if ($null -eq $eng) { Write-Error "OCR fr-FR absent de Windows"; exit 1 }
$lignes = New-Object System.Collections.Generic.List[string]
foreach ($png in (Get-ChildItem -Path $Dossier -Filter *.png | Sort-Object Name)) {
  $lignes.Add("===== page " + ($png.BaseName -replace '.*-p', ''))
  $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($png.FullName)) ([Windows.Storage.StorageFile])
  $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
  $dec = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
  $bmp = Await ($dec.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
  $res = Await ($eng.RecognizeAsync($bmp)) ([Windows.Media.Ocr.OcrResult])
  foreach ($l in $res.Lines) { $lignes.Add($l.Text) }
  $stream.Dispose()
}
[IO.File]::WriteAllLines($Sortie, $lignes, [Text.UTF8Encoding]::new($false))
