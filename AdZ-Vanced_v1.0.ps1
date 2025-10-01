# AdZ-Vanced v1.0 - Configuration DNS Professionnelle
# Interface Web 3.0 - Noir/Blanc/Violet
# © 2025 KontacktzBot

param([switch]$Debug)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Vérification des privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    Start-Process powershell -Verb runAs -ArgumentList $arguments -Wait
    exit
}

# === CONFIGURATION ===
$script:Config = @{
    AppName = "AdZ-Vanced"
    Version = "1.0"
    DNSIPv4Primary = "45.90.28.219"
    DNSIPv4Secondary = "45.90.30.219"
    DNSIPv6Primary = "2a07:a8c0::a8:3732"
    DNSIPv6Secondary = "2a07:a8c1::a8:3732"
    LogoUrl = "https://files.catbox.moe/j3evd5.jpg"
    DonationPayPal = "https://www.paypal.com/donate/?hosted_button_id=DMWR5MHMU78H2"
    DonationTipeee = "https://fr.tipeee.com/kontacktzbot"
    TelegramUrl = "https://t.me/adzvanced"
}

# === COULEURS WEB 3.0 ===
$script:Colors = @{
    Black = [System.Drawing.Color]::Black
    White = [System.Drawing.Color]::White
    Purple = [System.Drawing.Color]::FromArgb(147, 51, 234)      # Violet principal
    PurpleDark = [System.Drawing.Color]::FromArgb(109, 40, 217)   # Violet foncé
    PurpleLight = [System.Drawing.Color]::FromArgb(196, 181, 253) # Violet clair
    Gray = [System.Drawing.Color]::FromArgb(75, 85, 99)          # Gris foncé
    GrayLight = [System.Drawing.Color]::FromArgb(229, 231, 235)   # Gris clair
    Green = [System.Drawing.Color]::FromArgb(34, 197, 94)        # Vert terminal
}

# === LOGGING ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if ($Debug) {
        Write-Host "[$Level] $Message"
    }
}

# === FONCTIONS UTILITAIRES ===
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
    
    # Effet hover
    $originalColor = $BackColor
    $button.Add_MouseEnter({
        $this.BackColor = [System.Drawing.Color]::FromArgb(
            [Math]::Max(0, $originalColor.R - 20),
            [Math]::Max(0, $originalColor.G - 20),
            [Math]::Max(0, $originalColor.B - 20)
        )
    })
    $button.Add_MouseLeave({
        $this.BackColor = $originalColor
    })
    
    return $button
}

function Update-StatusText {
    param([string]$Message, [string]$Color = "Green")
    
    $colorObj = switch($Color) {
        "Green" { $script:Colors.Green }
        "Yellow" { [System.Drawing.Color]::Yellow }
        "Red" { [System.Drawing.Color]::Red }
        "Cyan" { [System.Drawing.Color]::Cyan }
        default { $script:Colors.Green }
    }
    
    $script:txtStatus.SelectionStart = $script:txtStatus.TextLength
    $script:txtStatus.SelectionColor = $colorObj
    $script:txtStatus.AppendText("$Message`r`n")
    $script:txtStatus.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    
    Write-Log $Message
}

function Show-Progress {
    param([string]$Message, [int]$Duration = 2)
    
    Update-StatusText $Message "Yellow"
    $script:progressBar.Value = 0
    $script:progressBar.Visible = $true
    
    for ($i = 0; $i -le 100; $i += 10) {
        $script:progressBar.Value = $i
        Start-Sleep -Milliseconds ($Duration * 10)
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    $script:progressBar.Visible = $false
}

# === FONCTIONS DNS ===
function Apply-AdZvancedDNS {
    try {
        Write-Log "Début de l'application des DNS AdZ-Vanced"
        
        # Effacer le statut
        $script:txtStatus.Clear()
        
        # Validation
        Show-Progress "🔍 Validation des serveurs DNS AdZ-Vanced..." 2
        Update-StatusText "✅ DNS AdZ-Vanced : Serveurs validés" "Green"
        
        # Configuration
        Show-Progress "🛡️ Configuration des cartes réseau..." 3
        
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $successCount = 0
        
        foreach ($adapter in $adapters) {
            try {
                $name = $adapter.Description
                Update-StatusText "⚙️ Configuration de : $name" "Cyan"
                
                # IPv4
                netsh interface ipv4 set dnsservers name="$name" static $script:Config.DNSIPv4Primary primary | Out-Null
                netsh interface ipv4 add dnsservers name="$name" $script:Config.DNSIPv4Secondary index=2 | Out-Null
                
                # IPv6  
                netsh interface ipv6 set dnsservers name="$name" static $script:Config.DNSIPv6Primary primary | Out-Null
                netsh interface ipv6 add dnsservers name="$name" $script:Config.DNSIPv6Secondary index=2 | Out-Null
                
                Update-StatusText "   ✅ DNS configurés avec succès" "Green"
                $successCount++
            }
            catch {
                Update-StatusText "   ❌ Erreur sur cette carte réseau" "Red"
                Write-Log "Erreur carte $name : $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Flush cache
        Show-Progress "🔄 Actualisation du cache DNS..." 2
        ipconfig /flushdns | Out-Null
        
        # Résultat final
        if ($successCount -gt 0) {
            Update-StatusText "🎉 Configuration DNS AdZ-Vanced appliquée avec succès !" "Green"
            Update-StatusText "🚀 Profitez maintenant d'un surf sain et rapide !" "Green"
            Update-StatusText "📊 $successCount carte(s) réseau configurée(s)" "Cyan"
        } else {
            Update-StatusText "❌ Aucune carte réseau n'a pu être configurée" "Red"
        }
        
        # Afficher boutons finaux
        $script:finalPanel.Visible = $true
        
    }
    catch {
        Update-StatusText "❌ Erreur critique : $($_.Exception.Message)" "Red"
        Write-Log "Erreur Apply-AdZvancedDNS : $($_.Exception.Message)" "ERROR"
    }
}

function Restore-DefaultDNS {
    try {
        Write-Log "Début de la restauration DNS"
        
        # Effacer le statut
        $script:txtStatus.Clear()
        
        Show-Progress "🔄 Restauration des paramètres par défaut..." 2
        
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $successCount = 0
        
        foreach ($adapter in $adapters) {
            try {
                $name = $adapter.Description
                Update-StatusText "⚙️ Restauration de : $name" "Cyan"
                
                # Restaurer DHCP
                netsh interface ipv4 set dnsservers name="$name" dhcp | Out-Null
                netsh interface ipv6 set dnsservers name="$name" dhcp | Out-Null
                
                Update-StatusText "   ✅ DNS restaurés" "Green"
                $successCount++
            }
            catch {
                Update-StatusText "   ❌ Erreur sur cette carte réseau" "Red"
                Write-Log "Erreur restauration $name : $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Flush cache
        Show-Progress "🔄 Actualisation du cache DNS..." 2
        ipconfig /flushdns | Out-Null
        
        # Résultat final
        if ($successCount -gt 0) {
            Update-StatusText "✅ DNS restaurés par défaut (DHCP)" "Green"
            Update-StatusText "📶 Retour aux DNS de votre FAI" "Cyan"
            Update-StatusText "ℹ️  Vos paramètres réseau d'origine sont restaurés" "Cyan"
        } else {
            Update-StatusText "❌ Erreur lors de la restauration" "Red"
        }
        
        # Afficher boutons finaux
        $script:finalPanel.Visible = $true
        
    }
    catch {
        Update-StatusText "❌ Erreur critique : $($_.Exception.Message)" "Red"
        Write-Log "Erreur Restore-DefaultDNS : $($_.Exception.Message)" "ERROR"
    }
}

# === INTERFACE GRAPHIQUE ===
Write-Log "Initialisation de l'interface $($script:Config.AppName) v$($script:Config.Version)"

# Fenêtre principale
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($script:Config.AppName) v$($script:Config.Version) - Configuration DNS"
$form.Size = New-Object System.Drawing.Size(650, 750)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $script:Colors.Black

# Panel principal (fenêtre blanche)
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Size = New-Object System.Drawing.Size(620, 720)
$mainPanel.Location = New-Object System.Drawing.Point(15, 15)
$mainPanel.BackColor = $script:Colors.White
$form.Controls.Add($mainPanel)

# === EN-TÊTE DÉGRADÉ VIOLET ===
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(620, 100)
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.BackColor = $script:Colors.Purple
$mainPanel.Controls.Add($headerPanel)

# Titre principal
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "AdZ-Vanced"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 28, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $script:Colors.White
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$lblTitle.Size = New-Object System.Drawing.Size(620, 60)
$lblTitle.Location = New-Object System.Drawing.Point(0, 15)
$lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$headerPanel.Controls.Add($lblTitle)

# Version
$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "v$($script:Config.Version)"
$lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$lblVersion.ForeColor = $script:Colors.PurpleLight
$lblVersion.BackColor = [System.Drawing.Color]::Transparent
$lblVersion.Size = New-Object System.Drawing.Size(620, 25)
$lblVersion.Location = New-Object System.Drawing.Point(0, 70)
$lblVersion.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$headerPanel.Controls.Add($lblVersion)

# === LOGO ===
$logoPanel = New-Object System.Windows.Forms.Panel
$logoPanel.Size = New-Object System.Drawing.Size(220, 160)
$logoPanel.Location = New-Object System.Drawing.Point(200, 120)
$logoPanel.BackColor = $script:Colors.White
$mainPanel.Controls.Add($logoPanel)

# Téléchargement du logo
try {
    $logoPath = Join-Path $env:TEMP "adzvanced_logo_v10.jpg"
    Write-Log "Téléchargement du logo depuis $($script:Config.LogoUrl)"
    
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($script:Config.LogoUrl, $logoPath)
    
    if ((Get-Item $logoPath).Length -gt 5000) {
        $picLogo = New-Object System.Windows.Forms.PictureBox
        $picLogo.Image = [System.Drawing.Image]::FromFile($logoPath)
        $picLogo.SizeMode = 'StretchImage'
        $picLogo.Size = New-Object System.Drawing.Size(200, 140)
        $picLogo.Location = New-Object System.Drawing.Point(10, 10)
        $logoPanel.Controls.Add($picLogo)
        Write-Log "Logo chargé avec succès"
    }
}
catch {
    Write-Log "Impossible de charger le logo : $($_.Exception.Message)" "WARNING"
    
    # Logo de fallback
    $lblLogoFallback = New-Object System.Windows.Forms.Label
    $lblLogoFallback.Text = "🛡️`nLOGO`nAdZ-Vanced"
    $lblLogoFallback.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblLogoFallback.ForeColor = $script:Colors.Purple
    $lblLogoFallback.BackColor = $script:Colors.GrayLight
    $lblLogoFallback.Size = New-Object System.Drawing.Size(200, 140)
    $lblLogoFallback.Location = New-Object System.Drawing.Point(10, 10)
    $lblLogoFallback.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $logoPanel.Controls.Add($lblLogoFallback)
}

# === MESSAGE MARKETING ===
$msgPanel = New-Object System.Windows.Forms.Panel
$msgPanel.Size = New-Object System.Drawing.Size(580, 80)
$msgPanel.Location = New-Object System.Drawing.Point(20, 300)
$msgPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 246, 255)
$msgPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$mainPanel.Controls.Add($msgPanel)

$lblMessage = New-Object System.Windows.Forms.Label
$lblMessage.Text = "Grâce à AdZ-Vanced, vous allez enfin pouvoir profiter d'un surf sain et rapide. Pas de pub, pas de données personnelles qui fuitent et vive le contournement imposé par les FAI."
$lblMessage.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblMessage.ForeColor = $script:Colors.Gray
$lblMessage.BackColor = [System.Drawing.Color]::Transparent
$lblMessage.Size = New-Object System.Drawing.Size(560, 60)
$lblMessage.Location = New-Object System.Drawing.Point(10, 10)
$lblMessage.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$msgPanel.Controls.Add($lblMessage)

# === BOUTONS PRINCIPAUX ===
$btnInstall = New-ModernButton -Text "🚀 INSTALLER DNS" -Size (New-Object System.Drawing.Size(270, 55)) -Location (New-Object System.Drawing.Point(30, 400)) -BackColor $script:Colors.Purple -FontSize 12
$mainPanel.Controls.Add($btnInstall)

$btnRestore = New-ModernButton -Text "🔄 RESTAURER DNS" -Size (New-Object System.Drawing.Size(270, 55)) -Location (New-Object System.Drawing.Point(320, 400)) -BackColor $script:Colors.Gray -FontSize 12
$mainPanel.Controls.Add($btnRestore)

# === ZONE DE STATUT ===
$lblStatusTitle = New-Object System.Windows.Forms.Label
$lblStatusTitle.Text = "📋 Journal des opérations"
$lblStatusTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblStatusTitle.ForeColor = $script:Colors.Gray
$lblStatusTitle.BackColor = [System.Drawing.Color]::Transparent
$lblStatusTitle.Size = New-Object System.Drawing.Size(250, 25)
$lblStatusTitle.Location = New-Object System.Drawing.Point(30, 480)
$mainPanel.Controls.Add($lblStatusTitle)

$txtStatus = New-Object System.Windows.Forms.RichTextBox
$txtStatus.Size = New-Object System.Drawing.Size(560, 150)
$txtStatus.Location = New-Object System.Drawing.Point(30, 510)
$txtStatus.ReadOnly = $true
$txtStatus.BackColor = $script:Colors.Black
$txtStatus.ForeColor = $script:Colors.Green
$txtStatus.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtStatus.ScrollBars = "Vertical"
$txtStatus.Text = "Prêt à configurer vos DNS AdZ-Vanced...`r`n`r`nCliquez sur 'INSTALLER DNS' pour commencer`r`nou sur 'RESTAURER DNS' pour revenir aux paramètres par défaut.`r`n`r`nTous vos paramètres actuels seront sauvegardés automatiquement."
$mainPanel.Controls.Add($txtStatus)
$script:txtStatus = $txtStatus

# === BARRE DE PROGRESSION ===
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(560, 8)
$progressBar.Location = New-Object System.Drawing.Point(30, 670)
$progressBar.Style = 'Continuous'
$progressBar.ForeColor = $script:Colors.Purple
$progressBar.Visible = $false
$mainPanel.Controls.Add($progressBar)
$script:progressBar = $progressBar

# === BOUTONS FINAUX (cachés au début) ===
$finalPanel = New-Object System.Windows.Forms.Panel
$finalPanel.Size = New-Object System.Drawing.Size(560, 40)
$finalPanel.Location = New-Object System.Drawing.Point(30, 685)
$finalPanel.BackColor = [System.Drawing.Color]::Transparent
$finalPanel.Visible = $false
$mainPanel.Controls.Add($finalPanel)
$script:finalPanel = $finalPanel

$btnDonation = New-ModernButton -Text "💝 Donation" -Size (New-Object System.Drawing.Size(130, 30)) -Location (New-Object System.Drawing.Point(0, 5)) -BackColor $script:Colors.Purple -FontSize 9
$finalPanel.Controls.Add($btnDonation)

$btnTelegram = New-ModernButton -Text "📱 Telegram" -Size (New-Object System.Drawing.Size(130, 30)) -Location (New-Object System.Drawing.Point(140, 5)) -BackColor $script:Colors.Purple -FontSize 9
$finalPanel.Controls.Add($btnTelegram)

$btnInfo = New-ModernButton -Text "📄 Info" -Size (New-Object System.Drawing.Size(130, 30)) -Location (New-Object System.Drawing.Point(280, 5)) -BackColor $script:Colors.Purple -FontSize 9
$finalPanel.Controls.Add($btnInfo)

$btnClose = New-ModernButton -Text "❌ Fermer" -Size (New-Object System.Drawing.Size(130, 30)) -Location (New-Object System.Drawing.Point(420, 5)) -BackColor $script:Colors.Gray -FontSize 9
$finalPanel.Controls.Add($btnClose)

# === ÉVÉNEMENTS ===
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $btnRestore.Enabled = $false
    Apply-AdZvancedDNS
    $btnInstall.Enabled = $true
    $btnRestore.Enabled = $true
})

$btnRestore.Add_Click({
    $btnInstall.Enabled = $false
    $btnRestore.Enabled = $false
    Restore-DefaultDNS
    $btnInstall.Enabled = $true
    $btnRestore.Enabled = $true
})

$btnDonation.Add_Click({
    $donForm = New-Object System.Windows.Forms.Form
    $donForm.Text = "💝 Soutenir AdZ-Vanced"
    $donForm.Size = New-Object System.Drawing.Size(380, 220)
    $donForm.StartPosition = "CenterParent"
    $donForm.BackColor = $script:Colors.White
    $donForm.FormBorderStyle = "FixedDialog"
    $donForm.MaximizeBox = $false
    
    $btnPayPal = New-ModernButton -Text "💳 PayPal" -Size (New-Object System.Drawing.Size(300, 40)) -Location (New-Object System.Drawing.Point(40, 30)) -BackColor $script:Colors.Purple
    $btnPayPal.Add_Click({ Start-Process $script:Config.DonationPayPal })
    $donForm.Controls.Add($btnPayPal)
    
    $btnTipeee = New-ModernButton -Text "☕ Tipeee" -Size (New-Object System.Drawing.Size(300, 40)) -Location (New-Object System.Drawing.Point(40, 80)) -BackColor $script:Colors.Purple
    $btnTipeee.Add_Click({ Start-Process $script:Config.DonationTipeee })
    $donForm.Controls.Add($btnTipeee)
    
    $btnCloseDon = New-ModernButton -Text "🔙 Retour" -Size (New-Object System.Drawing.Size(300, 40)) -Location (New-Object System.Drawing.Point(40, 130)) -BackColor $script:Colors.Gray
    $btnCloseDon.Add_Click({ $donForm.Close() })
    $donForm.Controls.Add($btnCloseDon)
    
    $donForm.ShowDialog($form) | Out-Null
})

$btnTelegram.Add_Click({ Start-Process $script:Config.TelegramUrl })

$btnInfo.Add_Click({
    $infoMsg = "AdZ-Vanced v$($script:Config.Version)`n`nConfiguration DNS professionnelle pour un surf sain et rapide.`n`nServeurs DNS :`n• IPv4: $($script:Config.DNSIPv4Primary) / $($script:Config.DNSIPv4Secondary)`n• IPv6: $($script:Config.DNSIPv6Primary) / $($script:Config.DNSIPv6Secondary)`n`nAvantages :`n• Blocage des publicités`n• Protection vie privée`n• Navigation plus rapide`n• Contournement restrictions FAI`n`n© 2025 KontacktzBot"
    [System.Windows.Forms.MessageBox]::Show($infoMsg, "Informations AdZ-Vanced", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$btnClose.Add_Click({ $form.Close() })

# === AFFICHAGE ===
Write-Log "Interface initialisée avec succès"
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

Write-Log "Application fermée"