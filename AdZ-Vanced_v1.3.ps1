param(
    [switch]$Debug
)

# AdZ-Vanced v1.3 - Outil DNS professionnel
# Auteur: Votre nom
# Date: Janvier 2025

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Drawing2D

# Vérification des privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments -Wait
    exit
}

# === CONFIGURATION ===
$script:Config = @{
    AppName = "AdZ-Vanced"
    Version = "1.3"
    Author = "KontacktzBot"
    DNSIPv4Primary = "45.90.28.219"
    DNSIPv4Secondary = "45.90.30.219"
    DNSIPv6Primary = "2a07:a8c0::a8:3732"
    DNSIPv6Secondary = "2a07:a8c1::a8:3732"
    LogoUrl = "https://files.catbox.moe/j3evd5.jpg"
    DonationPayPal = "https://www.paypal.com/donate/?hosted_button_id=DMWR5MHMU78H2"
    DonationTipeee = "https://fr.tipeee.com/kontacktzbot"
    TelegramUrl = "https://t.me/adzvanced"
    BackupFile = "$env:TEMP\AdZvanced_DNS_Backup.json"
}

# === COULEURS ET THÈMES ===
$script:Theme = @{
    Primary = [System.Drawing.Color]::FromArgb(41, 128, 185)      # Bleu professionnel
    Secondary = [System.Drawing.Color]::FromArgb(52, 152, 219)     # Bleu clair
    Success = [System.Drawing.Color]::FromArgb(46, 204, 113)       # Vert
    Warning = [System.Drawing.Color]::FromArgb(241, 196, 15)       # Jaune
    Error = [System.Drawing.Color]::FromArgb(231, 76, 60)          # Rouge
    Dark = [System.Drawing.Color]::FromArgb(44, 62, 80)           # Gris foncé
    Light = [System.Drawing.Color]::FromArgb(236, 240, 241)       # Gris clair
    White = [System.Drawing.Color]::White
    Black = [System.Drawing.Color]::FromArgb(33, 37, 41)
    Background = [System.Drawing.Color]::FromArgb(248, 249, 250)
    CardBackground = [System.Drawing.Color]::White
}

# === LOGGING ===
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARNING","ERROR","SUCCESS")]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($Debug) {
        Write-Host $logMessage
    }
    
    # Log vers fichier
    $logFile = "$env:TEMP\AdZvanced.log"
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}

# === UTILITAIRES INTERFACE ===
function New-RoundedButton {
    param(
        [string]$Text,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = $script:Theme.Primary,
        [System.Drawing.Color]$ForeColor = $script:Theme.White,
        [int]$FontSize = 10
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
    $button.FlatAppearance.BorderColor = $BackColor
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Effet hover
    $button.Add_MouseEnter({
        $this.BackColor = [System.Drawing.Color]::FromArgb(
            [Math]::Min(255, $this.BackColor.R + 20),
            [Math]::Min(255, $this.BackColor.G + 20),
            [Math]::Min(255, $this.BackColor.B + 20)
        )
    })
    
    $button.Add_MouseLeave({
        $this.BackColor = $BackColor
    })
    
    return $button
}

function New-StyledLabel {
    param(
        [string]$Text,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$ForeColor = $script:Theme.Dark,
        [int]$FontSize = 9,
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular,
        [System.Drawing.ContentAlignment]$TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    )
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Size = $Size
    $label.Location = $Location
    $label.ForeColor = $ForeColor
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $FontSize, $FontStyle)
    $label.TextAlign = $TextAlign
    
    return $label
}

function Test-DNSConnectivity {
    param([string]$DNSServer)
    
    try {
        Write-Log "Test de connectivité DNS vers $DNSServer" "INFO"
        $result = Test-NetConnection -ComputerName $DNSServer -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        Write-Log "Résultat test DNS $DNSServer : $result" "INFO"
        return $result
    }
    catch {
        Write-Log "Erreur test DNS $DNSServer : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Backup-CurrentDNS {
    try {
        Write-Log "Sauvegarde des paramètres DNS actuels" "INFO"
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $backup = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Adapters = @()
        }
        
        foreach ($adapter in $adapters) {
            $adapterInfo = @{
                Description = $adapter.Description
                Index = $adapter.Index
                DNSServerSearchOrder = $adapter.DNSServerSearchOrder
                DNSServerSearchOrderIPv6 = @()
            }
            
            # Récupération DNS IPv6 via netsh
            try {
                $ipv6DNS = netsh interface ipv6 show dnsservers name="$($adapter.Description)" 2>$null
                if ($ipv6DNS) {
                    $adapterInfo.DNSServerSearchOrderIPv6 = $ipv6DNS | Where-Object { $_ -match "^\s+\d" } | ForEach-Object { $_.Trim() }
                }
            }
            catch {}
            
            $backup.Adapters += $adapterInfo
        }
        
        $backup | ConvertTo-Json -Depth 3 | Out-File $script:Config.BackupFile -Encoding UTF8
        Write-Log "Sauvegarde DNS créée : $($script:Config.BackupFile)" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la sauvegarde DNS : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-DNSFromBackup {
    param([bool]$RestoreToDefault = $false)
    
    try {
        if ($RestoreToDefault) {
            Write-Log "Restauration DNS par défaut (DHCP)" "INFO"
            $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            
            foreach ($adapter in $adapters) {
                $name = $adapter.Description
                Write-Log "Restauration DHCP sur $name" "INFO"
                
                # IPv4
                netsh interface ipv4 set dnsservers name="$name" dhcp | Out-Null
                # IPv6
                netsh interface ipv6 set dnsservers name="$name" dhcp | Out-Null
            }
            
            ipconfig /flushdns | Out-Null
            Write-Log "DNS restaurés par défaut (DHCP)" "SUCCESS"
            return $true
        }
        
        if (-not (Test-Path $script:Config.BackupFile)) {
            Write-Log "Aucune sauvegarde trouvée" "WARNING"
            return $false
        }
        
        $backup = Get-Content $script:Config.BackupFile -Raw | ConvertFrom-Json
        Write-Log "Restauration à partir de la sauvegarde du $($backup.Timestamp)" "INFO"
        
        foreach ($adapterBackup in $backup.Adapters) {
            $name = $adapterBackup.Description
            Write-Log "Restauration DNS sur $name" "INFO"
            
            # IPv4
            if ($adapterBackup.DNSServerSearchOrder -and $adapterBackup.DNSServerSearchOrder.Count -gt 0) {
                netsh interface ipv4 set dnsservers name="$name" static $($adapterBackup.DNSServerSearchOrder[0]) primary | Out-Null
                if ($adapterBackup.DNSServerSearchOrder.Count -gt 1) {
                    for ($i = 1; $i -lt $adapterBackup.DNSServerSearchOrder.Count; $i++) {
                        netsh interface ipv4 add dnsservers name="$name" $($adapterBackup.DNSServerSearchOrder[$i]) index=$($i + 1) | Out-Null
                    }
                }
            }
            
            # IPv6
            if ($adapterBackup.DNSServerSearchOrderIPv6 -and $adapterBackup.DNSServerSearchOrderIPv6.Count -gt 0) {
                netsh interface ipv6 set dnsservers name="$name" static $($adapterBackup.DNSServerSearchOrderIPv6[0]) primary | Out-Null
                if ($adapterBackup.DNSServerSearchOrderIPv6.Count -gt 1) {
                    for ($i = 1; $i -lt $adapterBackup.DNSServerSearchOrderIPv6.Count; $i++) {
                        netsh interface ipv6 add dnsservers name="$name" $($adapterBackup.DNSServerSearchOrderIPv6[$i]) index=$($i + 1) | Out-Null
                    }
                }
            }
        }
        
        ipconfig /flushdns | Out-Null
        Write-Log "DNS restaurés depuis la sauvegarde" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la restauration DNS : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Update-Status {
    param(
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")]$Type = "Info",
        [switch]$Append
    )
    
    $color = switch ($Type) {
        "Success" { $script:Theme.Success }
        "Warning" { $script:Theme.Warning }
        "Error" { $script:Theme.Error }
        default { $script:Theme.Dark }
    }
    
    if (-not $Append) {
        $script:txtStatus.Clear()
    }
    
    $script:txtStatus.SelectionStart = $script:txtStatus.TextLength
    $script:txtStatus.SelectionColor = $color
    $script:txtStatus.AppendText("$(Get-Date -Format 'HH:mm:ss') - $Message`r`n")
    $script:txtStatus.ScrollToCaret()
    
    Write-Log $Message $Type.ToUpper()
    [System.Windows.Forms.Application]::DoEvents()
}

function Show-ProgressAnimation {
    param(
        [string]$Message,
        [int]$DurationSeconds = 3
    )
    
    $script:progressBar.Visible = $true
    $script:progressBar.Value = 0
    
    Update-Status $Message "Info"
    
    $steps = 50
    $stepDelay = [Math]::Max(1, ($DurationSeconds * 1000) / $steps)
    
    for ($i = 0; $i -le $steps; $i++) {
        $script:progressBar.Value = ($i * 100) / $steps
        Start-Sleep -Milliseconds $stepDelay
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    $script:progressBar.Visible = $false
}

function Apply-AdZvancedDNS {
    try {
        # Validation préalable
        Update-Status "🔍 Validation des serveurs DNS..." "Info"
        
        $dnsServers = @($script:Config.DNSIPv4Primary, $script:Config.DNSIPv4Secondary)
        $validServers = 0
        
        foreach ($dns in $dnsServers) {
            if (Test-DNSConnectivity $dns) {
                $validServers++
                Update-Status "✅ DNS $dns : Accessible" "Success" -Append
            } else {
                Update-Status "⚠️ DNS $dns : Non accessible" "Warning" -Append
            }
        }
        
        if ($validServers -eq 0) {
            Update-Status "❌ Aucun serveur DNS AdZ-Vanced n'est accessible" "Error" -Append
            Update-Status "🌐 Vérifiez votre connexion Internet" "Info" -Append
            return $false
        }
        
        # Sauvegarde
        Update-Status "💾 Sauvegarde des paramètres actuels..." "Info" -Append
        if (-not (Backup-CurrentDNS)) {
            Update-Status "⚠️ Impossible de sauvegarder les paramètres actuels" "Warning" -Append
        }
        
        # Détection IP publique
        Show-ProgressAnimation "🌍 Détection de l'adresse IP publique..." 2
        
        try {
            $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content
            Update-Status "🌍 IP publique détectée : $publicIP" "Info" -Append
        }
        catch {
            Update-Status "⚠️ Impossible de détecter l'IP publique" "Warning" -Append
            $publicIP = "Non détectée"
        }
        
        # Application des DNS
        Show-ProgressAnimation "🔧 Configuration des serveurs DNS..." 3
        
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $successCount = 0
        $totalCount = $adapters.Count
        
        foreach ($adapter in $adapters) {
            $name = $adapter.Description
            Update-Status "⚙️ Configuration de : $name" "Info" -Append
            
            try {
                # IPv4
                netsh interface ipv4 set dnsservers name="$name" static $script:Config.DNSIPv4Primary primary | Out-Null
                netsh interface ipv4 add dnsservers name="$name" $script:Config.DNSIPv4Secondary index=2 | Out-Null
                
                # IPv6
                netsh interface ipv6 set dnsservers name="$name" static $script:Config.DNSIPv6Primary primary | Out-Null
                netsh interface ipv6 add dnsservers name="$name" $script:Config.DNSIPv6Secondary index=2 | Out-Null
                
                Update-Status "   ✅ DNS configurés avec succès" "Success" -Append
                $successCount++
            }
            catch {
                Update-Status "   ❌ Erreur : $($_.Exception.Message)" "Error" -Append
            }
        }
        
        # Flush DNS
        Show-ProgressAnimation "🔄 Actualisation du cache DNS..." 2
        ipconfig /flushdns | Out-Null
        
        # Résultats
        if ($successCount -eq $totalCount) {
            Update-Status "🎉 Configuration DNS AdZ-Vanced appliquée avec succès !" "Success" -Append
            Update-Status "📊 $successCount/$totalCount cartes réseau configurées" "Success" -Append
            Update-Status "🚀 Profitez d'une navigation plus saine et plus rapide !" "Info" -Append
        } else {
            Update-Status "⚠️ Configuration partielle : $successCount/$totalCount cartes configurées" "Warning" -Append
        }
        
        return $successCount -gt 0
        
    }
    catch {
        Update-Status "❌ Erreur critique : $($_.Exception.Message)" "Error" -Append
        Write-Log "Erreur critique Apply-AdZvancedDNS : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-DefaultDNS {
    try {
        Update-Status "🔄 Restauration des paramètres DNS par défaut..." "Info"
        
        Show-ProgressAnimation "🔧 Restauration en cours..." 2
        
        $success = Restore-DNSFromBackup -RestoreToDefault $true
        
        if ($success) {
            Update-Status "✅ DNS restaurés par défaut (DHCP)" "Success" -Append
            Update-Status "🔄 Cache DNS vidé" "Info" -Append
            Update-Status "📶 Vos paramètres réseau d'origine sont restaurés" "Success" -Append
        } else {
            Update-Status "❌ Erreur lors de la restauration" "Error" -Append
        }
        
        return $success
        
    }
    catch {
        Update-Status "❌ Erreur critique : $($_.Exception.Message)" "Error" -Append
        Write-Log "Erreur critique Restore-DefaultDNS : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# === INTERFACE GRAPHIQUE PRINCIPALE ===
Write-Log "Démarrage de $($script:Config.AppName) v$($script:Config.Version)" "INFO"

# Fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($script:Config.AppName) v$($script:Config.Version) - Configuration DNS Professionnelle"
$form.Size = New-Object System.Drawing.Size(700, 900)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $script:Theme.Background
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")

# Panel principal avec ombre
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(660, 840)
$mainPanel.Location = New-Object System.Drawing.Point(20, 20)
$mainPanel.BackColor = $script:Theme.CardBackground
$form.Controls.Add($mainPanel)

# === EN-TÊTE ===
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(660, 120)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.BackColor = $script:Theme.Primary
$mainPanel.Controls.Add($headerPanel)

# Titre principal
$lblTitle = New-StyledLabel -Text "$($script:Config.AppName)" -Size (New-Object System.Drawing.Size(400, 40)) -Location (New-Object System.Drawing.Point(30, 25)) -ForeColor $script:Theme.White -FontSize 24 -FontStyle Bold
$headerPanel.Controls.Add($lblTitle)

# Sous-titre
$lblSubtitle = New-StyledLabel -Text "Configuration DNS Professionnelle v$($script:Config.Version)" -Size (New-Object System.Drawing.Size(400, 25)) -Location (New-Object System.Drawing.Point(30, 65)) -ForeColor $script:Theme.Light -FontSize 12
$headerPanel.Controls.Add($lblSubtitle)

# === LOGO ===
$logoPanel = New-Object System.Windows.Forms.Panel
$logoPanel.Size = New-Object System.Drawing.Size(220, 160)
$logoPanel.Location = New-Object System.Drawing.Point(220, 140)
$logoPanel.BackColor = $script:Theme.CardBackground
$mainPanel.Controls.Add($logoPanel)

# Téléchargement et affichage du logo
$logoPath = Join-Path $env:TEMP "adzvanced_logo_v13.jpg"
try {
    Update-Status "📥 Téléchargement du logo..." "Info"
    Invoke-WebRequest -Uri $script:Config.LogoUrl -OutFile $logoPath -UseBasicParsing -TimeoutSec 10
    
    if ((Get-Item $logoPath).Length -gt 5000) {
        $picLogo = New-Object System.Windows.Forms.PictureBox
        $picLogo.Image = [System.Drawing.Image]::FromFile($logoPath)
        $picLogo.SizeMode = 'StretchImage'
        $picLogo.Size = New-Object System.Drawing.Size(200, 140)
        $picLogo.Location = New-Object System.Drawing.Point(10, 10)
        $logoPanel.Controls.Add($picLogo)
    }
}
catch {
    Write-Log "Impossible de télécharger le logo : $($_.Exception.Message)" "WARNING"
}

# === SECTION INFORMATIONS ===
$infoPanel = New-Object System.Windows.Forms.Panel
$infoPanel.Size = New-Object System.Drawing.Size(620, 80)
$infoPanel.Location = New-Object System.Drawing.Point(20, 320)
$infoPanel.BackColor = $script:Theme.Light
$mainPanel.Controls.Add($infoPanel)

$lblInfo = New-StyledLabel -Text "🛡️ Serveurs DNS AdZ-Vanced - Navigation sécurisée et rapide" -Size (New-Object System.Drawing.Size(600, 25)) -Location (New-Object System.Drawing.Point(20, 15)) -ForeColor $script:Theme.Dark -FontSize 11 -FontStyle Bold -TextAlign MiddleCenter
$infoPanel.Controls.Add($lblInfo)

$lblDNS = New-StyledLabel -Text "DNS IPv4: $($script:Config.DNSIPv4Primary) / $($script:Config.DNSIPv4Secondary)" -Size (New-Object System.Drawing.Size(600, 20)) -Location (New-Object System.Drawing.Point(20, 40)) -ForeColor $script:Theme.Dark -FontSize 9 -TextAlign MiddleCenter
$infoPanel.Controls.Add($lblDNS)

# === BOUTONS PRINCIPAUX ===
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Size = New-Object System.Drawing.Size(620, 80)
$buttonPanel.Location = New-Object System.Drawing.Point(20, 420)
$buttonPanel.BackColor = $script:Theme.CardBackground
$mainPanel.Controls.Add($buttonPanel)

# Bouton Installer
$btnInstall = New-RoundedButton -Text "🚀 INSTALLER DNS AdZ-Vanced" -Size (New-Object System.Drawing.Size(280, 50)) -Location (New-Object System.Drawing.Point(20, 15)) -BackColor $script:Theme.Success -FontSize 11
$buttonPanel.Controls.Add($btnInstall)

# Bouton Restaurer
$btnRestore = New-RoundedButton -Text "🔄 RESTAURER DNS PAR DÉFAUT" -Size (New-Object System.Drawing.Size(280, 50)) -Location (New-Object System.Drawing.Point(320, 15)) -BackColor $script:Theme.Warning -FontSize 11
$buttonPanel.Controls.Add($btnRestore)

# === ZONE DE STATUT ===
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Size = New-Object System.Drawing.Size(620, 280)
$statusPanel.Location = New-Object System.Drawing.Point(20, 520)
$statusPanel.BackColor = $script:Theme.CardBackground
$mainPanel.Controls.Add($statusPanel)

$lblStatusTitle = New-StyledLabel -Text "📋 Journal des opérations" -Size (New-Object System.Drawing.Size(300, 25)) -Location (New-Object System.Drawing.Point(20, 10)) -ForeColor $script:Theme.Dark -FontSize 11 -FontStyle Bold
$statusPanel.Controls.Add($lblStatusTitle)

$txtStatus = New-Object System.Windows.Forms.RichTextBox
$txtStatus.Size = New-Object System.Drawing.Size(580, 230)
$txtStatus.Location = New-Object System.Drawing.Point(20, 40)
$txtStatus.ReadOnly = $true
$txtStatus.BackColor = $script:Theme.Black
$txtStatus.ForeColor = $script:Theme.Light
$txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtStatus.ScrollBars = "Vertical"
$statusPanel.Controls.Add($txtStatus)
$script:txtStatus = $txtStatus

# === BARRE DE PROGRESSION ===
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(620, 8)
$progressBar.Location = New-Object System.Drawing.Point(20, 810)
$progressBar.Style = 'Continuous'
$progressBar.ForeColor = $script:Theme.Primary
$progressBar.Visible = $false
$mainPanel.Controls.Add($progressBar)
$script:progressBar = $progressBar

# === BOUTONS FINAUX ===
$finalPanel = New-Object System.Windows.Forms.Panel
$finalPanel.Size = New-Object System.Drawing.Size(620, 50)
$finalPanel.Location = New-Object System.Drawing.Point(20, 825)
$finalPanel.BackColor = $script:Theme.CardBackground
$finalPanel.Visible = $false
$mainPanel.Controls.Add($finalPanel)
$script:finalPanel = $finalPanel

$btnDonation = New-RoundedButton -Text "💝 Faire un don" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(20, 8)) -BackColor $script:Theme.Secondary -FontSize 9
$finalPanel.Controls.Add($btnDonation)

$btnTelegram = New-RoundedButton -Text "📱 Telegram" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(170, 8)) -BackColor $script:Theme.Secondary -FontSize 9
$finalPanel.Controls.Add($btnTelegram)

$btnBackup = New-RoundedButton -Text "💾 Sauvegarde" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(320, 8)) -BackColor $script:Theme.Dark -FontSize 9
$finalPanel.Controls.Add($btnBackup)

$btnClose = New-RoundedButton -Text "✖️ Fermer" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(470, 8)) -BackColor $script:Theme.Error -FontSize 9
$finalPanel.Controls.Add($btnClose)

# === ÉVÉNEMENTS ===
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $btnRestore.Enabled = $false
    
    $success = Apply-AdZvancedDNS
    
    $btnInstall.Enabled = $true
    $btnRestore.Enabled = $true
    $script:finalPanel.Visible = $true
})

$btnRestore.Add_Click({
    $btnInstall.Enabled = $false
    $btnRestore.Enabled = $false
    
    $success = Restore-DefaultDNS
    
    $btnInstall.Enabled = $true
    $btnRestore.Enabled = $true
    $script:finalPanel.Visible = $true
})

$btnDonation.Add_Click({
    $donForm = New-Object System.Windows.Forms.Form
    $donForm.Text = "💝 Soutenir AdZ-Vanced"
    $donForm.Size = New-Object System.Drawing.Size(400, 200)
    $donForm.StartPosition = "CenterParent"
    $donForm.BackColor = $script:Theme.CardBackground
    $donForm.FormBorderStyle = "FixedDialog"
    $donForm.MaximizeBox = $false
    
    $btnPayPal = New-RoundedButton -Text "💳 PayPal" -Size (New-Object System.Drawing.Size(320, 35)) -Location (New-Object System.Drawing.Point(40, 30)) -BackColor $script:Theme.Primary
    $btnPayPal.Add_Click({ Start-Process $script:Config.DonationPayPal })
    $donForm.Controls.Add($btnPayPal)
    
    $btnTipeee = New-RoundedButton -Text "☕ Tipeee" -Size (New-Object System.Drawing.Size(320, 35)) -Location (New-Object System.Drawing.Point(40, 80)) -BackColor $script:Theme.Success
    $btnTipeee.Add_Click({ Start-Process $script:Config.DonationTipeee })
    $donForm.Controls.Add($btnTipeee)
    
    $btnCloseDon = New-RoundedButton -Text "🔙 Retour" -Size (New-Object System.Drawing.Size(320, 35)) -Location (New-Object System.Drawing.Point(40, 130)) -BackColor $script:Theme.Dark
    $btnCloseDon.Add_Click({ $donForm.Close() })
    $donForm.Controls.Add($btnCloseDon)
    
    $donForm.ShowDialog($form) | Out-Null
})

$btnTelegram.Add_Click({ 
    Start-Process $script:Config.TelegramUrl 
})

$btnBackup.Add_Click({
    if (Test-Path $script:Config.BackupFile) {
        $backup = Get-Content $script:Config.BackupFile -Raw | ConvertFrom-Json
        $message = "Sauvegarde disponible du $($backup.Timestamp)`n`nVoulez-vous restaurer cette sauvegarde ?"
        $result = [System.Windows.Forms.MessageBox]::Show($message, "Restauration sauvegarde", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $btnInstall.Enabled = $false
            $btnRestore.Enabled = $false
            
            Update-Status "🔄 Restauration depuis la sauvegarde..." "Info"
            $success = Restore-DNSFromBackup
            
            $btnInstall.Enabled = $true
            $btnRestore.Enabled = $true
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Aucune sauvegarde disponible.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnClose.Add_Click({ 
    $form.Close() 
})

# === INITIALISATION ===
Update-Status "🎯 AdZ-Vanced v$($script:Config.Version) - Prêt à l'utilisation" "Success"
Update-Status "ℹ️ Cliquez sur 'INSTALLER' pour configurer les DNS AdZ-Vanced" "Info" -Append
Update-Status "ℹ️ Cliquez sur 'RESTAURER' pour revenir aux paramètres par défaut" "Info" -Append

# === AFFICHAGE ===
$form.Topmost = $true
$form.Add_Shown({ $form.Activate(); $form.Topmost = $false })

Write-Log "Interface graphique initialisée" "INFO"
[void]$form.ShowDialog()

Write-Log "Fermeture de l'application" "INFO"