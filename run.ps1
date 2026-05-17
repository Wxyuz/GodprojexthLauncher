$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_GODPROJEXTH_ExecPolicyFixed.zip"
$Sha256 = "0773E76FF777B75A6687D5D305C0248C496CEE2A995D4F28E82CF36B114BEE39"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class FreedxmLoaderWindow
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

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
    Write-Host "  FREEDXM LAUNCHER" -ForegroundColor Cyan
    Write-Host "  Smooth PowerShell loader" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Status : Preparing..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [........................................]   0%" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Frame  : 0000" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Login GUI opens after GODPROJEXTH credit." -ForegroundColor DarkGray
}

function Safe-WriteLine {
    param(
        [int]$Top,
        [string]$Text,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )

    try {
        $width = [Console]::WindowWidth

        if ($width -lt 40) {
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
    $bar = ("#" * $filled) + ("." * $empty)

    $spinnerChars = @("|", "/", "-", "\")
    $spinner = $spinnerChars[$Frame % $spinnerChars.Count]

    Safe-WriteLine -Top 4 -Text ("  Status : {0} {1}" -f $Status, $spinner) -Color White
    Safe-WriteLine -Top 6 -Text ("  [{0}] {1,3}%" -f $bar, $Percent) -Color Cyan
    Safe-WriteLine -Top 8 -Text ("  Frame  : {0:0000}" -f $Frame) -Color DarkGray
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

function Get-PixelWord {
    $font = @{}

    $font["G"] = @(" ### ","#    ","#  ##","#   #"," ### ")
    $font["O"] = @(" ### ","#   #","#   #","#   #"," ### ")
    $font["D"] = @("#### ","#   #","#   #","#   #","#### ")
    $font["P"] = @("#### ","#   #","#### ","#    ","#    ")
    $font["R"] = @("#### ","#   #","#### ","#  # ","#   #")
    $font["J"] = @("  ###","   # ","   # ","#  # "," ##  ")
    $font["E"] = @("#####","#    ","#### ","#    ","#####")
    $font["X"] = @("#   #"," # # ","  #  "," # # ","#   #")
    $font["T"] = @("#####","  #  ","  #  ","  #  ","  #  ")
    $font["H"] = @("#   #","#   #","#####","#   #","#   #")

    $word = "GODPROJEXTH"
    $lines = @("", "", "", "", "")

    foreach ($char in $word.ToCharArray()) {
        $glyph = $font[[string]$char]

        for ($i = 0; $i -lt 5; $i++) {
            $lines[$i] += $glyph[$i] + "  "
        }
    }

    return $lines
}

function Show-GodprojexthCredit {
    param([ref]$FrameRef)

    Clear-Host

    $art = Get-PixelWord
    $maxLength = ($art | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    Write-Host ""
    Write-Host ""
    Write-Host "        CREDIT" -ForegroundColor DarkYellow
    Write-Host ""

    for ($column = 1; $column -le $maxLength; $column++) {
        for ($i = 0; $i -lt $art.Count; $i++) {
            $sourceLine = $art[$i]

            if ($column -gt $sourceLine.Length) {
                $part = $sourceLine
            }
            else {
                $part = $sourceLine.Substring(0, $column)
            }

            $colorStep = ($i + [Math]::Floor($column / 3)) % 4

            if ($colorStep -eq 0) {
                $color = [System.ConsoleColor]::DarkYellow
            }
            elseif ($colorStep -eq 1) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($colorStep -eq 2) {
                $color = [System.ConsoleColor]::White
            }
            else {
                $color = [System.ConsoleColor]::Yellow
            }

            Safe-WriteLine -Top (4 + $i) -Text ("        " + $part) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("        Typing GODPROJEXTH credit... frame {0:0000}" -f $FrameRef.Value) -Color DarkGray
        $FrameRef.Value++
        Start-Sleep -Milliseconds 28
    }

    for ($glow = 0; $glow -lt 55; $glow++) {
        for ($i = 0; $i -lt $art.Count; $i++) {
            $colorStep = ($glow + $i) % 4

            if ($colorStep -eq 0) {
                $color = [System.ConsoleColor]::DarkYellow
            }
            elseif ($colorStep -eq 1) {
                $color = [System.ConsoleColor]::Yellow
            }
            elseif ($colorStep -eq 2) {
                $color = [System.ConsoleColor]::White
            }
            else {
                $color = [System.ConsoleColor]::Yellow
            }

            Safe-WriteLine -Top (4 + $i) -Text ("        " + $art[$i]) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("        Opening login interface... frame {0:0000}" -f $FrameRef.Value) -Color DarkGray
        $FrameRef.Value++
        Start-Sleep -Milliseconds 16
    }
}

function Start-LoginGui {
    param(
        [string]$GuiScriptPath
    )

    if (-not (Test-Path -LiteralPath $GuiScriptPath)) {
        throw "GUI script was not found: $GuiScriptPath"
    }

    $powerShellExe = Join-Path $PSHOME "powershell.exe"

    if (-not (Test-Path -LiteralPath $powerShellExe)) {
        $powerShellExe = "powershell.exe"
    }

    $encodedGuiPath = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($GuiScriptPath))

    $guiCommand = @"
`$ErrorActionPreference = 'Stop'
`$ProgressPreference = 'SilentlyContinue'
`$bytes = [Convert]::FromBase64String('$encodedGuiPath')
`$guiPath = [System.Text.Encoding]::Unicode.GetString(`$bytes)
`$code = [System.IO.File]::ReadAllText(`$guiPath, [System.Text.Encoding]::UTF8)
Invoke-Expression `$code
"@

    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($guiCommand))

    $argumentList = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-STA",
        "-EncodedCommand",
        $encodedCommand
    )

    $process = Start-Process -FilePath $powerShellExe -ArgumentList $argumentList -WindowStyle Normal -PassThru

    if (-not $process) {
        throw "Cannot start GUI PowerShell process."
    }

    return $process
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Initialize-Loader

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

    $progress = Animate-ToPercent -From $progress -To 100 -Status "Completed. Showing GODPROJEXTH credit..." -FrameRef ([ref]$frame)

    Show-GodprojexthCredit -FrameRef ([ref]$frame)

    $GuiScript = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $GuiScript) {
        throw "FreedxmLauncher.ps1 was not found after install."
    }

    Start-LoginGui -GuiScriptPath $GuiScript.FullName | Out-Null

    Start-Sleep -Milliseconds 1200

    $ConsoleWindow = [FreedxmLoaderWindow]::GetConsoleWindow()

    if ($ConsoleWindow -ne [IntPtr]::Zero) {
        [FreedxmLoaderWindow]::ShowWindow($ConsoleWindow, 6) | Out-Null
    }

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

    $ConsoleWindow = [FreedxmLoaderWindow]::GetConsoleWindow()

    if ($ConsoleWindow -ne [IntPtr]::Zero) {
        [FreedxmLoaderWindow]::ShowWindow($ConsoleWindow, 5) | Out-Null
    }

    Clear-Host
    Write-Host ""
    Write-Host "  FREEDXM LAUNCHER ERROR" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press Enter to close..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
