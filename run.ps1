$ErrorActionPreference = "Stop"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$PreferredAssetName = "FreedxmLauncher_NoDotnet.zip"
$Sha256 = "0CD8F91B9B104DCB4B2F43443F17E302C6984CCB7F65DDCC0B0BA79F45B09DC6"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Write-Host "Freedxm Launcher" -ForegroundColor Cyan
Write-Host "Finding latest release..." -ForegroundColor Cyan

$Headers = @{
    "User-Agent" = "FreedxmLauncherInstaller"
}

$ReleaseApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
$Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

$Asset = $Release.assets |
    Where-Object { $_.name -eq $PreferredAssetName } |
    Select-Object -First 1

if (-not $Asset) {
    $Asset = $Release.assets |
        Where-Object { $_.name -like "*.zip" } |
        Select-Object -First 1
}

if (-not $Asset) {
    throw "No .zip asset found in latest release."
}

$ZipUrl = $Asset.browser_download_url

Write-Host "Found asset: $($Asset.name)" -ForegroundColor Green
Write-Host "Downloading..." -ForegroundColor Cyan

Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TempRoot | Out-Null

Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

Write-Host "Checking SHA256..." -ForegroundColor Cyan

$ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
$ExpectedHash = $Sha256.ToUpperInvariant()

if ($ActualHash -ne $ExpectedHash) {
    Write-Host "Expected: $ExpectedHash" -ForegroundColor Red
    Write-Host "Actual:   $ActualHash" -ForegroundColor Red
    throw "SHA256 mismatch. ZIP file changed or corrupted."
}

Write-Host "Installing..." -ForegroundColor Cyan

Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $InstallDir | Out-Null

Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

$Exe = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
$Bat = Get-ChildItem -Path $InstallDir -Filter "run.bat" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
$Ps1 = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

if ($Exe) {
    Write-Host "Opening FreedxmLauncher.exe..." -ForegroundColor Green
    Start-Process -FilePath $Exe.FullName
}
elseif ($Bat) {
    Write-Host "Opening run.bat..." -ForegroundColor Green
    Start-Process -FilePath $Bat.FullName -WorkingDirectory $Bat.DirectoryName
}
elseif ($Ps1) {
    Write-Host "Opening FreedxmLauncher.ps1..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($Ps1.FullName)`""
}
else {
    Write-Host "No EXE, run.bat, or FreedxmLauncher.ps1 found. Opening folder..." -ForegroundColor Yellow
    Start-Process explorer.exe $InstallDir
}

Write-Host "Done." -ForegroundColor Green
