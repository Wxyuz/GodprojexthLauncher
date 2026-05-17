$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_YELLOW_METAL_FRONTFIX.zip"
$Sha256 = "80D69106086C53DCFD5240E94E178D9C76AE7BAA1CC402042ADA1B71423F0F45"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

if (-not ("FreedxmLoaderNativeYellowMetalV5" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class FreedxmLoaderNativeYellowMetalV5
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
}

function Show-ConsoleWindow {
    $handle = [FreedxmLoaderNativeYellowMetalV5]::GetConsoleWindow()

    if ($handle -ne [IntPtr]::Zero) {
        [FreedxmLoaderNativeYellowMetalV5]::ShowWindow($handle, 5) | Out-Null
    }
}

function Minimize-ConsoleWindow {
    $handle = [FreedxmLoaderNativeYellowMetalV5]::GetConsoleWindow()

    if ($handle -ne [IntPtr]::Zero) {
        [FreedxmLoaderNativeYellowMetalV5]::ShowWindow($handle, 6) | Out-Null
    }
}

function Initialize-Loader {
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
    catch {
    }

    try {
        [Console]::CursorVisible = $false
    }
    catch {
    }

    Clear-Host

    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER" -ForegroundColor Yellow
    Write-Host "  Yellow Metal Loader" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Status : Preparing..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [........................................]   0%" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Frame  : 0000" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  GODPROJEXTH metal pixel credit will type, then LOGIN GUI opens." -ForegroundColor DarkYellow
}

function Safe-WriteLine {
    param(
        [int]$Top,
        [string]$Text,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )

    try {
        $width = [Console]::WindowWidth

        if ($width -lt 60) {
            $width = 120
        }

        if ($Text.Length -gt ($width - 1)) {
            $Text = $Text.Substring(0, $width - 1)
        }

        $padded = $Text.PadRight($width - 1)

        [Console]::SetCursorPosition(0, $Top)
        Write-Host $padded -NoNewline -ForegroundColor $Color
    }
    catch {
    }
}

function Draw-YellowLoader {
    param(
        [string]$Status,
        [int]$Percent,
        [int]$Frame
    )

    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))

    $barWidth = 44
    $filled = [int][Math]::Floor(($Percent / 100) * $barWidth)

    if ($filled -lt 0) {
        $filled = 0
    }

    if ($filled -gt $barWidth) {
        $filled = $barWidth
    }

    $empty = $barWidth - $filled
    $pulse = $Frame % 4

    if ($pulse -eq 0) {
        $head = "▓"
    }
    elseif ($pulse -eq 1) {
        $head = "▒"
    }
    elseif ($pulse -eq 2) {
        $head = "░"
    }
    else {
        $head = "▓"
    }

    if ($filled -le 0) {
        $bar = ("░" * $barWidth)
    }
    elseif ($filled -ge $barWidth) {
        $bar = ("█" * $barWidth)
    }
    else {
        $bar = ("█" * ($filled - 1)) + $head + ("░" * $empty)
    }

    $spinnerChars = @("◐", "◓", "◑", "◒")
    $spinner = $spinnerChars[$Frame % $spinnerChars.Count]

    Safe-WriteLine -Top 4 -Text ("  Status : {0} {1}" -f $Status, $spinner) -Color Yellow
    Safe-WriteLine -Top 6 -Text ("  ╔{0}╗" -f ("═" * $barWidth)) -Color DarkYellow
    Safe-WriteLine -Top 7 -Text ("  ║{0}║ {1,3}%" -f $bar, $Percent) -Color Yellow
    Safe-WriteLine -Top 8 -Text ("  ╚{0}╝" -f ("═" * $barWidth)) -Color DarkYellow
    Safe-WriteLine -Top 10 -Text ("  Frame  : {0:0000}" -f $Frame) -Color DarkYellow
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
        Draw-YellowLoader -Status $Status -Percent $value -Frame $FrameRef.Value
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
                    Draw-YellowLoader -Status "Downloading package..." -Percent $downloadPercent -Frame $FrameRef.Value
                }
                else {
                    $softPercent = 42 + ($FrameRef.Value % 18)
                    Draw-YellowLoader -Status "Downloading package..." -Percent $softPercent -Frame $FrameRef.Value
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

function Get-MetalPixelWord {
    $font = @{}

    $font["G"] = @(
        " ██████ ",
        "██      ",
        "██  ███",
        "██   ██",
        " █████ "
    )

    $font["O"] = @(
        " █████ ",
        "██   ██",
        "██   ██",
        "██   ██",
        " █████ "
    )

    $font["D"] = @(
        "██████ ",
        "██   ██",
        "██   ██",
        "██   ██",
        "██████ "
    )

    $font["P"] = @(
        "██████ ",
        "██   ██",
        "██████ ",
        "██     ",
        "██     "
    )

    $font["R"] = @(
        "██████ ",
        "██   ██",
        "██████ ",
        "██  ██ ",
        "██   ██"
    )

    $font["J"] = @(
        "  █████",
        "    ██ ",
        "    ██ ",
        "██  ██ ",
        " ████  "
    )

    $font["E"] = @(
        "███████",
        "██     ",
        "██████ ",
        "██     ",
        "███████"
    )

    $font["X"] = @(
        "██   ██",
        " ██ ██ ",
        "  ███  ",
        " ██ ██ ",
        "██   ██"
    )

    $font["T"] = @(
        "███████",
        "  ███  ",
        "  ███  ",
        "  ███  ",
        "  ███  "
    )

    $font["H"] = @(
        "██   ██",
        "██   ██",
        "███████",
        "██   ██",
        "██   ██"
    )

    $word = "GODPROJEXTH"
    $lines = @("", "", "", "", "")

    foreach ($char in $word.ToCharArray()) {
        $glyph = $font[[string]$char]

        for ($row = 0; $row -lt 5; $row++) {
            $lines[$row] += $glyph[$row] + " "
        }
    }

    return $lines
}

function Show-GodprojexthMetalCredit {
    param([ref]$FrameRef)

    Clear-Host

    $art = Get-MetalPixelWord
    $maxLength = ($art | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    Write-Host ""
    Write-Host ""
    Write-Host "        CREDIT" -ForegroundColor DarkYellow
    Write-Host ""

    for ($column = 1; $column -le $maxLength; $column++) {
        for ($row = 0; $row -lt $art.Count; $row++) {
            $sourceLine = $art[$row]

            if ($column -gt $sourceLine.Length) {
                $part = $sourceLine
            }
            else {
                $part = $sourceLine.Substring(0, $column)
            }

            if ($row -eq 0) {
                $color = [System.ConsoleColor]::White
            }
            elseif ($row -eq 1) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($row -eq 2) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($row -eq 3) {
                $color = [System.ConsoleColor]::DarkYellow
            }
            else {
                $color = [System.ConsoleColor]::DarkYellow
            }

            Safe-WriteLine -Top (4 + $row) -Text ("        " + $part) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("        METAL PIXEL TYPE-IN  frame {0:0000}" -f $FrameRef.Value) -Color DarkYellow
        $FrameRef.Value++
        Start-Sleep -Milliseconds 20
    }

    for ($shine = 0; $shine -lt 60; $shine++) {
        for ($row = 0; $row -lt $art.Count; $row++) {
            $phase = ($shine + $row) % 5

            if ($phase -eq 0) {
                $color = [System.ConsoleColor]::White
            }
            elseif ($phase -eq 1) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($phase -eq 2) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($phase -eq 3) {
                $color = [System.ConsoleColor]::DarkYellow
            }
            else {
                $color = [System.ConsoleColor]::Yellow
            }

            Safe-WriteLine -Top (4 + $row) -Text ("        " + $art[$row]) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("        Opening smooth Login GUI... frame {0:0000}" -f $FrameRef.Value) -Color DarkYellow
        $FrameRef.Value++
        Start-Sleep -Milliseconds 16
    }
}

function Start-SmoothLoginGui {
    param(
        [string]$InstallPath
    )

    $vbsPath = Join-Path $InstallPath "Launch_Login.vbs"
    $psPath = Join-Path $InstallPath "FreedxmLoginSmooth.ps1"

    if (-not (Test-Path -LiteralPath $psPath)) {
        throw "GUI script not found: $psPath"
    }

    if (Test-Path -LiteralPath $vbsPath) {
        $process = Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsPath`"" -PassThru
    }
    else {
        $powerShellExe = Join-Path $PSHOME "powershell.exe"

        if (-not (Test-Path -LiteralPath $powerShellExe)) {
            $powerShellExe = "powershell.exe"
        }

        $arguments = @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-STA",
            "-File",
            "`"$psPath`""
        )

        $process = Start-Process -FilePath $powerShellExe -ArgumentList $arguments -WindowStyle Normal -PassThru
    }

    if (-not $process) {
        throw "Cannot start Login GUI."
    }

    return $process
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Initialize-Loader

    $frame = 0
    $progress = 0

    $progress = Animate-ToPercent -From $progress -To 8 -Status "Connecting to release..." -FrameRef ([ref]$frame)

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

    $progress = Animate-ToPercent -From $progress -To 100 -Status "Completed. Showing metal credit..." -FrameRef ([ref]$frame)

    Show-GodprojexthMetalCredit -FrameRef ([ref]$frame)

    Start-SmoothLoginGui -InstallPath $InstallDir | Out-Null

    Start-Sleep -Milliseconds 1300

    Minimize-ConsoleWindow

    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }
}
catch {
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }

    Show-ConsoleWindow

    Clear-Host
    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER ERROR" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press Enter to close..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
