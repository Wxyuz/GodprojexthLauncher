$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$Owner = "Wxyuz"
$Repo = "GodprojexthLauncher"
$PreferredAssetName = "FreedxmLauncher_Borderless.zip"
$Sha256 = "E5088D499DCDF695F68BD66CA774858FA8811B285097EB2E4E632F6A2BA64C62"

$InstallDir = Join-Path $env:LOCALAPPDATA "FreedxmLauncher"
$TempRoot = Join-Path $env:TEMP "FreedxmLauncherInstall"
$TempZip = Join-Path $TempRoot "FreedxmLauncher.zip"

$script:DownloadCompleted = $false
$script:DownloadFailed = $false
$script:ErrorMessage = ""
$script:CurrentStatus = "Preparing..."
$script:CurrentPercent = 0
$script:LoaderStep = 0

function Set-LoaderState($status, $percent) {
    $script:CurrentStatus = $status
    $script:CurrentPercent = [Math]::Max(0, [Math]::Min(100, [int]$percent))

    if ($script:StatusLabel -ne $null) {
        $script:StatusLabel.Text = $script:CurrentStatus
    }

    if ($script:PercentLabel -ne $null) {
        $script:PercentLabel.Text = "$($script:CurrentPercent)%"
    }

    if ($script:ProgressBar -ne $null) {
        $script:ProgressBar.Value = $script:CurrentPercent
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Show-ErrorBox($message) {
    [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Freedxm Launcher",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Start-InstallerJob {
    try {
        Set-LoaderState "Connecting to release server..." 10

        $Headers = @{
            "User-Agent" = "FreedxmLauncherInstaller"
        }

        $ReleaseApi = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers

        Set-LoaderState "Selecting package..." 20

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

        Set-LoaderState "Preparing download..." 30

        Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $TempRoot | Out-Null

        Set-LoaderState "Downloading package..." 45

        Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -Headers $Headers

        Set-LoaderState "Verifying SHA256..." 65

        $ActualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpperInvariant()
        $ExpectedHash = $Sha256.ToUpperInvariant()

        if ($ActualHash -ne $ExpectedHash) {
            throw "SHA256 mismatch.`nExpected: $ExpectedHash`nActual:   $ActualHash"
        }

        Set-LoaderState "Installing files..." 80

        Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $InstallDir | Out-Null

        Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

        Set-LoaderState "Opening launcher..." 95

        $Exe = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $Bat = Get-ChildItem -Path $InstallDir -Filter "run.bat" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        $Ps1 = Get-ChildItem -Path $InstallDir -Filter "FreedxmLauncher.ps1" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($Exe) {
            Start-Process -FilePath $Exe.FullName
        }
        elseif ($Bat) {
            Start-Process -FilePath $Bat.FullName -WorkingDirectory $Bat.DirectoryName
        }
        elseif ($Ps1) {
            Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($Ps1.FullName)`""
        }
        else {
            Start-Process explorer.exe $InstallDir
        }

        Set-LoaderState "Completed." 100

        Start-Sleep -Milliseconds 500

        $script:DownloadCompleted = $true
    }
    catch {
        $script:DownloadFailed = $true
        $script:ErrorMessage = $_.Exception.Message
    }
}

$LoaderForm = New-Object System.Windows.Forms.Form
$LoaderForm.Text = "Freedxm Launcher"
$LoaderForm.Size = New-Object System.Drawing.Size(520, 250)
$LoaderForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$LoaderForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$LoaderForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#050A14")
$LoaderForm.TopMost = $true
$LoaderForm.ShowInTaskbar = $true

$MainPanel = New-Object System.Windows.Forms.Panel
$MainPanel.Location = New-Object System.Drawing.Point(1, 1)
$MainPanel.Size = New-Object System.Drawing.Size(518, 248)
$MainPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#08111F")
$LoaderForm.Controls.Add($MainPanel)

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "FREEDXM LAUNCHER"
$TitleLabel.Location = New-Object System.Drawing.Point(32, 30)
$TitleLabel.Size = New-Object System.Drawing.Size(360, 34)
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::White
$TitleLabel.BackColor = [System.Drawing.Color]::Transparent
$MainPanel.Controls.Add($TitleLabel)

$script:StatusLabel = New-Object System.Windows.Forms.Label
$script:StatusLabel.Text = "Preparing..."
$script:StatusLabel.Location = New-Object System.Drawing.Point(34, 80)
$script:StatusLabel.Size = New-Object System.Drawing.Size(350, 24)
$script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$script:StatusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#93C5FD")
$script:StatusLabel.BackColor = [System.Drawing.Color]::Transparent
$MainPanel.Controls.Add($script:StatusLabel)

$script:PercentLabel = New-Object System.Windows.Forms.Label
$script:PercentLabel.Text = "0%"
$script:PercentLabel.Location = New-Object System.Drawing.Point(425, 80)
$script:PercentLabel.Size = New-Object System.Drawing.Size(60, 24)
$script:PercentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:PercentLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$script:PercentLabel.BackColor = [System.Drawing.Color]::Transparent
$script:PercentLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$MainPanel.Controls.Add($script:PercentLabel)

$script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$script:ProgressBar.Location = New-Object System.Drawing.Point(36, 122)
$script:ProgressBar.Size = New-Object System.Drawing.Size(448, 16)
$script:ProgressBar.Minimum = 0
$script:ProgressBar.Maximum = 100
$script:ProgressBar.Value = 0
$MainPanel.Controls.Add($script:ProgressBar)

$PulseLabel = New-Object System.Windows.Forms.Label
$PulseLabel.Text = "Loading"
$PulseLabel.Location = New-Object System.Drawing.Point(36, 158)
$PulseLabel.Size = New-Object System.Drawing.Size(448, 24)
$PulseLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
$PulseLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#64748B")
$PulseLabel.BackColor = [System.Drawing.Color]::Transparent
$MainPanel.Controls.Add($PulseLabel)

$CloseButton = New-Object System.Windows.Forms.Button
$CloseButton.Text = "X"
$CloseButton.Location = New-Object System.Drawing.Point(468, 16)
$CloseButton.Size = New-Object System.Drawing.Size(32, 28)
$CloseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$CloseButton.FlatAppearance.BorderSize = 0
$CloseButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827")
$CloseButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CBD5E1")
$CloseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$MainPanel.Controls.Add($CloseButton)

$CloseButton.Add_Click({
    $LoaderForm.Close()
})

$AnimationTimer = New-Object System.Windows.Forms.Timer
$AnimationTimer.Interval = 120

$AnimationTimer.Add_Tick({
    if ($script:LoaderStep -ge 3) {
        $script:LoaderStep = 0
    }
    else {
        $script:LoaderStep++
    }

    $dots = "." * $script:LoaderStep
    $PulseLabel.Text = "Loading$dots"

    if ($script:DownloadCompleted) {
        $AnimationTimer.Stop()
        $LoaderForm.Close()
    }

    if ($script:DownloadFailed) {
        $AnimationTimer.Stop()
        $LoaderForm.Close()
        Show-ErrorBox $script:ErrorMessage
    }
})

$LoaderForm.Add_Shown({
    $AnimationTimer.Start()
    Start-InstallerJob
})

[System.Windows.Forms.Application]::Run($LoaderForm)
