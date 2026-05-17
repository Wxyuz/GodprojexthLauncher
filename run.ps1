$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$RunUrl = "https://raw.githubusercontent.com/Wxyuz/GodprojexthLauncher/main/run.ps1"

if ($env:FREEDXM_STA_RELAUNCHED -ne "1") {
    try {
        $apartment = [System.Threading.Thread]::CurrentThread.GetApartmentState()

        if ($apartment -ne [System.Threading.ApartmentState]::STA) {
            $env:FREEDXM_STA_RELAUNCHED = "1"
            $relay = "iex (iwr -UseBasicParsing '$RunUrl')"
            $encodedRelay = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($relay))
            $powerShellExe = Join-Path $PSHOME "powershell.exe"

            if (-not (Test-Path -LiteralPath $powerShellExe)) {
                $powerShellExe = "powershell.exe"
            }

            Start-Process -FilePath $powerShellExe -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-STA",
                "-EncodedCommand",
                $encodedRelay
            ) -WindowStyle Normal | Out-Null

            return
        }
    }
    catch {
    }
}

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_GOLD_VISIBLE_LOGIN_WORKING.zip"
$Sha256 = "C3D7FF26E3924A26578D4789322BD95CD961718C001A7C6B472402461410CF23"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

if (-not ("FreedxmVisibleNativeV9" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class FreedxmVisibleNativeV9
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, int wParam, int lParam);

    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateRoundRectRgn(
        int nLeftRect,
        int nTopRect,
        int nRightRect,
        int nBottomRect,
        int nWidthEllipse,
        int nHeightEllipse
    );

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
}
"@
}

function Show-ConsoleWindow {
    try {
        $handle = [FreedxmVisibleNativeV9]::GetConsoleWindow()

        if ($handle -ne [IntPtr]::Zero) {
            [FreedxmVisibleNativeV9]::ShowWindow($handle, 5) | Out-Null
        }
    }
    catch {
    }
}

function Minimize-ConsoleWindow {
    try {
        $handle = [FreedxmVisibleNativeV9]::GetConsoleWindow()

        if ($handle -ne [IntPtr]::Zero) {
            [FreedxmVisibleNativeV9]::ShowWindow($handle, 6) | Out-Null
        }
    }
    catch {
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
    Write-Host "  Gold Visible Login Working" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Status : Preparing..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [--------------------------------------------]   0%" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Frame  : 0000" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Loading data, then opening Login GUI in the same PowerShell session." -ForegroundColor DarkYellow
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

function Draw-GoldLoader {
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

    if ($filled -eq 0) {
        $bar = "-" * $barWidth
    }
    elseif ($filled -ge $barWidth) {
        $bar = "#" * $barWidth
    }
    else {
        $bar = ("#" * $filled) + ("-" * $empty)
    }

    $spinnerChars = @("|", "/", "-", "\")
    $spinner = $spinnerChars[$Frame % $spinnerChars.Count]

    Safe-WriteLine -Top 4 -Text ("  Status : {0} {1}" -f $Status, $spinner) -Color Yellow
    Safe-WriteLine -Top 6 -Text ("  +{0}+" -f ("=" * $barWidth)) -Color DarkYellow
    Safe-WriteLine -Top 7 -Text ("  |{0}| {1,3}%" -f $bar, $Percent) -Color Yellow
    Safe-WriteLine -Top 8 -Text ("  +{0}+" -f ("=" * $barWidth)) -Color DarkYellow
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
        Draw-GoldLoader -Status $Status -Percent $value -Frame $FrameRef.Value
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
                    Draw-GoldLoader -Status "Downloading package..." -Percent $downloadPercent -Frame $FrameRef.Value
                }
                else {
                    $softPercent = 42 + ($FrameRef.Value % 18)
                    Draw-GoldLoader -Status "Downloading package..." -Percent $softPercent -Frame $FrameRef.Value
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

function Get-GoldPixelWord {
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

        for ($row = 0; $row -lt 5; $row++) {
            $lines[$row] += $glyph[$row] + " "
        }
    }

    return $lines
}

function Show-GoldGodCredit {
    param([ref]$FrameRef)

    Clear-Host

    $art = Get-GoldPixelWord
    $maxLength = ($art | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

    Write-Host ""
    Write-Host ""
    Write-Host "  CREDIT" -ForegroundColor DarkYellow
    Write-Host ""

    for ($column = 1; $column -le $maxLength; $column++) {
        for ($row = 0; $row -lt $art.Count; $row++) {
            $line = $art[$row]

            if ($column -gt $line.Length) {
                $part = $line
            }
            else {
                $part = $line.Substring(0, $column)
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

            Safe-WriteLine -Top (4 + $row) -Text ("  " + $part) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("  GOLD PIXEL CREDIT  frame {0:0000}" -f $FrameRef.Value) -Color DarkYellow
        $FrameRef.Value++
        Start-Sleep -Milliseconds 24
    }

    for ($shine = 0; $shine -lt 40; $shine++) {
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

            Safe-WriteLine -Top (4 + $row) -Text ("  " + $art[$row]) -Color $color
        }

        Safe-WriteLine -Top 11 -Text ("  Opening Login GUI... frame {0:0000}" -f $FrameRef.Value) -Color DarkYellow
        $FrameRef.Value++
        Start-Sleep -Milliseconds 16
    }
}

function Show-LoginGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()

    try {
        [FreedxmVisibleNativeV9]::SetProcessDPIAware() | Out-Null
    }
    catch {
    }

    function New-C {
        param([string]$Hex)
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    }

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $baseWidth = 430
    $baseHeight = 640
    $script:Scale = [Math]::Min(1.0, [Math]::Min(($screen.Width * 0.92) / $baseWidth, ($screen.Height * 0.92) / $baseHeight))

    if ($script:Scale -lt 0.82) {
        $script:Scale = 0.82
    }

    function U {
        param([double]$Value)
        return [int][Math]::Round($Value * $script:Scale)
    }

    function New-Font {
        param(
            [double]$Size,
            [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
        )

        return New-Object System.Drawing.Font("Segoe UI", [float]([Math]::Max(6.0, $Size * $script:Scale)), $Style)
    }

    function Set-Round {
        param(
            [System.Windows.Forms.Control]$Control,
            [int]$Radius
        )

        if ($null -eq $Control) {
            return
        }

        if ($Control.Width -le 0 -or $Control.Height -le 0) {
            return
        }

        $round = [Math]::Max(2, (U $Radius))
        $regionPointer = [FreedxmVisibleNativeV9]::CreateRoundRectRgn(
            0,
            0,
            $Control.Width + 1,
            $Control.Height + 1,
            $round,
            $round
        )

        $Control.Region = [System.Drawing.Region]::FromHrgn($regionPointer)
    }

    function Enable-Drag {
        param(
            [System.Windows.Forms.Control]$Control,
            [System.Windows.Forms.Form]$Form
        )

        $Control.Add_MouseDown({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                [FreedxmVisibleNativeV9]::ReleaseCapture() | Out-Null
                [FreedxmVisibleNativeV9]::SendMessage($Form.Handle, 0xA1, 0x2, 0) | Out-Null
            }
        })
    }

    function Bring-LoginFront {
        param([System.Windows.Forms.Form]$Form)

        try {
            $Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
            $Form.Show()
            $Form.Activate()
            $Form.Focus()
            $Form.BringToFront()
            [FreedxmVisibleNativeV9]::BringWindowToTop($Form.Handle) | Out-Null
            [FreedxmVisibleNativeV9]::SetForegroundWindow($Form.Handle) | Out-Null
        }
        catch {
        }
    }

    function Label {
        param(
            [string]$Text,
            [int]$X,
            [int]$Y,
            [int]$W,
            [int]$H,
            [double]$Size,
            [string]$Color,
            [bool]$Bold = $false
        )

        $label = New-Object System.Windows.Forms.Label
        $label.Text = $Text
        $label.Location = New-Object System.Drawing.Point((U $X), (U $Y))
        $label.Size = New-Object System.Drawing.Size((U $W), (U $H))
        $label.BackColor = [System.Drawing.Color]::Transparent
        $label.ForeColor = New-C $Color

        $style = [System.Drawing.FontStyle]::Regular

        if ($Bold) {
            $style = [System.Drawing.FontStyle]::Bold
        }

        $label.Font = New-Font -Size $Size -Style $style
        $label.AutoEllipsis = $true

        return $label
    }

    function Panel {
        param(
            [int]$X,
            [int]$Y,
            [int]$W,
            [int]$H,
            [string]$Back,
            [int]$Radius = 0
        )

        $panel = New-Object System.Windows.Forms.Panel
        $panel.Location = New-Object System.Drawing.Point((U $X), (U $Y))
        $panel.Size = New-Object System.Drawing.Size((U $W), (U $H))
        $panel.BackColor = New-C $Back

        if ($Radius -gt 0) {
            $panel.Add_HandleCreated({
                Set-Round -Control $panel -Radius $Radius
            })

            $panel.Add_SizeChanged({
                Set-Round -Control $panel -Radius $Radius
            })
        }

        return $panel
    }

    function Button {
        param(
            [string]$Text,
            [int]$X,
            [int]$Y,
            [int]$W,
            [int]$H,
            [string]$Back = "#5FA0FF",
            [string]$Fore = "#07111F",
            [int]$Radius = 16
        )

        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point((U $X), (U $Y))
        $button.Size = New-Object System.Drawing.Size((U $W), (U $H))
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderSize = 0
        $button.BackColor = New-C $Back
        $button.ForeColor = New-C $Fore
        $button.Font = New-Font -Size 10 -Style ([System.Drawing.FontStyle]::Bold)
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $button.TabStop = $true
        $button.UseVisualStyleBackColor = $false

        $button.Add_HandleCreated({
            Set-Round -Control $button -Radius $Radius
        })

        $button.Add_SizeChanged({
            Set-Round -Control $button -Radius $Radius
        })

        return $button
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Freedxm Launcher"
    $form.Size = New-Object System.Drawing.Size((U $baseWidth), (U $baseHeight))
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = New-C "#050910"
    $form.ShowInTaskbar = $true
    $form.TopMost = $true
    $form.Opacity = 1
    $form.KeyPreview = $true

    $form.Add_HandleCreated({
        Set-Round -Control $form -Radius 34
    })

    $form.Add_Resize({
        Set-Round -Control $form -Radius 34
    })

    $root = Panel 0 0 430 640 "#020617" 34
    $root.Dock = [System.Windows.Forms.DockStyle]::Fill
    $form.Controls.Add($root)

    $main = Panel 10 10 410 620 "#050910" 30
    $root.Controls.Add($main)

    $header = Panel 16 16 378 54 "#0B1220" 18
    $main.Controls.Add($header)
    Enable-Drag -Control $header -Form $form

    $logo = Panel 14 14 26 26 "#5FA0FF" 9
    $header.Controls.Add($logo)
    $logo.Controls.Add((Label "N" 7 3 16 18 10 "#FFFFFF" $true))

    $brand = Label "NEVER" 52 15 120 22 11 "#FFFFFF" $true
    $header.Controls.Add($brand)
    Enable-Drag -Control $brand -Form $form

    $min = Button "-" 272 11 30 30 "#111827" "#94A3B8" 10
    $close = Button "x" 306 11 30 30 "#111827" "#94A3B8" 10
    $theme = Button "moon" 340 7 32 40 "#5FA0FF" "#07111F" 12
    $theme.Font = New-Font -Size 7.5 -Style ([System.Drawing.FontStyle]::Bold)

    $header.Controls.Add($min)
    $header.Controls.Add($close)
    $header.Controls.Add($theme)

    $min.Add_Click({
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    })

    $close.Add_Click({
        $form.Close()
    })

    $body = Panel 16 82 378 510 "#050910" 0
    $main.Controls.Add($body)

    $loginPanel = New-Object System.Windows.Forms.Panel
    $loginPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $loginPanel.BackColor = New-C "#050910"
    $body.Controls.Add($loginPanel)

    $modePanel = New-Object System.Windows.Forms.Panel
    $modePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $modePanel.BackColor = New-C "#050910"
    $modePanel.Visible = $false
    $body.Controls.Add($modePanel)

    $hero = Panel 10 4 358 168 "#08111F" 18
    $loginPanel.Controls.Add($hero)
    $heroInner = Panel 8 8 342 152 "#0A1A2C" 14
    $hero.Controls.Add($heroInner)

    $heroInner.Controls.Add((Label "----    ----    -----" 120 12 156 18 7.5 "#CBD5E1"))
    $heroInner.Controls.Add((Label "NEVERSTORE" 22 34 180 22 14 "#6B7C93" $true))
    $heroInner.Controls.Add((Label "launcher interface" 24 53 132 12 6.5 "#475569"))
    $heroInner.Controls.Add((Label "Mode" 22 72 125 32 23 "#667085"))
    $heroInner.Controls.Add((Label "Hyper" 22 100 160 36 29 "#8190A5"))
    $heroInner.Controls.Add((Label "BOTTLE" 22 130 100 18 9 "#FFFFFF" $true))
    $heroInner.Controls.Add((Label "Stable visible login window,`nand cleaner aligned layout." 22 143 300 28 7 "#A3B1C6"))

    $welcome = Label "Welcome Back!" 0 188 378 28 16 "#FFFFFF" $true
    $welcome.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($welcome)

    $sub = Label "Please enter your key to continue." 0 216 378 18 9 "#94A3B8"
    $sub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($sub)

    $keyPanel = Panel 10 254 358 48 "#0B1220" 16
    $loginPanel.Controls.Add($keyPanel)
    $keyPanel.Controls.Add((Label "key" 16 13 34 22 8 "#64748B"))

    $keyBox = New-Object System.Windows.Forms.TextBox
    $keyBox.Location = New-Object System.Drawing.Point((U 56), (U 14))
    $keyBox.Size = New-Object System.Drawing.Size((U 282), (U 22))
    $keyBox.Font = New-Font -Size 11
    $keyBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $keyBox.BackColor = New-C "#0B1220"
    $keyBox.ForeColor = New-C "#64748B"
    $keyBox.Text = "Key"
    $keyPanel.Controls.Add($keyBox)

    $keyBox.Add_GotFocus({
        if ($keyBox.Text -eq "Key") {
            $keyBox.Text = ""
            $keyBox.ForeColor = [System.Drawing.Color]::White
            $keyBox.UseSystemPasswordChar = $true
        }
    })

    $keyBox.Add_LostFocus({
        if ([string]::IsNullOrWhiteSpace($keyBox.Text)) {
            $keyBox.UseSystemPasswordChar = $false
            $keyBox.Text = "Key"
            $keyBox.ForeColor = New-C "#64748B"
        }
    })

    $status = Label "" 10 306 358 18 8 "#F87171"
    $status.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($status)

    $loginPanel.Controls.Add((Label "Forgot key?" 220 333 78 18 9 "#FFFFFF" $true))
    $support = Label "Support" 298 333 62 18 9 "#60A5FA" $true
    $support.Cursor = [System.Windows.Forms.Cursors]::Hand
    $support.Add_Click({
        Start-Process "https://github.com/Wxyuz/GodprojexthLauncher"
    })

    $loginPanel.Controls.Add($support)

    $signin = Button "Sign In" 10 372 358 44 "#5FA0FF" "#07111F" 16
    $loginPanel.Controls.Add($signin)

    $dot = Label "." 184 454 14 14 6 "#334155"
    $footer = Label "2025 Never. All rights reserved." 0 472 378 16 7 "#64748B"
    $footer.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($dot)
    $loginPanel.Controls.Add($footer)

    $modeTitle = Label "Select Mode" 0 44 378 28 16 "#FFFFFF" $true
    $modeTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $modeSub = Label "Choose your preferred profile." 0 72 378 18 9 "#94A3B8"
    $modeSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $modePanel.Controls.Add($modeTitle)
    $modePanel.Controls.Add($modeSub)

    $script:selectedMode = "NORMAL"
    $modeSelected = Label "Selected: NORMAL" 0 242 378 20 10 "#60A5FA" $true
    $modeSelected.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $modeLeft = Button "BOTTLE" 18 132 96 76 "#0B1220" "#CBD5E1" 20
    $modeCenter = Button "NORMAL" 141 120 96 100 "#1E293B" "#FFFFFF" 20
    $modeRight = Button "HYPER" 264 132 96 76 "#0B1220" "#64748B" 20

    $modePanel.Controls.Add($modeLeft)
    $modePanel.Controls.Add($modeCenter)
    $modePanel.Controls.Add($modeRight)
    $modePanel.Controls.Add($modeSelected)

    function SetMode {
        param([string]$m)

        $script:selectedMode = $m
        $modeSelected.Text = "Selected: $m"

        $modeLeft.BackColor = New-C "#0B1220"
        $modeCenter.BackColor = New-C "#0B1220"
        $modeRight.BackColor = New-C "#0B1220"

        $modeLeft.ForeColor = New-C "#CBD5E1"
        $modeCenter.ForeColor = New-C "#CBD5E1"
        $modeRight.ForeColor = New-C "#64748B"

        if ($m -eq "BOTTLE") {
            $modeLeft.BackColor = New-C "#1E293B"
            $modeLeft.ForeColor = [System.Drawing.Color]::White
        }

        if ($m -eq "NORMAL") {
            $modeCenter.BackColor = New-C "#1E293B"
            $modeCenter.ForeColor = [System.Drawing.Color]::White
        }

        if ($m -eq "HYPER") {
            $modeRight.BackColor = New-C "#1E293B"
            $modeRight.ForeColor = [System.Drawing.Color]::White
        }
    }

    $modeLeft.Add_Click({ SetMode "BOTTLE" })
    $modeCenter.Add_Click({ SetMode "NORMAL" })
    $modeRight.Add_Click({ SetMode "HYPER" })

    $load = Button "Load" 38 302 302 44 "#5FA0FF" "#07111F" 16
    $clean = Button "Clean" 38 358 302 44 "#111827" "#CBD5E1" 16
    $website = Button "WEBSITE" 38 414 302 44 "#5FA0FF" "#07111F" 16

    $modePanel.Controls.Add($load)
    $modePanel.Controls.Add($clean)
    $modePanel.Controls.Add($website)

    $activity = Panel 10 268 358 218 "#090F19" 18
    $activity.Visible = $false
    $modePanel.Controls.Add($activity)
    $activity.Controls.Add((Label "Activity" 14 12 120 18 10 "#FFFFFF" $true))

    $activityBox = New-Object System.Windows.Forms.TextBox
    $activityBox.Location = New-Object System.Drawing.Point((U 14), (U 40))
    $activityBox.Size = New-Object System.Drawing.Size((U 330), (U 134))
    $activityBox.Multiline = $true
    $activityBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $activityBox.ReadOnly = $true
    $activityBox.BackColor = New-C "#020617"
    $activityBox.ForeColor = New-C "#86EFAC"
    $activityBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $activityBox.Font = New-Object System.Drawing.Font("Consolas", (9 * $script:Scale))
    $activity.Controls.Add($activityBox)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point((U 14), (U 186))
    $progress.Size = New-Object System.Drawing.Size((U 330), (U 10))
    $progress.Minimum = 0
    $progress.Maximum = 100
    $progress.Value = 0
    $activity.Controls.Add($progress)

    $script:lines = @()
    $script:index = 0

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 420

    $timer.Add_Tick({
        if ($script:index -lt $script:lines.Count) {
            $activityBox.AppendText($script:lines[$script:index] + [Environment]::NewLine)
            $script:index++
            $progress.Value = [Math]::Min(100, [int](($script:index / $script:lines.Count) * 100))
        }
        else {
            $timer.Stop()
        }
    })

    function StartActivity {
        param([string[]]$l)

        $activity.Visible = $true
        $activity.BringToFront()
        $activityBox.Clear()
        $progress.Value = 0
        $script:lines = $l
        $script:index = 0
        $timer.Start()
    }

    $signin.Add_Click({
        $entered = $keyBox.Text.Trim()

        if ($entered -eq "" -or $entered -eq "Key") {
            $status.Text = "Please enter your key to continue."
            return
        }

        $valid = @("freedxm", "NEVER-2026", "WXYU-KEY", "GODPROJEXTH")

        if ($valid -contains $entered) {
            $status.Text = ""
            $modePanel.Visible = $true
            $modePanel.BringToFront()
            $loginPanel.Visible = $false
        }
        else {
            $status.Text = "Invalid key."
        }
    })

    $keyBox.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $signin.PerformClick()
        }
    })

    $load.Add_Click({
        StartActivity @(
            "[SYSTEM] Starting launcher...",
            "[MODE] Selected mode: $script:selectedMode",
            "[CHECK] Checking local config...",
            "[CHECK] Verifying files...",
            "[LOAD] Preparing profile...",
            "[LOAD] Applying UI profile...",
            "[DONE] Successfully loaded."
        )
    })

    $clean.Add_Click({
        StartActivity @(
            "[CLEAN] Starting cleanup...",
            "[CLEAN] Clearing temporary cache...",
            "[CLEAN] Removing old logs...",
            "[DONE] Cleanup completed."
        )
    })

    $website.Add_Click({
        Start-Process "https://github.com/Wxyuz/GodprojexthLauncher"
    })

    $theme.Add_Click({
        if ($theme.Text -eq "moon") {
            $theme.Text = "dark"
            $theme.BackColor = New-C "#93C5FD"
        }
        else {
            $theme.Text = "moon"
            $theme.BackColor = New-C "#5FA0FF"
        }
    })

    $form.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $form.Close()
        }
    })

    $frontTimer = New-Object System.Windows.Forms.Timer
    $frontTimer.Interval = 150
    $script:frontTick = 0

    $frontTimer.Add_Tick({
        $script:frontTick++

        if ($script:frontTick -le 10) {
            Bring-LoginFront $form
        }
        else {
            $frontTimer.Stop()
            $form.TopMost = $false
        }
    })

    $form.Add_Shown({
        $loginPanel.BringToFront()
        Minimize-ConsoleWindow
        Bring-LoginFront $form
        $frontTimer.Start()
        $keyBox.Focus()
    })

    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }

    [System.Windows.Forms.Application]::Run($form)
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

    $progress = Animate-ToPercent -From $progress -To 100 -Status "Completed. Showing credit..." -FrameRef ([ref]$frame)

    Show-GoldGodCredit -FrameRef ([ref]$frame)

    Show-LoginGui
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
