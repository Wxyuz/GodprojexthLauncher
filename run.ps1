$ErrorActionPreference = "Stop"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_ProRounded.zip"
$Sha256 = "EE160E94C6289B680F0E44C73AA2E2CA7746E2D8A6CF83527AC060ED9E60649C"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class RunConsoleWindow
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

function Show-Loader {
    param(
        [string]$Status,
        [int]$Percent
    )

    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))
    $barWidth = 36
    $filled = [Math]::Floor(($Percent / 100) * $barWidth)
    $empty = $barWidth - $filled

    $bar = ("█" * $filled) + ("░" * $empty)

    Clear-Host

    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER" -ForegroundColor Cyan
    Write-Host "  Professional one-link loader" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Status : " -NoNewline -ForegroundColor DarkGray
    Write-Host $Status -ForegroundColor White
    Write-Host ""
    Write-Host "  [" -NoNewline -ForegroundColor DarkGray
    Write-Host $bar -NoNewline -ForegroundColor Cyan
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$Percent%" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please wait..." -ForegroundColor DarkGray
}

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::CursorVisible = $false

    Show-Loader -Status "Connecting to GitHub release..." -Percent 5

    $Headers = @{
        "User-Agent" = "FreedxmLauncherInstaller"
    }

    $ReleaseApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"

    Show-Loader -Status "Reading latest release..." -Percent 12
    $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

    Show-Loader -Status "Finding package: $AssetName" -Percent 20

    $Asset = $Release.assets |
        Where-Object { $_.name -eq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets | Select-Object -ExpandProperty name) -join ", "
        throw "Cannot find asset '$AssetName' in latest release.`nUpload this file to Release Assets: $AssetName`nAvailable assets: $Available"
    }

    $ZipUrl = $Asset.browser_download_url

    Show-Loader -Status "Selected package: $($Asset.name)" -Percent 28

    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Show-Loader -Status "Downloading package..." -Percent 42
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

    Show-Loader -Status "Checking SHA256..." -Percent 64
    $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
    $ExpectedHash = $Sha256.ToUpperInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA256 mismatch for $AssetName.`nExpected: $ExpectedHash`nActual:   $ActualHash`nFix: upload the new ZIP file again, then commit this run.ps1."
    }

    Show-Loader -Status "Installing launcher files..." -Percent 78

    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $InstallDir | Out-Null

    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

    Show-Loader -Status "Opening login GUI..." -Percent 92

    $GuiScript = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $GuiScript) {
        throw "FreedxmLauncher.ps1 was not found after install."
    }

    $ArgumentList = "-STA -NoProfile -ExecutionPolicy Bypass -File `"$($GuiScript.FullName)`""

    Start-Process -FilePath "powershell.exe" -ArgumentList $ArgumentList -WindowStyle Hidden

    Show-Loader -Status "Completed." -Percent 100
    Start-Sleep -Milliseconds 700

    $ConsoleWindow = [RunConsoleWindow]::GetConsoleWindow()
    if ($ConsoleWindow -ne [IntPtr]::Zero) {
        [RunConsoleWindow]::ShowWindow($ConsoleWindow, 6) | Out-Null
    }

    [Console]::CursorVisible = $true
}
catch {
    [Console]::CursorVisible = $true
    Clear-Host
    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER ERROR" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press Enter to close..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
