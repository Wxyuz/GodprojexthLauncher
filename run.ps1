$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_Smooth60.zip"
$Sha256 = "EBDD1615097CA757DBD95B7E42CB22350A7DEBA63900B71D40347C6AE865E707"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class LoaderConsoleWindow
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

function Initialize-ConsoleLoader {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::CursorVisible = $false

    Clear-Host

    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER" -ForegroundColor Cyan
    Write-Host "  Smooth 60 FPS PowerShell loader" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Status : Preparing..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [----------------------------------------] 0%" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Frame  : 0000" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Please wait. The login window will open automatically." -ForegroundColor DarkGray
}

function Write-CleanLine {
    param(
        [int]$Top,
        [string]$Text,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )

    $width = [Console]::WindowWidth
    if ($width -lt 20) {
        $width = 120
    }

    if ($Text.Length -gt ($width - 1)) {
        $Text = $Text.Substring(0, $width - 1)
    }

    $padded = $Text.PadRight($width - 1)

    [Console]::SetCursorPosition(0, $Top)
    Write-Host $padded -NoNewline -ForegroundColor $Color
}

function Draw-Loader {
    param(
        [string]$Status,
        [int]$Percent,
        [int]$Frame
    )

    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))

    $barWidth = 40
    $filled = [int][Math]::Floor(($Percent / 100) * $barWidth)

    if ($filled -lt 0) {
        $filled = 0
    }

    if ($filled -gt $barWidth) {
        $filled = $barWidth
    }

    $empty = $barWidth - $filled
    $bar = ("#" * $filled) + ("-" * $empty)

    $spinnerChars = @("|", "/", "-", "\")
    $spinner = $spinnerChars[$Frame % $spinnerChars.Count]

    Write-CleanLine -Top 4 -Text ("  Status : {0} {1}" -f $Status, $spinner) -Color White
    Write-CleanLine -Top 6 -Text ("  [{0}] {1,3}%" -f $bar, $Percent) -Color Cyan
    Write-CleanLine -Top 8 -Text ("  Frame  : {0:0000}" -f $Frame) -Color DarkGray
}

function Animate-ToPercent {
    param(
        [int]$From,
        [int]$To,
        [string]$Status,
        [ref]$FrameRef
    )

    if ($To -lt $From) {
        $To = $From
    }

    for ($value = $From; $value -le $To; $value++) {
        Draw-Loader -Status $Status -Percent $value -Frame $FrameRef.Value
        $FrameRef.Value++
        Start-Sleep -Milliseconds 16
    }

    return $To
}

function Download-FileSmooth {
    param(
        [string]$Url,
        [string]$OutFile,
        [hashtable]$Headers,
        [ref]$FrameRef
    )

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = "GET"
    $request.AllowAutoRedirect = $true
    $request.UserAgent = $Headers["User-Agent"]

    $response = $null
    $inputStream = $null
    $outputStream = $null

    try {
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength

        $inputStream = $response.GetResponseStream()
        $outputStream = [System.IO.File]::Create($OutFile)

        $buffer = New-Object byte[] 65536
        $totalRead = 0L
        $lastDraw = [Environment]::TickCount

        while ($true) {
            $read = $inputStream.Read($buffer, 0, $buffer.Length)

            if ($read -le 0) {
                break
            }

            $outputStream.Write($buffer, 0, $read)
            $totalRead += $read

            $now = [Environment]::TickCount
            if (($now - $lastDraw) -ge 16) {
                if ($totalBytes -gt 0) {
                    $downloadPercent = [int](35 + (($totalRead / $totalBytes) * 28))
                    Draw-Loader -Status "Downloading package..." -Percent $downloadPercent -Frame $FrameRef.Value
                }
                else {
                    $softPercent = 42 + ($FrameRef.Value % 18)
                    Draw-Loader -Status "Downloading package..." -Percent $softPercent -Frame $FrameRef.Value
                }

                $FrameRef.Value++
                $lastDraw = $now
            }
        }
    }
    finally {
        if ($outputStream -ne $null) {
            $outputStream.Close()
            $outputStream.Dispose()
        }

        if ($inputStream -ne $null) {
            $inputStream.Close()
            $inputStream.Dispose()
        }

        if ($response -ne $null) {
            $response.Close()
        }
    }
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Initialize-ConsoleLoader

    $frame = 0
    $progress = 0

    $progress = Animate-ToPercent -From $progress -To 8 -Status "Connecting to GitHub release..." -FrameRef ([ref]$frame)

    $Headers = @{
        "User-Agent" = "FreedxmLauncherInstaller"
    }

    $ReleaseApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"

    $progress = Animate-ToPercent -From $progress -To 16 -Status "Reading latest release..." -FrameRef ([ref]$frame)
    $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

    $progress = Animate-ToPercent -From $progress -To 25 -Status "Finding package: $AssetName" -FrameRef ([ref]$frame)

    $Asset = $Release.assets |
        Where-Object { $_.name -eq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets | Select-Object -ExpandProperty name) -join ", "
        throw "Cannot find asset '$AssetName' in latest release.`nUpload this file to Release Assets: $AssetName`nAvailable assets: $Available"
    }

    $ZipUrl = $Asset.browser_download_url

    $progress = Animate-ToPercent -From $progress -To 34 -Status "Preparing download folder..." -FrameRef ([ref]$frame)

    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $TempRoot | Out-Null

    Download-FileSmooth -Url $ZipUrl -OutFile $TempZip -Headers $Headers -FrameRef ([ref]$frame)

    $progress = Animate-ToPercent -From 64 -To 72 -Status "Checking SHA256..." -FrameRef ([ref]$frame)

    $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
    $ExpectedHash = $Sha256.ToUpperInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        throw "SHA256 mismatch for $AssetName.`nExpected: $ExpectedHash`nActual:   $ActualHash`nFix: upload the new ZIP file again, then commit this run.ps1."
    }

    $progress = Animate-ToPercent -From $progress -To 84 -Status "Installing launcher files..." -FrameRef ([ref]$frame)

    Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $InstallDir | Out-Null

    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

    $progress = Animate-ToPercent -From $progress -To 94 -Status "Preparing login window..." -FrameRef ([ref]$frame)

    $GuiScript = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $GuiScript) {
        throw "FreedxmLauncher.ps1 was not found after install."
    }

    $ArgumentList = "-STA -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$($GuiScript.FullName)`""

    Start-Process -FilePath "powershell.exe" -ArgumentList $ArgumentList -WindowStyle Hidden

    $progress = Animate-ToPercent -From $progress -To 100 -Status "Completed. Opening login..." -FrameRef ([ref]$frame)

    Start-Sleep -Milliseconds 450

    $ConsoleWindow = [LoaderConsoleWindow]::GetConsoleWindow()
    if ($ConsoleWindow -ne [IntPtr]::Zero) {
        [LoaderConsoleWindow]::ShowWindow($ConsoleWindow, 6) | Out-Null
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
