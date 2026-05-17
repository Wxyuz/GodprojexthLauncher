# FreedxmLauncher one-link installer
# แก้แค่บรรทัด ZipUrl ให้เป็น direct link ของ FreedxmLauncher.zip ของคุณ
# แล้วอัปโหลดไฟล์นี้เป็น run.ps1

$ErrorActionPreference = "Stop"

$ZipUrl = "https://github.com/Wxyuz/GodprojexthLauncher/releases/download/v1.0.0/FreedxmLauncher.1.zip"
$Sha256 = "1A9262B9DC9A00EF662325EE14466246354C929F75636F65D85507520811B075"
$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Write-Host "Freedxm Launcher" -ForegroundColor Cyan
Write-Host "Downloading..." -ForegroundColor Cyan

Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TempRoot | Out-Null

Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing

Write-Host "Checking SHA256..." -ForegroundColor Cyan
$ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()

if ($ActualHash -ne $Sha256.ToUpperInvariant()) {
    Write-Host "Expected: $Sha256" -ForegroundColor Red
    Write-Host "Actual:   $ActualHash" -ForegroundColor Red
    throw "SHA256 mismatch. ZIP file changed or corrupted."
}

Write-Host "Installing..." -ForegroundColor Cyan
Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

$Exe = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
$Bat = Get-ChildItem -Path $InstallDir -Filter "run.bat" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

if ($Exe) {
    Write-Host "Opening FreedxmLauncher.exe..." -ForegroundColor Green
    Start-Process -FilePath $Exe.FullName
}
elseif ($Bat) {
    Write-Host "Opening run.bat..." -ForegroundColor Green
    Start-Process -FilePath $Bat.FullName -WorkingDirectory $Bat.DirectoryName
}
else {
    Write-Host "No EXE or run.bat found. Opening folder..." -ForegroundColor Yellow
    Start-Process explorer.exe $InstallDir
}

Write-Host "Done." -ForegroundColor Green
