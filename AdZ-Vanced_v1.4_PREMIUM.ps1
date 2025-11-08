#Requires -RunAsAdministrator
# AdZ-Vanced v1.4 PREMIUM - DNS Configuration Tool
# Interface Ultra-Professionnelle avec Logo Dynamique
# © 2025 - Configuration DNS Avancée

Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 API pour arrondis et transparence
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

# Vérification admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $arguments = "-NoProfile -File `"$($MyInvocation.MyCommand.Definition)`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments -Wait
    exit
}

# Configuration globale
$APPDATA = Join-Path $env:APPDATA 'AdZ-Vanced'
$BackupFile = Join-Path $APPDATA 'backup_dns.json'
$LogFile = Join-Path $APPDATA 'adzvanced.log'
if (!(Test-Path $APPDATA)) { New-Item -Type Directory $APPDATA | Out-Null }

$script:Config = @{
    AppName = "AdZ-Vanced"
    Version = "1.4 PREMIUM"
    DNSIPv4Primary = "45.90.28.219"
    DNSIPv4Secondary = "45.90.30.219"
    DNSIPv6Primary = "2a07:a8c0::a8:3732"
    DNSIPv6Secondary = "2a07:a8c1::a8:3732"
    DonationPayPal = "https://www.paypal.com/ncp/payment/MGLWSKGF79JN8"
    TelegramUrl = "https://t.me/adzvanced"
    BackupFile = $BackupFile
    LogFile = $LogFile
    AppDataDir = $APPDATA
}

$script:Colors = @{
    Purple = [System.Drawing.Color]::FromArgb(147, 51, 234)
    PurpleLight = [System.Drawing.Color]::FromArgb(196, 181, 253)
    PurpleDark = [System.Drawing.Color]::FromArgb(126, 34, 206)
    Black = [System.Drawing.Color]::FromArgb(20, 25, 45)
    BlackLight = [System.Drawing.Color]::FromArgb(30, 35, 55)
    GrayDark = [System.Drawing.Color]::FromArgb(50, 55, 75)
    Gray = [System.Drawing.Color]::FromArgb(95, 98, 114)
    GrayLight = [System.Drawing.Color]::FromArgb(229, 231, 235)
    Green = [System.Drawing.Color]::FromArgb(34, 197, 94)
    Red = [System.Drawing.Color]::FromArgb(239, 68, 68)
    Yellow = [System.Drawing.Color]::FromArgb(234, 179, 8)
    Cyan = [System.Drawing.Color]::FromArgb(6, 182, 212)
    White = [System.Drawing.Color]::White
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $script:Config.LogFile -Value $logEntry
}

function Update-LogDisplay {
    param([string]$Message, [string]$Color = "Green")
    $colorObj = switch ($Color.ToLower()) {
        "green" { $script:Colors.Green }
        "yellow" { $script:Colors.Yellow }
        "red" { $script:Colors.Red }
        "cyan" { $script:Colors.Cyan }
        "white" { $script:Colors.White }
        default { $script:Colors.White }
    }
    if ($null -ne $script:txtLogs) {
        $script:txtLogs.SelectionStart = $script:txtLogs.Text.Length
        $script:txtLogs.SelectionColor = $colorObj
        $script:txtLogs.AppendText("$Message`r`n")
        $script:txtLogs.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
    Write-Log $Message $Color
}

# ====================================
# FONCTIONS DNS
# ====================================

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
        Update-LogDisplay "Erreur sauvegarde : $($_.Exception.Message)" "Red"
        Write-Log "Erreur sauvegarde : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-DNSBackup {
    try {
        if (!(Test-Path $script:Config.BackupFile)) {
            Update-LogDisplay "Aucune sauvegarde trouvée, retour DHCP." "Yellow"
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
            Update-LogDisplay "DNS restaurés depuis la sauvegarde !" "Green"
        } else {
            Update-LogDisplay "Aucun adaptateur trouvé, DHCP fallback..." "Yellow"
            Restore-DefaultDNS
        }
    } catch {
        Update-LogDisplay "Erreur restauration : $($_.Exception.Message)" "Red"
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
        Update-LogDisplay "DNS réinitialisé (DHCP)" "Green"
    } catch {
        Update-LogDisplay "Erreur DHCP : $($_.Exception.Message)" "Red"
        Write-Log "Erreur DHCP : $($_.Exception.Message)" "ERROR"
    }
}

function Apply-AdZvancedDNS {
    try {
        if (Save-DNSBackup) {
            Write-Log "Application DNS AdZ-Vanced"
            if ($null -ne $script:txtLogs) { $script:txtLogs.Clear() }
            Update-LogDisplay "Application des DNS AdZ-Vanced en cours..." "Cyan"
            $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            $successCount = 0
            foreach ($adapter in $adapters) {
                $name = $adapter.Description
                try {
                    Update-LogDisplay "Configuration : $name" "Cyan"
                    netsh interface ipv4 set dnsservers name="$name" static $script:Config.DNSIPv4Primary primary | Out-Null
                    netsh interface ipv4 add dnsservers name="$name" $script:Config.DNSIPv4Secondary index=2 | Out-Null
                    netsh interface ipv6 set dnsservers name="$name" static $script:Config.DNSIPv6Primary primary | Out-Null
                    netsh interface ipv6 add dnsservers name="$name" $script:Config.DNSIPv6Secondary index=2 | Out-Null
                    Update-LogDisplay "   ✓ DNS appliqués avec succès" "Green"
                    $successCount++
                } catch {
                    Update-LogDisplay "   ✗ Erreur sur $name" "Red"
                    Write-Log "Erreur $name : $($_.Exception.Message)" "ERROR"
                }
            }
            ipconfig /flushdns | Out-Null
            if ($successCount -gt 0) {
                Update-LogDisplay "" "White"
                Update-LogDisplay "⭐ DNS AdZ-Vanced appliqués avec succès !" "Green"
                Update-LogDisplay "$successCount carte(s) réseau configurée(s)" "Cyan"
            } else {
                Update-LogDisplay "Aucune carte configurée" "Red"
            }
        } else {
            Update-LogDisplay "Erreur de sauvegarde. Opération annulée." "Red"
        }
    } catch {
        Update-LogDisplay "Erreur critique : $($_.Exception.Message)" "Red"
        Write-Log "Erreur Apply : $($_.Exception.Message)" "ERROR"
    }
}

# ====================================
# INTERFACE PREMIUM
# ====================================

Write-Log "Initialisation de l'interface PREMIUM v1.4"

# Création du formulaire principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($script:Config.AppName) v$($script:Config.Version)"
$form.Size = New-Object System.Drawing.Size(1024, 800)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = $script:Colors.Black

# Titre principal
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = $script:Config.AppName
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 36, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $script:Colors.White
$titleLabel.AutoSize = $false
$titleLabel.Size = New-Object System.Drawing.Size(1024, 60)
$titleLabel.Location = New-Object System.Drawing.Point(0, 20)
$titleLabel.TextAlign = 'MiddleCenter'
$form.Controls.Add($titleLabel)

# Version
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v$($script:Config.Version)"
$versionLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$versionLabel.ForeColor = $script:Colors.PurpleLight
$versionLabel.AutoSize = $false
$versionLabel.Size = New-Object System.Drawing.Size(1024, 30)
$versionLabel.Location = New-Object System.Drawing.Point(0, 85)
$versionLabel.TextAlign = 'MiddleCenter'
$form.Controls.Add($versionLabel)

# LOGO - Chargement depuis logo.png (300px)
$logoBox = New-Object System.Windows.Forms.PictureBox
$logoBox.Size = New-Object System.Drawing.Size(300, 300)
$logoBox.Location = New-Object System.Drawing.Point(362, 120)
$logoBox.SizeMode = 'Zoom'
$logoBox.BackColor = [System.Drawing.Color]::Transparent

try {
    $logoPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "logo.png"
    if (Test-Path $logoPath) {
        $logoBox.Image = [System.Drawing.Image]::FromFile($logoPath)
        Write-Log "Logo chargé depuis $logoPath"
    } else {
        # Logo de remplacement si fichier non trouvé
        $logoLabel = New-Object System.Windows.Forms.Label
        $logoLabel.Text = "A"
        $logoLabel.Font = New-Object System.Drawing.Font('Segoe UI', 120, [System.Drawing.FontStyle]::Bold)
        $logoLabel.ForeColor = $script:Colors.Purple
        $logoLabel.AutoSize = $false
        $logoLabel.Size = New-Object System.Drawing.Size(300, 300)
        $logoLabel.Location = New-Object System.Drawing.Point(362, 120)
        $logoLabel.TextAlign = 'MiddleCenter'
        $form.Controls.Add($logoLabel)
        Write-Log "Logo fichier non trouvé, utilisation du logo texte"
    }
} catch {
    Write-Log "Erreur chargement logo : $($_.Exception.Message)" "ERROR"
}

$form.Controls.Add($logoBox)

# Panneau de message informatif
$messagePanel = New-Object System.Windows.Forms.Panel
$messagePanel.Size = New-Object System.Drawing.Size(900, 70)
$messagePanel.Location = New-Object System.Drawing.Point(62, 430)
$messagePanel.BorderStyle = 'FixedSingle'
$messagePanel.BackColor = $script:Colors.BlackLight
$form.Controls.Add($messagePanel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Panneau de message informatif : Prêt à optimizze votre connexion."
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(224, 242, 254)
$statusLabel.AutoSize = $false
$statusLabel.Size = New-Object System.Drawing.Size(880, 60)
$statusLabel.Location = New-Object System.Drawing.Point(10, 5)
$statusLabel.TextAlign = 'MiddleLeft'
$messagePanel.Controls.Add($statusLabel)

# Boutons principaux (INSTALLER et RESTAURER)
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "INSTALLER DNS"
$btnInstall.Size = New-Object System.Drawing.Size(400, 55)
$btnInstall.Location = New-Object System.Drawing.Point(112, 520)
$btnInstall.BackColor = $script:Colors.Purple
$btnInstall.ForeColor = $script:Colors.White
$btnInstall.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.FlatAppearance.BorderSize = 0
$btnInstall.Cursor = 'Hand'
$btnInstall.Add_MouseEnter({
    $this.BackColor = $script:Colors.PurpleDark
})
$btnInstall.Add_MouseLeave({
    $this.BackColor = $script:Colors.Purple
})
$btnInstall.Add_Click({
    $statusLabel.Text = "Application des DNS AdZ-Vanced en cours..."
    [System.Windows.Forms.Application]::DoEvents()
    Apply-AdZvancedDNS
    $statusLabel.Text = "DNS AdZ-Vanced appliqués avec succès ! Consultez les logs ci-dessous."
})
$form.Controls.Add($btnInstall)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "RESTAURER DNS"
$btnRestore.Size = New-Object System.Drawing.Size(400, 55)
$btnRestore.Location = New-Object System.Drawing.Point(512, 520)
$btnRestore.BackColor = $script:Colors.Purple
$btnRestore.ForeColor = $script:Colors.White
$btnRestore.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$btnRestore.FlatStyle = 'Flat'
$btnRestore.FlatAppearance.BorderSize = 0
$btnRestore.Cursor = 'Hand'
$btnRestore.Add_MouseEnter({
    $this.BackColor = $script:Colors.PurpleDark
})
$btnRestore.Add_MouseLeave({
    $this.BackColor = $script:Colors.Purple
})
$btnRestore.Add_Click({
    $statusLabel.Text = "Restauration de la sauvegarde DNS..."
    [System.Windows.Forms.Application]::DoEvents()
    Restore-DNSBackup
    $statusLabel.Text = "DNS restaurés depuis la sauvegarde. Consultez les logs."
})
$form.Controls.Add($btnRestore)

# Zone de Logs (RichTextBox pour couleurs)
$logsLabel = New-Object System.Windows.Forms.Label
$logsLabel.Text = "Logs :"
$logsLabel.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$logsLabel.ForeColor = $script:Colors.White
$logsLabel.AutoSize = $true
$logsLabel.Location = New-Object System.Drawing.Point(62, 590)
$form.Controls.Add($logsLabel)

$script:txtLogs = New-Object System.Windows.Forms.RichTextBox
$script:txtLogs.Multiline = $true
$script:txtLogs.ScrollBars = 'Vertical'
$script:txtLogs.Size = New-Object System.Drawing.Size(900, 120)
$script:txtLogs.Location = New-Object System.Drawing.Point(62, 620)
$script:txtLogs.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 30)
$script:txtLogs.ForeColor = $script:Colors.GrayLight
$script:txtLogs.Font = New-Object System.Drawing.Font('Consolas', 9)
$script:txtLogs.ReadOnly = $true
$script:txtLogs.BorderStyle = 'FixedSingle'
$form.Controls.Add($script:txtLogs)

# Panel pour les 6 boutons du bas (centrés)
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Size = New-Object System.Drawing.Size(900, 60)
$bottomPanel.Location = New-Object System.Drawing.Point(62, 730)
$bottomPanel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($bottomPanel)

$buttonWidth = 140
$buttonSpacing = 10
$totalWidth = (6 * $buttonWidth) + (5 * $buttonSpacing)
$startX = (900 - $totalWidth) / 2

# Bouton Donation
$btnDonation = New-Object System.Windows.Forms.Button
$btnDonation.Text = "♥ Donation"
$btnDonation.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnDonation.Location = New-Object System.Drawing.Point($startX, 5)
$btnDonation.BackColor = $script:Colors.GrayDark
$btnDonation.ForeColor = $script:Colors.White
$btnDonation.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnDonation.FlatStyle = 'Flat'
$btnDonation.Cursor = 'Hand'
$btnDonation.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnDonation.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnDonation.Add_Click({ Start-Process $script:Config.DonationPayPal })
$bottomPanel.Controls.Add($btnDonation)

# Bouton Telegram
$btnTelegram = New-Object System.Windows.Forms.Button
$btnTelegram.Text = "✉ Telegram"
$btnTelegram.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnTelegram.Location = New-Object System.Drawing.Point(($startX + $buttonWidth + $buttonSpacing), 5)
$btnTelegram.BackColor = $script:Colors.GrayDark
$btnTelegram.ForeColor = $script:Colors.White
$btnTelegram.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnTelegram.FlatStyle = 'Flat'
$btnTelegram.Cursor = 'Hand'
$btnTelegram.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnTelegram.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnTelegram.Add_Click({ Start-Process $script:Config.TelegramUrl })
$bottomPanel.Controls.Add($btnTelegram)

# Bouton Info
$btnInfo = New-Object System.Windows.Forms.Button
$btnInfo.Text = "i Info"
$btnInfo.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnInfo.Location = New-Object System.Drawing.Point(($startX + (2 * ($buttonWidth + $buttonSpacing))), 5)
$btnInfo.BackColor = $script:Colors.GrayDark
$btnInfo.ForeColor = $script:Colors.White
$btnInfo.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnInfo.FlatStyle = 'Flat'
$btnInfo.Cursor = 'Hand'
$btnInfo.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnInfo.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnInfo.Add_Click({
    $infoMsg = "$($script:Config.AppName) v$($script:Config.Version)`n`nOutil professionnel de configuration DNS`n© 2025 - Tous droits réservés`n`nDNS utilisés :`nPrimaire IPv4: $($script:Config.DNSIPv4Primary)`nSecondaire IPv4: $($script:Config.DNSIPv4Secondary)`nPrimaire IPv6: $($script:Config.DNSIPv6Primary)`nSecondaire IPv6: $($script:Config.DNSIPv6Secondary)"
    [System.Windows.Forms.MessageBox]::Show($infoMsg, "Informations", 'OK', 'Information')
})
$bottomPanel.Controls.Add($btnInfo)

# Bouton Voir DNS
$btnViewDNS = New-Object System.Windows.Forms.Button
$btnViewDNS.Text = "🔍 Voir DNS"
$btnViewDNS.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnViewDNS.Location = New-Object System.Drawing.Point(($startX + (3 * ($buttonWidth + $buttonSpacing))), 5)
$btnViewDNS.BackColor = $script:Colors.GrayDark
$btnViewDNS.ForeColor = $script:Colors.White
$btnViewDNS.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnViewDNS.FlatStyle = 'Flat'
$btnViewDNS.Cursor = 'Hand'
$btnViewDNS.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnViewDNS.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnViewDNS.Add_Click({
    Start-Process "powershell.exe" -ArgumentList "-NoProfile", "-Command", "ipconfig /all | Select-String 'DNS' | Out-String | Out-GridView -Title 'Configuration DNS actuelle' -Wait"
})
$bottomPanel.Controls.Add($btnViewDNS)

# Bouton Ouvrir Logs
$btnOpenLogs = New-Object System.Windows.Forms.Button
$btnOpenLogs.Text = "📄 Ouvrir Logs"
$btnOpenLogs.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnOpenLogs.Location = New-Object System.Drawing.Point(($startX + (4 * ($buttonWidth + $buttonSpacing))), 5)
$btnOpenLogs.BackColor = $script:Colors.GrayDark
$btnOpenLogs.ForeColor = $script:Colors.White
$btnOpenLogs.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnOpenLogs.FlatStyle = 'Flat'
$btnOpenLogs.Cursor = 'Hand'
$btnOpenLogs.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnOpenLogs.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnOpenLogs.Add_Click({
    if (Test-Path $script:Config.LogFile) {
        Start-Process "notepad.exe" $script:Config.LogFile
    } else {
        [System.Windows.Forms.MessageBox]::Show("Aucun fichier de logs trouvé.", "Logs", 'OK', 'Warning')
    }
})
$bottomPanel.Controls.Add($btnOpenLogs)

# Bouton Fermer
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "✖ Fermer"
$btnClose.Size = New-Object System.Drawing.Size($buttonWidth, 45)
$btnClose.Location = New-Object System.Drawing.Point(($startX + (5 * ($buttonWidth + $buttonSpacing))), 5)
$btnClose.BackColor = $script:Colors.GrayDark
$btnClose.ForeColor = $script:Colors.White
$btnClose.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$btnClose.FlatStyle = 'Flat'
$btnClose.Cursor = 'Hand'
$btnClose.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 95) })
$btnClose.Add_MouseLeave({ $this.BackColor = $script:Colors.GrayDark })
$btnClose.Add_Click({ $form.Close() })
$bottomPanel.Controls.Add($btnClose)

Write-Log "Interface PREMIUM initialisée avec succès"
$form.ShowDialog() | Out-Null
