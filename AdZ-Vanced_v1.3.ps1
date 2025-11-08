#Requires -RunAsAdministrator
# AdZ-Vanced v1.3 - DNS Configuration Tool
# UI Premium, Backup/Restore, Logs

Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 API pour arrondis
if (-not ("Win32.NativeMethods" -as [type])) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    namespace Win32 {
        public static class NativeMethods {
            [DllImport("gdi32.dll", SetLastError=true)]
            public static extern IntPtr CreateRoundRectRgn(
                int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
        }
    }
"@
}

# Vérif admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $arguments = "-NoProfile -File `"$($MyInvocation.MyCommand.Definition)`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments -Wait
    exit
}

$APPDATA = Join-Path $env:APPDATA 'AdZ-Vanced'
$BackupFile = Join-Path $APPDATA 'backup_dns.json'
$LogFile = Join-Path $APPDATA 'adzvanced.log'
if (!(Test-Path $APPDATA)) { New-Item -Type Directory $APPDATA | Out-Null }

$script:Config = @{
    AppName = "AdZ-Vanced"
    Version = "1.3"
    DNSIPv4Primary = "45.90.28.219"
    DNSIPv4Secondary = "45.90.30.219"
    DNSIPv6Primary = "2a07:a8c0::a8:3732"
    DNSIPv6Secondary = "2a07:a8c1::a8:3732"
    LogoUrl = "https://files.catbox.moe/j3evd5.jpg"
    DonationPayPal = "https://www.paypal.com/ncp/payment/MGLWSKGF79JN8"
    DonationTipeee = "https://fr.tipeee.com/kontacktzbot"
    TelegramUrl = "https://t.me/adzvanced"
    BackupFile = $BackupFile
    LogFile = $LogFile
    AppDataDir = $APPDATA
}

$script:Colors = @{
    Purple      = [System.Drawing.Color]::FromArgb(147, 51, 234)
    PurpleLight = [System.Drawing.Color]::FromArgb(196, 181, 253)
    Black       = [System.Drawing.Color]::FromArgb(20, 20, 25)
    GrayDark    = [System.Drawing.Color]::FromArgb(38, 38, 42)
    Gray        = [System.Drawing.Color]::FromArgb(95, 98, 114)
    GrayLight   = [System.Drawing.Color]::FromArgb(229, 231, 235)
    Green       = [System.Drawing.Color]::FromArgb(34, 197, 94)
    Red         = [System.Drawing.Color]::FromArgb(255, 85, 95)
    White       = [System.Drawing.Color]::White
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $script:Config.LogFile -Value $logEntry
    if ($Debug) { Write-Host $logEntry }
}

function Update-StatusText {
    param([string]$Message, [string]$Color = "Green")
    $colorObj = switch ($Color.ToLower()) {
        "green"   { $script:Colors.Green }
        "yellow"  { [System.Drawing.Color]::Yellow }
        "red"     { $script:Colors.Red }
        "cyan"    { [System.Drawing.Color]::Cyan }
        default   { $script:Colors.Green }
    }
    if ($null -ne $script:txtStatus) {
        $script:txtStatus.SelectionStart = $script:txtStatus.TextLength
        $script:txtStatus.SelectionColor = $colorObj
        $script:txtStatus.AppendText("$Message`r`n")
        $script:txtStatus.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
    Write-Log $Message $Color
}

function Show-Progress {
    param([string]$Message, [int]$Duration = 2)
    Update-StatusText $Message "Yellow"
    if ($null -ne $script:progressBar) {
        $script:progressBar.Value = 0
        $script:progressBar.Visible = $true
        for ($i = 0; $i -le 100; $i += 10) {
            $script:progressBar.Value = $i
            Start-Sleep -Milliseconds ($Duration * 10)
            [System.Windows.Forms.Application]::DoEvents()
        }
        $script:progressBar.Visible = $false
    }
}

function Save-DNSBackup {
    try {
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $dnsConfig = @{}
        foreach ($adapter in $adapters) {
            $ipv4 = $adapter.DNSServerSearchOrder
            $ipv6 = $null
            if ($adapter.PSObject.Properties.Name -contains 'DNSServerSearchOrder6') {
                $ipv6 = $adapter.DNSServerSearchOrder6
            }
            $dnsConfig[$adapter.Description] = @{
                IPv4 = $ipv4
                IPv6 = $ipv6
            }
        }
        $dnsConfig | ConvertTo-Json | Set-Content -Path $script:Config.BackupFile
        Write-Log "Sauvegarde DNS effectuée"
        return $true
    } catch {
        Update-StatusText "Erreur sauvegarde : $($_.Exception.Message)" "Red"
        Write-Log "Erreur sauvegarde : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-DNSBackup {
    try {
        if (!(Test-Path $script:Config.BackupFile)) {
            Update-StatusText "Aucune sauvegarde trouvée, retour DHCP." "Red"
            Restore-DefaultDNS
            return
        }
        $backupData = Get-Content -Raw $script:Config.BackupFile | ConvertFrom-Json
        $successCount = 0
        foreach ($adapter in Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }) {
            $desc = $adapter.Description
            if ($backupData.PSObject.Properties.Name -contains $desc) {
                $info = $backupData.$desc
                if ($info.IPv4) {
                    netsh interface ipv4 set dnsservers name="$desc" static $info.IPv4[0] primary | Out-Null
                    for ($i = 1; $i -lt $info.IPv4.Count; $i++) {
                        netsh interface ipv4 add dnsservers name="$desc" $info.IPv4[$i] index=($i+1) | Out-Null
                    }
                } else { netsh interface ipv4 set dnsservers name="$desc" dhcp | Out-Null }
                if ($info.IPv6) {
                    netsh interface ipv6 set dnsservers name="$desc" static $info.IPv6[0] primary | Out-Null
                    for ($i = 1; $i -lt $info.IPv6.Count; $i++) {
                        netsh interface ipv6 add dnsservers name="$desc" $info.IPv6[$i] index=($i+1) | Out-Null
                    }
                } else { netsh interface ipv6 set dnsservers name="$desc" dhcp | Out-Null }
                $successCount++
            }
        }
        ipconfig /flushdns | Out-Null
        if ($successCount -gt 0) {
            Update-StatusText "DNS restaurés depuis la sauvegarde !" "Green"
        } else {
            Update-StatusText "Aucun adaptateur trouvé, DHCP fallback..." "Red"
            Restore-DefaultDNS
        }
    } catch {
        Update-StatusText "Erreur restauration : $($_.Exception.Message)" "Red"
        Write-Log "Erreur restauration : $($_.Exception.Message)" "ERROR"
        Restore-DefaultDNS
    }
}

function Restore-DefaultDNS {
    try {
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($adapter in $adapters) {
            $name = $adapter.Description
            netsh interface ipv4 set dnsservers name="$name" dhcp | Out-Null
            netsh interface ipv6 set dnsservers name="$name" dhcp | Out-Null
        }
        ipconfig /flushdns | Out-Null
        Update-StatusText "DNS réinitialisé (DHCP)" "Green"
    } catch {
        Update-StatusText "Erreur DHCP : $($_.Exception.Message)" "Red"
        Write-Log "Erreur DHCP : $($_.Exception.Message)" "ERROR"
    }
}

function New-ModernButton {
    param(
        [string]$Text,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor,
        [System.Drawing.Color]$ForeColor = $script:Colors.White,
        [int]$FontSize = 11
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = $Size
    $button.Location = $Location
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font = New-Object System.Drawing.Font("Segoe UI", $FontSize, [System.Drawing.FontStyle]::Bold)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Tag = $BackColor
    try {
        $button.Region = [System.Drawing.Region]::FromHrgn([Win32.NativeMethods]::CreateRoundRectRgn(0, 0, $button.Width, $button.Height, 15, 15))
    } catch {}
    $button.Add_MouseEnter({
        $oldCol = $this.Tag
        $this.BackColor = [System.Drawing.Color]::FromArgb(
            [Math]::Min(255, $oldCol.R + 24),
            [Math]::Min(255, $oldCol.G + 24),
            [Math]::Min(255, $oldCol.B + 24)
        )
    })
    $button.Add_MouseLeave({ $this.BackColor = $this.Tag })
    return $button
}

function Get-CurrentDNS {
    $dnsList = @()
    foreach ($adapter in Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }) {
        $item = @{
            Name = $adapter.Description
            IPv4 = ($adapter.DNSServerSearchOrder -join ',')
            IPv6 = ""
        }
        if ($adapter.PSObject.Properties.Name -contains 'DNSServerSearchOrder6') {
            $item.IPv6 = ($adapter.DNSServerSearchOrder6 -join ',')
        }
        $dnsList += $item
    }
    return $dnsList
}

function Show-CurrentDNS {
    $dnsArr = Get-CurrentDNS
    $txt = ($dnsArr | ForEach-Object { "$($_.Name)`nIPv4: $($_.IPv4)`nIPv6: $($_.IPv6)`n" }) -join "`n"
    [System.Windows.Forms.MessageBox]::Show($txt, "DNS actuels")
}

function Open-LogsFolder { Start-Process $script:Config.AppDataDir }

function Apply-AdZvancedDNS {
    try {
        if (Save-DNSBackup) {
            Write-Log "Application DNS AdZ-Vanced"
            if ($null -ne $script:txtStatus) { $script:txtStatus.Clear() }
            Show-Progress "Application des DNS..." 2
            $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            $successCount = 0
            foreach ($adapter in $adapters) {
                $name = $adapter.Description
                try {
                    Update-StatusText "Configuration : $name" "Cyan"
                    netsh interface ipv4 set dnsservers name="$name" static $script:Config.DNSIPv4Primary primary | Out-Null
                    netsh interface ipv4 add dnsservers name="$name" $script:Config.DNSIPv4Secondary index=2 | Out-Null
                    netsh interface ipv6 set dnsservers name="$name" static $script:Config.DNSIPv6Primary primary | Out-Null
                    netsh interface ipv6 add dnsservers name="$name" $script:Config.DNSIPv6Secondary index=2 | Out-Null
                    Update-StatusText "DNS OK" "Green"
                    $successCount++
                } catch {
                    Update-StatusText "Erreur sur $name" "Red"
                    Write-Log "Erreur $name : $($_.Exception.Message)" "ERROR"
                }
            }
            ipconfig /flushdns | Out-Null
            if ($successCount -gt 0) {
                Update-StatusText "DNS AdZ-Vanced appliqués !" "Green"
                Update-StatusText "$successCount carte(s) configurée(s)" "Cyan"
            } else {
                Update-StatusText "Aucune carte configurée" "Red"
            }
        } else {
            Update-StatusText "Erreur de sauvegarde. Annulation." "Red"
        }
    } catch {
        Update-StatusText "Erreur critique : $($_.Exception.Message)" "Red"
        Write-Log "Erreur Apply : $($_.Exception.Message)" "ERROR"
    }

}

# === INTERFACE PRINCIPALE ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($script:Config.AppName) v$($script:Config.Version)"
$form.Size = New-Object System.Drawing.Size(700, 850)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $script:Colors.Black
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

# Logo
try {
    $logoPath = Join-Path $script:Config.AppDataDir 'Logo.jpg'
    if (-not (Test-Path $logoPath)) {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($script:Config.LogoUrl, $logoPath)
    }
    $logo = New-Object System.Windows.Forms.PictureBox
    $logo.Size = New-Object System.Drawing.Size(200, 200)
    $logo.Location = New-Object System.Drawing.Point(250, 20)
    $logo.SizeMode = 'StretchImage'
    $logo.Image = [System.Drawing.Image]::FromFile($logoPath)
    $form.Controls.Add($logo)
} catch {
    Write-Log "Erreur chargement logo : $($_.Exception.Message)" "ERROR"
}

# Titre
$title = New-Object System.Windows.Forms.Label
$title.Text = "$($script:Config.AppName) v$($script:Config.Version)"
$title.Location = New-Object System.Drawing.Point(0, 240)
$title.Size = New-Object System.Drawing.Size(700, 40)
$title.TextAlign = 'MiddleCenter'
$title.ForeColor = $script:Colors.White
$title.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($title)

# Label de statut
$script:txtStatus = New-Object System.Windows.Forms.Label
$script:txtStatus.Location = New-Object System.Drawing.Point(50, 300)
$script:txtStatus.Size = New-Object System.Drawing.Size(600, 80)
$script:txtStatus.TextAlign = 'MiddleCenter'
$script:txtStatus.ForeColor = $script:Colors.Gray
$script:txtStatus.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$script:txtStatus.Text = "Prêt à configurer vos DNS"
$form.Controls.Add($script:txtStatus)

# Position Y pour les boutons
$yPos = 400

# Bouton Appliquer DNS
$btnApply = New-ModernButton -Text "Appliquer DNS AdZ-Vanced" -Location (New-Object System.Drawing.Point(200, $yPos)) -Size (New-Object System.Drawing.Size(300, 50)) -BackColor $script:Colors.Purple -ForeColor $script:Colors.White
$btnApply.Add_Click({ Apply-AdZvancedDNS })
$form.Controls.Add($btnApply)
$yPos += 70

# Bouton Restaurer
$btnRestore = New-ModernButton -Text "Restaurer sauvegarde" -Location (New-Object System.Drawing.Point(200, $yPos)) -Size (New-Object System.Drawing.Size(300, 50)) -BackColor $script:Colors.GrayDark -ForeColor $script:Colors.White
$btnRestore.Add_Click({ Restore-DNSBackup })
$form.Controls.Add($btnRestore)
$yPos += 70

# Bouton DNS par défaut
$btnDefault = New-ModernButton -Text "DNS par défaut (DHCP)" -Location (New-Object System.Drawing.Point(200, $yPos)) -Size (New-Object System.Drawing.Size(300, 50)) -BackColor $script:Colors.GrayDark -ForeColor $script:Colors.White
$btnDefault.Add_Click({ Restore-DefaultDNS })
$form.Controls.Add($btnDefault)
$yPos += 70

# Bouton Voir DNS actuels
$btnCurrent = New-ModernButton -Text "Voir DNS actuels" -Location (New-Object System.Drawing.Point(200, $yPos)) -Size (New-Object System.Drawing.Size(300, 50)) -BackColor $script:Colors.GrayDark -ForeColor $script:Colors.White
$btnCurrent.Add_Click({ Show-CurrentDNS })
$form.Controls.Add($btnCurrent)
$yPos += 70

# Bouton Ouvrir logs
$btnLogs = New-ModernButton -Text "Ouvrir dossier Logs" -Location (New-Object System.Drawing.Point(200, $yPos)) -Size (New-Object System.Drawing.Size(300, 50)) -BackColor $script:Colors.GrayDark -ForeColor $script:Colors.White
$btnLogs.Add_Click({ Open-LogsFolder })
$form.Controls.Add($btnLogs)

# Liens en bas de page
$linkPayPal = New-Object System.Windows.Forms.LinkLabel
$linkPayPal.Text = "☕ Faire un don PayPal"
$linkPayPal.Location = New-Object System.Drawing.Point(50, 770)
$linkPayPal.Size = New-Object System.Drawing.Size(200, 25)
$linkPayPal.LinkColor = $script:Colors.Purple
$linkPayPal.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$linkPayPal.Add_Click({ Start-Process $script:Config.DonationPayPal })
$form.Controls.Add($linkPayPal)

$linkTipeee = New-Object System.Windows.Forms.LinkLabel
$linkTipeee.Text = "☕ Faire un don Tipeee"
$linkTipeee.Location = New-Object System.Drawing.Point(260, 770)
$linkTipeee.Size = New-Object System.Drawing.Size(200, 25)
$linkTipeee.LinkColor = $script:Colors.Purple
$linkTipeee.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$linkTipeee.Add_Click({ Start-Process $script:Config.DonationTipeee })
$form.Controls.Add($linkTipeee)

$linkTelegram = New-Object System.Windows.Forms.LinkLabel
$linkTelegram.Text = "💬 Rejoindre Telegram"
$linkTelegram.Location = New-Object System.Drawing.Point(470, 770)
$linkTelegram.Size = New-Object System.Drawing.Size(180, 25)
$linkTelegram.LinkColor = $script:Colors.Purple
$linkTelegram.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$linkTelegram.Add_Click({ Start-Process $script:Config.TelegramUrl })
$form.Controls.Add($linkTelegram)

Write-Log "Interface initialisée avec succès"
$form.ShowDialog() | Out-Null
