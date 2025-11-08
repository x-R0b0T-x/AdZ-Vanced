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



# ========================================
# INTERFACE UTILISATEUR PRINCIPALE
# ========================================

# Création du formulaire principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($script:Config.AppName) v$($script:Config.Version)"
$form.Size = New-Object System.Drawing.Size(1024, 768)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 25, 45)

    # Titre principal
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $script:Config.AppName
    $titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 32, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.AutoSize = $false
    $titleLabel.Size = New-Object System.Drawing.Size(1024, 50)
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.TextAlign = 'MiddleCenter'
    $form.Controls.Add($titleLabel)
    
    # Version
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "v$($script:Config.Version)"
    $versionLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12)
    $versionLabel.ForeColor = [System.Drawing.Color]::LightGray
    $versionLabel.AutoSize = $false
    $versionLabel.Size = New-Object System.Drawing.Size(1024, 25)
    $versionLabel.Location = New-Object System.Drawing.Point(0, 75)
    $versionLabel.TextAlign = 'MiddleCenter'
    $form.Controls.Add($versionLabel)
    
    # Logo (Shield avec A)
    $logoLabel = New-Object System.Windows.Forms.Label
        $logoLabel.Text = "[    A    ]"
    $logoLabel.Font = New-Object System.Drawing.Font('Segoe UI', 48, [System.Drawing.FontStyle]::Bold)
    $logoLabel.ForeColor = [System.Drawing.Color]::FromArgb(147, 51, 234)
    $logoLabel.AutoSize = $false
    $logoLabel.Size = New-Object System.Drawing.Size(1024, 80)
    $logoLabel.Location = New-Object System.Drawing.Point(0, 110)
    $logoLabel.TextAlign = 'MiddleCenter'
    $form.Controls.Add($logoLabel)
    
    # Panneau de message informatif
    $messagePanel = New-Object System.Windows.Forms.Panel
    $messagePanel.Size = New-Object System.Drawing.Size(900, 60)
    $messagePanel.Location = New-Object System.Drawing.Point(62, 210)
    $messagePanel.BorderStyle = 'FixedSingle'
    $messagePanel.BackColor = [System.Drawing.Color]::FromArgb(30, 35, 55)
    $form.Controls.Add($messagePanel)
    
    $script:txtStatus = New-Object System.Windows.Forms.Label
    $script:txtStatus.Text = "Panneau de message informatif : Prêt à optimizze votre connexion."
    $script:txtStatus.Font = New-Object System.Drawing.Font('Segoe UI', 11)
    $script:txtStatus.ForeColor = [System.Drawing.Color]::LightCyan
    $script:txtStatus.AutoSize = $false
    $script:txtStatus.Size = New-Object System.Drawing.Size(880, 50)
    $script:txtStatus.Location = New-Object System.Drawing.Point(10, 5)
    $script:txtStatus.TextAlign = 'MiddleLeft'
    $messagePanel.Controls.Add($script:txtStatus)
    
    # Bouton INSTALLER DNS
    $btnInstall = New-Object System.Windows.Forms.Button
    $btnInstall.Text = "INSTALLER DNS"
    $btnInstall.Size = New-Object System.Drawing.Size(400, 50)
    $btnInstall.Location = New-Object System.Drawing.Point(112, 290)
    $btnInstall.BackColor = [System.Drawing.Color]::FromArgb(147, 51, 234)
    $btnInstall.ForeColor = [System.Drawing.Color]::White
    $btnInstall.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $btnInstall.FlatStyle = 'Flat'
    $btnInstall.FlatAppearance.BorderSize = 0
    $btnInstall.Cursor = 'Hand'
    $btnInstall.Add_Click({
        Apply-AdZvancedDNS
    })
    $form.Controls.Add($btnInstall)
    
    # Bouton RESTAURER DNS
    $btnRestore = New-Object System.Windows.Forms.Button
    $btnRestore.Text = "RESTAURER DNS"
    $btnRestore.Size = New-Object System.Drawing.Size(400, 50)
    $btnRestore.Location = New-Object System.Drawing.Point(512, 290)
    $btnRestore.BackColor = [System.Drawing.Color]::FromArgb(147, 51, 234)
    $btnRestore.ForeColor = [System.Drawing.Color]::White
    $btnRestore.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $btnRestore.FlatStyle = 'Flat'
    $btnRestore.FlatAppearance.BorderSize = 0
    $btnRestore.Cursor = 'Hand'
    $btnRestore.Add_Click({
        Restore-DNSBackup
    })
    $form.Controls.Add($btnRestore)
    
    # Zone de Logs
    $logsLabel = New-Object System.Windows.Forms.Label
    $logsLabel.Text = "Logs :"
    $logsLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $logsLabel.ForeColor = [System.Drawing.Color]::White
    $logsLabel.AutoSize = $true
    $logsLabel.Location = New-Object System.Drawing.Point(62, 360)
    $form.Controls.Add($logsLabel)
    
    $script:txtLogs = New-Object System.Windows.Forms.TextBox
    $script:txtLogs.Multiline = $true
    $script:txtLogs.ScrollBars = 'Vertical'
    $script:txtLogs.Size = New-Object System.Drawing.Size(900, 200)
    $script:txtLogs.Location = New-Object System.Drawing.Point(62, 390)
    $script:txtLogs.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 30)
    $script:txtLogs.ForeColor = [System.Drawing.Color]::LightGray
    $script:txtLogs.Font = New-Object System.Drawing.Font('Consolas', 9)
    $script:txtLogs.ReadOnly = $true
    $script:txtLogs.BorderStyle = 'FixedSingle'
    $form.Controls.Add($script:txtLogs)
    
    # Panel pour les boutons du bas (centrés)
    $bottomPanel = New-Object System.Windows.Forms.Panel
    $bottomPanel.Size = New-Object System.Drawing.Size(900, 60)
    $bottomPanel.Location = New-Object System.Drawing.Point(62, 610)
    $bottomPanel.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($bottomPanel)
    
    # Calcul pour centrer les 6 boutons (150px chacun + 10px espacement)
    $buttonWidth = 140
    $buttonSpacing = 10
    $totalWidth = (6 * $buttonWidth) + (5 * $buttonSpacing)
    $startX = (900 - $totalWidth) / 2
    
    # Bouton Donation
    $btnDonation = New-Object System.Windows.Forms.Button
    $btnDonation.Text = "♥ Donation"
    $btnDonation.Size = New-Object System.Drawing.Size($buttonWidth, 45)
    $btnDonation.Location = New-Object System.Drawing.Point($startX, 5)
    $btnDonation.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnDonation.ForeColor = [System.Drawing.Color]::White
    $btnDonation.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnDonation.FlatStyle = 'Flat'
    $btnDonation.Cursor = 'Hand'
    $btnDonation.Add_Click({
        Start-Process 'https://www.paypal.com/ncp/payment/MGLWSKGF79JN8'
    })
    $bottomPanel.Controls.Add($btnDonation)
    
    # Bouton Telegram
    $btnTelegram = New-Object System.Windows.Forms.Button
    $btnTelegram.Text = "✉ Telegram"
    $btnTelegram.Size = New-Object System.Drawing.Size($buttonWidth, 45)
    $btnTelegram.Location = New-Object System.Drawing.Point(($startX + $buttonWidth + $buttonSpacing), 5)
    $btnTelegram.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnTelegram.ForeColor = [System.Drawing.Color]::White
    $btnTelegram.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnTelegram.FlatStyle = 'Flat'
    $btnTelegram.Cursor = 'Hand'
    $btnTelegram.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Rejoignez notre communauté Telegram pour le support et les mises à jour!", "Telegram", 'OK', 'Information')
    })
    $bottomPanel.Controls.Add($btnTelegram)
    
    # Bouton Info
    $btnInfo = New-Object System.Windows.Forms.Button
    $btnInfo.Text = "i Info"
    $btnInfo.Size = New-Object System.Drawing.Size($buttonWidth, 45)
    $btnInfo.Location = New-Object System.Drawing.Point(($startX + (2 * ($buttonWidth + $buttonSpacing))), 5)
    $btnInfo.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnInfo.ForeColor = [System.Drawing.Color]::White
    $btnInfo.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnInfo.FlatStyle = 'Flat'
    $btnInfo.Cursor = 'Hand'
    $btnInfo.Add_Click({
        $infoMsg = "$($script:Config.AppName) v$($script:Config.Version)`n`nOutil de configuration DNS avancé`n© 2024 - Tous droits réservés`n`nDNS utilisés :`nPrimaire IPv4: $($script:Config.DNSIPv4Primary)`nSecondaire IPv4: $($script:Config.DNSIPv4Secondary)`nPrimaire IPv6: $($script:Config.DNSIPv6Primary)`nSecondaire IPv6: $($script:Config.DNSIPv6Secondary)"
        [System.Windows.Forms.MessageBox]::Show($infoMsg, "Informations", 'OK', 'Information')
    })
    $bottomPanel.Controls.Add($btnInfo)
    
    # Bouton Voir DNS
    $btnViewDNS = New-Object System.Windows.Forms.Button
    $btnViewDNS.Text = "🔍 Voir DNS"
    $btnViewDNS.Size = New-Object System.Drawing.Size($buttonWidth, 45)
    $btnViewDNS.Location = New-Object System.Drawing.Point(($startX + (3 * ($buttonWidth + $buttonSpacing))), 5)
    $btnViewDNS.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnViewDNS.ForeColor = [System.Drawing.Color]::White
    $btnViewDNS.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnViewDNS.FlatStyle = 'Flat'
    $btnViewDNS.Cursor = 'Hand'
    $btnViewDNS.Add_Click({
        Start-Process "powershell.exe" -ArgumentList "-NoProfile", "-Command", "ipconfig /all | Select-String 'DNS' | Out-String | Out-GridView -Title 'Configuration DNS actuelle' -Wait"
    })
    $bottomPanel.Controls.Add($btnViewDNS)
    
    # Bouton Ouvrir Logs
    $btnOpenLogs = New-Object System.Windows.Forms.Button
    $btnOpenLogs.Text = "📄 Ouvrir Logs"
    $btnOpenLogs.Size = New-Object System.Drawing.Size($buttonWidth, 45)
    $btnOpenLogs.Location = New-Object System.Drawing.Point(($startX + (4 * ($buttonWidth + $buttonSpacing))), 5)
    $btnOpenLogs.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnOpenLogs.ForeColor = [System.Drawing.Color]::White
    $btnOpenLogs.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnOpenLogs.FlatStyle = 'Flat'
    $btnOpenLogs.Cursor = 'Hand'
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
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(50, 55, 75)
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btnClose.FlatStyle = 'Flat'
    $btnClose.Cursor = 'Hand'
    $btnClose.Add_Click({
        $form.Close()
    })
    $bottomPanel.Controls.Add($btnClose)

Write-Log "Interface initialisée avec succès"
$form.ShowDialog() | Out-Null
