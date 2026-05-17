$ErrorActionPreference = "Stop"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"

$AssetHashes = [ordered]@{
    "FreedxmLauncher_AutoLogin.zip" = "5BF321967401DD9AE50ACE0C22B96D4C9B5D7A432E0D00EF73917CAD3646E249"
    "FreedxmLauncher_LoginVisible.zip" = "5BF321967401DD9AE50ACE0C22B96D4C9B5D7A432E0D00EF73917CAD3646E249"
    "FreedxmLauncher_AutoLogin.zip" = "FBCFA7CFB268203208889A265BA21C3DF8AF4533575EEAD08C0203B70835FC60"
    "FreedxmLauncher_LoginSample.zip" = "E704BDDF50DFB48DE8D6B657E047555EED0ADE18D886BF4405EF3A84631D3155"
    "FreedxmLauncher_Borderless.zip" = "E5088D499DCDF695F68BD66CA774858FA8811B285097EB2E4E632F6A2BA64C62"
    "FreedxmLauncher_NoDotnet.zip" = "0CD8F91B9B104DCB4B2F43443F17E302C6984CCB7F65DDCC0B0BA79F45B09DC6"
}

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

    Write-Step -Status "Finding supported ZIP asset..." -Percent 20

    $SelectedAsset = $null
    $SelectedSha256 = $null

    foreach ($AssetName in $AssetHashes.Keys) {
        $Candidate = $Release.assets |
            Where-Object { $_.name -eq $AssetName } |
            Select-Object -First 1

        if ($Candidate) {
            $SelectedAsset = $Candidate
            $SelectedSha256 = $AssetHashes[$AssetName]
            break
        }
    }

    if (-not $SelectedAsset) {
        $Available = ($Release.assets | Select-Object -ExpandProperty name) -join ", "
        throw "Cannot find supported ZIP asset in latest release.`nUpload one of these files: $($AssetHashes.Keys -join ', ')`nAvailable assets: $Available"
    }

    $ZipUrl = $SelectedAsset.browser_download_url

    Write-Step -Status "Selected package: $($SelectedAsset.name)" -Percent 28

    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Write-Step -Status "Downloading package..." -Percent 42
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

    Write-Step -Status "Checking SHA256..." -Percent 64
    $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
    $ExpectedHash = $SelectedSha256.ToUpperInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA256 mismatch for $($SelectedAsset.name).`nExpected: $ExpectedHash`nActual:   $ActualHash`nFix: upload the ZIP file from this ChatGPT package again, or update run.ps1 SHA256."
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
