$ErrorActionPreference = "Stop"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_FinalClean.zip"
$Sha256 = "798FBD0FB350A8D278B237ED88F2E82300866997D2CB41D108B2563987904404"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

function Write-Step {
    param(
        [string]$Status,
        [int]$Percent
    )

    Write-Progress -Activity "Freedxm Launcher" -Status $Status -PercentComplete $Percent
}

try {
    Write-Step -Status "Connecting to GitHub release..." -Percent 5

    $Headers = @{
        "User-Agent" = "FreedxmLauncherInstaller"
    }

    $ReleaseApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"

    Write-Step -Status "Reading latest release..." -Percent 12
    $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

    Write-Step -Status "Finding package: $AssetName" -Percent 20

    $Asset = $Release.assets |
        Where-Object { $_.name -eq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets | Select-Object -ExpandProperty name) -join ", "
        throw "Cannot find asset '$AssetName' in latest release.`nUpload this file to Release Assets: $AssetName`nAvailable assets: $Available"
    }

    $ZipUrl = $Asset.browser_download_url

    Write-Step -Status "Selected package: $($Asset.name)" -Percent 28

    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Write-Step -Status "Downloading package..." -Percent 42
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

    Write-Step -Status "Checking SHA256..." -Percent 64
    $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
    $ExpectedHash = $Sha256.ToUpperInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA256 mismatch for $AssetName.`nExpected: $ExpectedHash`nActual:   $ActualHash`nFix: upload the new ZIP file again, then commit this run.ps1."
    }

    Write-Step -Status "Installing launcher files..." -Percent 78

    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $InstallDir | Out-Null

    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

    Write-Step -Status "Opening login GUI..." -Percent 92

    $GuiScript = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $GuiScript) {
        throw "FreedxmLauncher.ps1 was not found after install."
    }

    $ArgumentList = "-STA -NoProfile -ExecutionPolicy Bypass -File `"$($GuiScript.FullName)`""

    Start-Process -FilePath "powershell.exe" -ArgumentList $ArgumentList -WindowStyle Normal

    Write-Step -Status "Completed." -Percent 100
    Start-Sleep -Milliseconds 500
    Write-Progress -Activity "Freedxm Launcher" -Completed
}
catch {
    Write-Progress -Activity "Freedxm Launcher" -Completed
    Write-Host ""
    Write-Host "[Freedxm Launcher Error]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Press Enter to close..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
