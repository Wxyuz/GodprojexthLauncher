$ErrorActionPreference = "Stop"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$PreferredAssetName = "FreedxmLauncher_LoginFixed.zip"
$Sha256 = "FBCFA7CFB268203208889A265BA21C3DF8AF4533575EEAD08C0203B70835FC60"

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

    Write-Step -Status "Reading release data..." -Percent 12
    $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

    Write-Step -Status "Finding package: $PreferredAssetName" -Percent 20
    $Asset = $Release.assets |
        Where-Object { $_.name -eq $PreferredAssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        throw "Cannot find asset '$PreferredAssetName' in latest release."
    }

    $ZipUrl = $Asset.browser_download_url

    Write-Step -Status "Preparing temporary folder..." -Percent 30
    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Write-Step -Status "Downloading package..." -Percent 42
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

    Write-Step -Status "Checking SHA256..." -Percent 64
    $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
    $ExpectedHash = $Sha256.ToUpperInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA256 mismatch.`nExpected: $ExpectedHash`nActual:   $ActualHash"
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

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "powershell.exe"
    $ProcessInfo.Arguments = "-STA -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$($GuiScript.FullName)`""
    $ProcessInfo.UseShellExecute = $true
    $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

    [System.Diagnostics.Process]::Start($ProcessInfo) | Out-Null

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
