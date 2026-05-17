$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$AssetName = "FreedxmLauncher_INLINE_GUI_REALFIX.zip"
$Sha256 = "E583E8A19755F0B3503BC2FD22BC5F99BFE7BDCF41842DE78193A7CEE430D2C2"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class FreedxmNativeWindow
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

function Show-ConsoleWindow {
    $handle = [FreedxmNativeWindow]::GetConsoleWindow()

    if ($handle -ne [IntPtr]::Zero) {
        [FreedxmNativeWindow]::ShowWindow($handle, 5) | Out-Null
    }
}

function Hide-ConsoleWindow {
    $handle = [FreedxmNativeWindow]::GetConsoleWindow()

    if ($handle -ne [IntPtr]::Zero) {
        [FreedxmNativeWindow]::ShowWindow($handle, 0) | Out-Null
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
    Write-Host "  FREEDXM LAUNCHER" -ForegroundColor Cyan
    Write-Host "  Inline GUI real fix loader" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Status : Preparing..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [........................................]   0%" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Frame  : 0000" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  After loading, GODPROJEXTH credit will type, then Login GUI will open." -ForegroundColor DarkGray
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

    $font["G"] = @(" #### ","#     ","#  ###","#   # "," #### ")
    $font["O"] = @(" ###  ","#   # ","#   # ","#   # "," ###  ")
    $font["D"] = @("####  ","#   # ","#   # ","#   # ","####  ")
    $font["P"] = @("####  ","#   # ","####  ","#     ","#     ")
    $font["R"] = @("####  ","#   # ","####  ","#  #  ","#   # ")
    $font["J"] = @("  ### ","   #  ","   #  ","#  #  "," ##   ")
    $font["E"] = @("##### ","#     ","####  ","#     ","##### ")
    $font["X"] = @("#   # "," # #  ","  #   "," # #  ","#   # ")
    $font["T"] = @("##### ","  #   ","  #   ","  #   ","  #   ")
    $font["H"] = @("#   # ","#   # ","##### ","#   # ","#   # ")

    $word = "GODPROJEXTH"
    $lines = @("", "", "", "", "")

    foreach ($char in $word.ToCharArray()) {
        $glyph = $font[[string]$char]

        for ($i = 0; $i -lt 5; $i++) {
            $lines[$i] += $glyph[$i] + " "
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

        Safe-WriteLine -Top 11 -Text ("        Typing GODPROJEXTH credit slowly... frame {0:0000}" -f $FrameRef.Value) -Color DarkGray
        $FrameRef.Value++
        Start-Sleep -Milliseconds 32
    }

    for ($glow = 0; $glow -lt 45; $glow++) {
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

        Safe-WriteLine -Top 11 -Text ("        Opening Login GUI... frame {0:0000}" -f $FrameRef.Value) -Color DarkGray
        $FrameRef.Value++
        Start-Sleep -Milliseconds 16
    }
}

function Show-LoginGui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()

    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class FreedxmGuiNative
{
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
}

public class SmoothPanel : Panel
{
    public SmoothPanel()
    {
        this.SetStyle(
            ControlStyles.AllPaintingInWmPaint |
            ControlStyles.UserPaint |
            ControlStyles.OptimizedDoubleBuffer |
            ControlStyles.ResizeRedraw,
            true
        );
        this.UpdateStyles();
    }
}
"@

    try {
        [FreedxmGuiNative]::SetProcessDPIAware() | Out-Null
    }
    catch {
    }

    Hide-ConsoleWindow

    $script:LoginSelectedMode = "NORMAL"
    $script:LoginValidKeys = @("freedxm", "NEVER-2026", "WXYU-KEY")
    $script:LoginScale = 1.0

    function C {
        param([string]$Html)

        return [System.Drawing.ColorTranslator]::FromHtml($Html)
    }

    function U {
        param([double]$Value)

        return [int][Math]::Round($Value * $script:LoginScale)
    }

    function F {
        param(
            [double]$Size,
            [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
        )

        $scaledSize = [float]([Math]::Max(6.0, $Size * $script:LoginScale))
        return New-Object System.Drawing.Font("Segoe UI", $scaledSize, $Style)
    }

    function Round-Control {
        param(
            [System.Windows.Forms.Control]$Control,
            [int]$Radius
        )

        if ($Control.Width -le 0 -or $Control.Height -le 0) {
            return
        }

        $r = [Math]::Max(2, (U $Radius))

        $regionPointer = [FreedxmGuiNative]::CreateRoundRectRgn(
            0,
            0,
            $Control.Width + 1,
            $Control.Height + 1,
            $r,
            $r
        )

        $Control.Region = [System.Drawing.Region]::FromHrgn($regionPointer)
    }

    function Enable-DragMove {
        param(
            [System.Windows.Forms.Control]$Control,
            [System.Windows.Forms.Form]$Form
        )

        $Control.Add_MouseDown({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                [FreedxmGuiNative]::ReleaseCapture() | Out-Null
                [FreedxmGuiNative]::SendMessage($Form.Handle, 0xA1, 0x2, 0) | Out-Null
            }
        })
    }

    function New-UiLabel {
        param(
            [string]$Text,
            [int]$X,
            [int]$Y,
            [int]$Width,
            [int]$Height,
            [double]$Size = 10,
            [string]$Color = "#FFFFFF",
            [bool]$Bold = $false
        )

        $style = if ($Bold) {
            [System.Drawing.FontStyle]::Bold
        }
        else {
            [System.Drawing.FontStyle]::Regular
        }

        $label = New-Object System.Windows.Forms.Label
        $label.Text = $Text
        $label.Location = New-Object System.Drawing.Point((U $X), (U $Y))
        $label.Size = New-Object System.Drawing.Size((U $Width), (U $Height))
        $label.Font = F -Size $Size -Style $style
        $label.ForeColor = C $Color
        $label.BackColor = [System.Drawing.Color]::Transparent
        $label.AutoEllipsis = $true

        return $label
    }

    function New-UiButton {
        param(
            [string]$Text,
            [int]$X,
            [int]$Y,
            [int]$Width,
            [int]$Height,
            [string]$Back = "#5FA0FF",
            [string]$Fore = "#07111F",
            [int]$Radius = 16
        )

        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point((U $X), (U $Y))
        $button.Size = New-Object System.Drawing.Size((U $Width), (U $Height))
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderSize = 0
        $button.BackColor = C $Back
        $button.ForeColor = C $Fore
        $button.Font = F -Size 10 -Style ([System.Drawing.FontStyle]::Bold)
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $button.TabStop = $true
        $button.UseVisualStyleBackColor = $false

        $button.Add_HandleCreated({
            Round-Control -Control $button -Radius $Radius
        })

        $button.Add_SizeChanged({
            Round-Control -Control $button -Radius $Radius
        })

        $button.Add_MouseEnter({
            $button.FlatAppearance.BorderSize = 1
            $button.FlatAppearance.BorderColor = C "#93C5FD"
        })

        $button.Add_MouseLeave({
            $button.FlatAppearance.BorderSize = 0
        })

        return $button
    }

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $baseWidth = 420
    $baseHeight = 625
    $scaleWidth = ($screen.Width * 0.92) / $baseWidth
    $scaleHeight = ($screen.Height * 0.92) / $baseHeight
    $script:LoginScale = [Math]::Min(1.0, [Math]::Min($scaleWidth, $scaleHeight))

    if ($script:LoginScale -lt 0.78) {
        $script:LoginScale = 0.78
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Freedxm Launcher"
    $form.Size = New-Object System.Drawing.Size((U $baseWidth), (U $baseHeight))
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.BackColor = C "#050910"
    $form.ShowInTaskbar = $true
    $form.TopMost = $true
    $form.Opacity = 0
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.KeyPreview = $true

    $form.Add_HandleCreated({
        Round-Control -Control $form -Radius 38
    })

    $form.Add_Resize({
        Round-Control -Control $form -Radius 38
    })

    $root = New-Object SmoothPanel
    $root.Dock = [System.Windows.Forms.DockStyle]::Fill
    $root.BackColor = C "#050910"
    $form.Controls.Add($root)

    $root.Add_HandleCreated({
        Round-Control -Control $root -Radius 38
    })

    $root.Add_SizeChanged({
        Round-Control -Control $root -Radius 38
    })

    $root.Add_Paint({
        param($sender, $event)

        $graphics = $event.Graphics
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width, $sender.Height)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            (C "#050910"),
            (C "#07111F"),
            90
        )

        $graphics.FillRectangle($brush, $rect)
        $brush.Dispose()

        $borderPen = New-Object System.Drawing.Pen((C "#111827"), 1)
        $graphics.DrawRectangle($borderPen, 0, 0, $sender.Width - 1, $sender.Height - 1)
        $borderPen.Dispose()
    })

    $header = New-Object SmoothPanel
    $header.Location = New-Object System.Drawing.Point((U 14), (U 14))
    $header.Size = New-Object System.Drawing.Size((U 392), (U 54))
    $header.BackColor = C "#0B1220"
    $root.Controls.Add($header)

    $header.Add_HandleCreated({
        Round-Control -Control $header -Radius 20
    })

    $header.Add_SizeChanged({
        Round-Control -Control $header -Radius 20
    })

    Enable-DragMove -Control $header -Form $form

    $logo = New-Object SmoothPanel
    $logo.Location = New-Object System.Drawing.Point((U 14), (U 14))
    $logo.Size = New-Object System.Drawing.Size((U 26), (U 26))
    $logo.BackColor = C "#5FA0FF"
    $header.Controls.Add($logo)

    $logo.Add_HandleCreated({
        Round-Control -Control $logo -Radius 10
    })

    $logoText = New-UiLabel -Text "N" -X 7 -Y 3 -Width 16 -Height 18 -Size 10 -Color "#FFFFFF" -Bold $true
    $logo.Controls.Add($logoText)

    $brand = New-UiLabel -Text "NEVER" -X 54 -Y 15 -Width 140 -Height 25 -Size 11 -Color "#FFFFFF" -Bold $true
    $header.Controls.Add($brand)
    Enable-DragMove -Control $brand -Form $form

    $minButton = New-UiButton -Text "-" -X 283 -Y 11 -Width 30 -Height 30 -Back "#111827" -Fore "#94A3B8" -Radius 10
    $closeButton = New-UiButton -Text "x" -X 317 -Y 11 -Width 30 -Height 30 -Back "#111827" -Fore "#94A3B8" -Radius 10
    $themeButton = New-UiButton -Text "moon" -X 354 -Y 7 -Width 32 -Height 40 -Back "#5FA0FF" -Fore "#07111F" -Radius 12
    $themeButton.Font = F -Size 7.5 -Style ([System.Drawing.FontStyle]::Bold)

    $header.Controls.Add($minButton)
    $header.Controls.Add($closeButton)
    $header.Controls.Add($themeButton)

    $minButton.Add_Click({
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    })

    $closeButton.Add_Click({
        $form.Close()
    })

    $body = New-Object SmoothPanel
    $body.Location = New-Object System.Drawing.Point((U 14), (U 76))
    $body.Size = New-Object System.Drawing.Size((U 392), (U 535))
    $body.BackColor = [System.Drawing.Color]::Transparent
    $root.Controls.Add($body)

    $loginPanel = New-Object SmoothPanel
    $loginPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $loginPanel.BackColor = [System.Drawing.Color]::Transparent
    $body.Controls.Add($loginPanel)

    $modePanel = New-Object SmoothPanel
    $modePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $modePanel.BackColor = [System.Drawing.Color]::Transparent
    $modePanel.Visible = $false
    $body.Controls.Add($modePanel)

    $hero = New-Object SmoothPanel
    $hero.Location = New-Object System.Drawing.Point((U 18), (U 12))
    $hero.Size = New-Object System.Drawing.Size((U 356), (U 178))
    $hero.BackColor = C "#08111F"
    $loginPanel.Controls.Add($hero)

    $hero.Add_HandleCreated({
        Round-Control -Control $hero -Radius 20
    })

    $hero.Add_SizeChanged({
        Round-Control -Control $hero -Radius 20
    })

    $hero.Add_Paint({
        param($sender, $event)

        $graphics = $event.Graphics
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width, $sender.Height)

        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            (C "#08111F"),
            (C "#0B2136"),
            35
        )

        $graphics.FillRectangle($brush, $rect)
        $brush.Dispose()

        $glowBrush = New-Object System.Drawing.SolidBrush((C "#123D59"))
        $graphics.FillEllipse($glowBrush, (U 144), (U 92), (U 96), (U 42))
        $glowBrush.Dispose()

        $linePen = New-Object System.Drawing.Pen((C "#5B6473"), 2)
        $graphics.DrawLine($linePen, (U 252), (U 25), (U 312), (U 140))
        $linePen.Dispose()

        $thinPen = New-Object System.Drawing.Pen((C "#1E293B"), 1)
        $graphics.DrawRectangle($thinPen, 0, 0, $sender.Width - 1, $sender.Height - 1)
        $thinPen.Dispose()
    })

    $heroTabs = New-UiLabel -Text "-----   -----   ------" -X 128 -Y 14 -Width 160 -Height 18 -Size 7.5 -Color "#CBD5E1"
    $loginPanel.Controls.Add($heroTabs)
    $heroTabs.BringToFront()

    $heroBrand = New-UiLabel -Text "NEVERSTORE" -X 22 -Y 45 -Width 180 -Height 22 -Size 14 -Color "#506277" -Bold $true
    $heroSmall = New-UiLabel -Text "launcher interface" -X 24 -Y 63 -Width 132 -Height 12 -Size 6.5 -Color "#3C4A5C"
    $heroMode = New-UiLabel -Text "Mode" -X 22 -Y 80 -Width 125 -Height 34 -Size 24 -Color "#4F6074"
    $heroHyper = New-UiLabel -Text "Hyper" -X 22 -Y 111 -Width 160 -Height 38 -Size 30 -Color "#64748B"
    $heroBottle = New-UiLabel -Text "BOTTLE" -X 22 -Y 146 -Width 100 -Height 18 -Size 9 -Color "#FFFFFF" -Bold $true
    $heroDescription = New-UiLabel -Text "Clean interface profile with smooth loading,`nlocal setup and polished dashboard flow." -X 22 -Y 160 -Width 314 -Height 28 -Size 7 -Color "#94A3B8"

    $hero.Controls.Add($heroBrand)
    $hero.Controls.Add($heroSmall)
    $hero.Controls.Add($heroMode)
    $hero.Controls.Add($heroHyper)
    $hero.Controls.Add($heroBottle)
    $hero.Controls.Add($heroDescription)

    $welcome = New-UiLabel -Text "Welcome Back!" -X 0 -Y 210 -Width 392 -Height 28 -Size 16 -Color "#FFFFFF" -Bold $true
    $welcome.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($welcome)

    $welcomeSub = New-UiLabel -Text "Please enter your key to continue." -X 0 -Y 237 -Width 392 -Height 18 -Size 9 -Color "#94A3B8"
    $welcomeSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($welcomeSub)

    $keyPanel = New-Object SmoothPanel
    $keyPanel.Location = New-Object System.Drawing.Point((U 18), (U 280))
    $keyPanel.Size = New-Object System.Drawing.Size((U 356), (U 48))
    $keyPanel.BackColor = C "#0B1220"
    $loginPanel.Controls.Add($keyPanel)

    $keyPanel.Add_HandleCreated({
        Round-Control -Control $keyPanel -Radius 18
    })

    $keyIcon = New-UiLabel -Text "key" -X 16 -Y 13 -Width 30 -Height 22 -Size 8 -Color "#64748B"
    $keyPanel.Controls.Add($keyIcon)

    $keyBox = New-Object System.Windows.Forms.TextBox
    $keyBox.Location = New-Object System.Drawing.Point((U 52), (U 14))
    $keyBox.Size = New-Object System.Drawing.Size((U 286), (U 22))
    $keyBox.Font = F -Size 11
    $keyBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $keyBox.BackColor = C "#0B1220"
    $keyBox.ForeColor = C "#64748B"
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
            $keyBox.ForeColor = C "#64748B"
        }
    })

    $status = New-UiLabel -Text "" -X 18 -Y 332 -Width 356 -Height 18 -Size 8 -Color "#F87171"
    $status.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($status)

    $forgot = New-UiLabel -Text "Forgot key?" -X 228 -Y 358 -Width 75 -Height 18 -Size 9 -Color "#FFFFFF" -Bold $true
    $support = New-UiLabel -Text "Support" -X 304 -Y 358 -Width 56 -Height 18 -Size 9 -Color "#60A5FA" -Bold $true
    $support.Cursor = [System.Windows.Forms.Cursors]::Hand
    $support.Add_Click({
        Start-Process "https://github.com/Wxyuz/GodprojexthLauncher"
    })

    $loginPanel.Controls.Add($forgot)
    $loginPanel.Controls.Add($support)

    $signIn = New-UiButton -Text "Sign In" -X 18 -Y 392 -Width 356 -Height 44 -Back "#5FA0FF" -Fore "#07111F" -Radius 18
    $loginPanel.Controls.Add($signIn)

    $footerDot = New-UiLabel -Text "o" -X 194 -Y 474 -Width 12 -Height 12 -Size 6 -Color "#334155"
    $footer = New-UiLabel -Text "2025 Never. All rights reserved." -X 0 -Y 492 -Width 392 -Height 16 -Size 7 -Color "#64748B"
    $footer.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loginPanel.Controls.Add($footerDot)
    $loginPanel.Controls.Add($footer)

    $modeTitle = New-UiLabel -Text "Select Mode" -X 0 -Y 48 -Width 392 -Height 28 -Size 16 -Color "#FFFFFF" -Bold $true
    $modeTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $modeSub = New-UiLabel -Text "Choose your preferred profile." -X 0 -Y 76 -Width 392 -Height 18 -Size 9 -Color "#94A3B8"
    $modeSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $modeLeft = New-UiButton -Text "BOTTLE" -X 30 -Y 138 -Width 92 -Height 72 -Back "#0B1220" -Fore "#CBD5E1" -Radius 20
    $modeCenter = New-UiButton -Text "NORMAL" -X 150 -Y 124 -Width 96 -Height 100 -Back "#1E293B" -Fore "#FFFFFF" -Radius 20
    $modeRight = New-UiButton -Text "HYPER" -X 270 -Y 138 -Width 92 -Height 72 -Back "#0B1220" -Fore "#64748B" -Radius 20

    $modeSelected = New-UiLabel -Text "Selected: NORMAL" -X 0 -Y 246 -Width 392 -Height 20 -Size 10 -Color "#60A5FA" -Bold $true
    $modeSelected.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $loadButton = New-UiButton -Text "Load" -X 46 -Y 310 -Width 300 -Height 44 -Back "#5FA0FF" -Fore "#07111F" -Radius 18
    $cleanButton = New-UiButton -Text "Clean" -X 46 -Y 366 -Width 300 -Height 44 -Back "#111827" -Fore "#CBD5E1" -Radius 18
    $websiteButton = New-UiButton -Text "WEBSITE" -X 46 -Y 422 -Width 300 -Height 44 -Back "#5FA0FF" -Fore "#07111F" -Radius 18

    $modePanel.Controls.Add($modeTitle)
    $modePanel.Controls.Add($modeSub)
    $modePanel.Controls.Add($modeLeft)
    $modePanel.Controls.Add($modeCenter)
    $modePanel.Controls.Add($modeRight)
    $modePanel.Controls.Add($modeSelected)
    $modePanel.Controls.Add($loadButton)
    $modePanel.Controls.Add($cleanButton)
    $modePanel.Controls.Add($websiteButton)

    $activity = New-Object SmoothPanel
    $activity.Location = New-Object System.Drawing.Point((U 18), (U 276))
    $activity.Size = New-Object System.Drawing.Size((U 356), (U 218))
    $activity.BackColor = C "#090F19"
    $activity.Visible = $false
    $modePanel.Controls.Add($activity)

    $activity.Add_HandleCreated({
        Round-Control -Control $activity -Radius 20
    })

    $activityTitle = New-UiLabel -Text "Activity" -X 14 -Y 12 -Width 120 -Height 18 -Size 10 -Color "#FFFFFF" -Bold $true
    $activity.Controls.Add($activityTitle)

    $activityBox = New-Object System.Windows.Forms.TextBox
    $activityBox.Location = New-Object System.Drawing.Point((U 14), (U 40))
    $activityBox.Size = New-Object System.Drawing.Size((U 328), (U 134))
    $activityBox.Multiline = $true
    $activityBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $activityBox.ReadOnly = $true
    $activityBox.BackColor = C "#020617"
    $activityBox.ForeColor = C "#86EFAC"
    $activityBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $activityBox.Font = New-Object System.Drawing.Font("Consolas", (9 * $script:LoginScale))
    $activity.Controls.Add($activityBox)

    $activityProgress = New-Object System.Windows.Forms.ProgressBar
    $activityProgress.Location = New-Object System.Drawing.Point((U 14), (U 186))
    $activityProgress.Size = New-Object System.Drawing.Size((U 328), (U 10))
    $activityProgress.Minimum = 0
    $activityProgress.Maximum = 100
    $activityProgress.Value = 0
    $activity.Controls.Add($activityProgress)

    $script:ActivityLines = @()
    $script:ActivityIndex = 0

    $activityTimer = New-Object System.Windows.Forms.Timer
    $activityTimer.Interval = 420

    $activityTimer.Add_Tick({
        if ($script:ActivityIndex -lt $script:ActivityLines.Count) {
            $activityBox.AppendText($script:ActivityLines[$script:ActivityIndex] + [Environment]::NewLine)
            $script:ActivityIndex++
            $activityProgress.Value = [Math]::Min(100, [int](($script:ActivityIndex / $script:ActivityLines.Count) * 100))
        }
        else {
            $activityTimer.Stop()
        }
    })

    function Set-ModeUi {
        param([string]$Mode)

        $script:LoginSelectedMode = $Mode
        $modeSelected.Text = "Selected: $Mode"

        $modeLeft.BackColor = C "#0B1220"
        $modeCenter.BackColor = C "#0B1220"
        $modeRight.BackColor = C "#0B1220"

        $modeLeft.ForeColor = C "#CBD5E1"
        $modeCenter.ForeColor = C "#CBD5E1"
        $modeRight.ForeColor = C "#64748B"

        if ($Mode -eq "BOTTLE") {
            $modeLeft.BackColor = C "#1E293B"
            $modeLeft.ForeColor = [System.Drawing.Color]::White
        }

        if ($Mode -eq "NORMAL") {
            $modeCenter.BackColor = C "#1E293B"
            $modeCenter.ForeColor = [System.Drawing.Color]::White
        }

        if ($Mode -eq "HYPER") {
            $modeRight.BackColor = C "#1E293B"
            $modeRight.ForeColor = [System.Drawing.Color]::White
        }
    }

    function Start-Activity {
        param([string[]]$Lines)

        $activity.Visible = $true
        $activity.BringToFront()
        $activityBox.Clear()
        $activityProgress.Value = 0
        $script:ActivityLines = $Lines
        $script:ActivityIndex = 0
        $activityTimer.Start()
    }

    $modeLeft.Add_Click({ Set-ModeUi -Mode "BOTTLE" })
    $modeCenter.Add_Click({ Set-ModeUi -Mode "NORMAL" })
    $modeRight.Add_Click({ Set-ModeUi -Mode "HYPER" })

    $signIn.Add_Click({
        $enteredKey = $keyBox.Text

        if ($enteredKey -eq "Key" -or [string]::IsNullOrWhiteSpace($enteredKey)) {
            $status.Text = "Please enter your key to continue."
            return
        }

        if ($script:LoginValidKeys -contains $enteredKey.Trim()) {
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
            $signIn.PerformClick()
        }
    })

    $loadButton.Add_Click({
        Start-Activity -Lines @(
            "[SYSTEM] Starting launcher...",
            "[MODE] Selected mode: $script:LoginSelectedMode",
            "[CHECK] Checking local config...",
            "[CHECK] Verifying files...",
            "[LOAD] Preparing profile...",
            "[LOAD] Applying UI profile...",
            "[DONE] Successfully loaded."
        )
    })

    $cleanButton.Add_Click({
        Start-Activity -Lines @(
            "[CLEAN] Starting cleanup...",
            "[CLEAN] Clearing temporary cache...",
            "[CLEAN] Removing old logs...",
            "[CLEAN] Finalizing cleanup...",
            "[DONE] Cleanup completed."
        )
    })

    $websiteButton.Add_Click({
        Start-Process "https://github.com/Wxyuz/GodprojexthLauncher"
    })

    $themeButton.Add_Click({
        if ($themeButton.Text -eq "moon") {
            $themeButton.Text = "dark"
            $themeButton.BackColor = C "#93C5FD"
        }
        else {
            $themeButton.Text = "moon"
            $themeButton.BackColor = C "#5FA0FF"
        }
    })

    $form.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $form.Close()
        }
    })

    $fadeTimer = New-Object System.Windows.Forms.Timer
    $fadeTimer.Interval = 16

    $fadeTimer.Add_Tick({
        if ($form.Opacity -lt 1) {
            $form.Opacity = [Math]::Min(1, $form.Opacity + 0.07)
        }
        else {
            $fadeTimer.Stop()
            $form.TopMost = $false
            $form.Activate()
            $keyBox.Focus()
        }
    })

    $form.Add_Shown({
        $loginPanel.BringToFront()
        $form.Activate()
        $form.BringToFront()
        $fadeTimer.Start()
    })

    [System.Windows.Forms.Application]::Run($form)
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

    Show-LoginGui

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
