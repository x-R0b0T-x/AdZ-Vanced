# ================================================================
# AdZ-Vanced Windows v1.0 - Edition Professionnelle
# Interface Web 3.0 Ultra-Premium | Compatible Windows 7-11 | x86/x64
# © 2025 KontacktzBot - Tous droits réservés
# ================================================================

param([switch]$Debug, [switch]$Portable)

# === VÉRIFICATION ARCHITECTURE ET COMPATIBILITÉ ===
$OSInfo = @{
    Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    ProcessArch = if ([Environment]::Is64BitProcess) { "x64" } else { "x86" }
    Version = [Environment]::OSVersion.Version
    ProductName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
}

Write-Host "=== AdZ-Vanced v1.0 - Détection Système ===" -ForegroundColor Cyan
Write-Host "OS: $($OSInfo.ProductName)" -ForegroundColor Green
Write-Host "Architecture: $($OSInfo.Architecture)" -ForegroundColor Green
Write-Host "Version: $($OSInfo.Version)" -ForegroundColor Green

# Vérification compatibilité Windows
if ($OSInfo.Version.Major -lt 6 -or ($OSInfo.Version.Major -eq 6 -and $OSInfo.Version.Minor -lt 1)) {
    [System.Windows.Forms.MessageBox]::Show("AdZ-Vanced nécessite Windows 7 ou supérieur.`nVersion détectée: Windows $($OSInfo.Version)", "Système non supporté", "OK", "Error")
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Drawing2D

# === VÉRIFICATION PRIVILÈGES ADMINISTRATEUR ===
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Élévation des privilèges administrateur..." -ForegroundColor Yellow
    
    $currentPath = $MyInvocation.MyCommand.Definition
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$currentPath`""
    
    if ($Debug) { $arguments += " -Debug" }
    if ($Portable) { $arguments += " -Portable" }
    
    try {
        Start-Process powershell -Verb runAs -ArgumentList $arguments -Wait
        exit
    } catch {
        [System.Windows.Forms.MessageBox]::Show("AdZ-Vanced nécessite des privilèges administrateur pour modifier la configuration réseau.", "Privilèges requis", "OK", "Warning")
        exit 1
    }
}

# === CONFIGURATION GLOBALE ===
$Global:AdZConfig = @{
    AppName = "AdZ-Vanced"
    Version = "1.0"
    Build = "2025.01.01"
    Author = "KontacktzBot"
    
    # Serveurs DNS AdZ-Vanced
    DNS = @{
        IPv4_Primary = "45.90.28.219"
        IPv4_Secondary = "45.90.30.219"
        IPv6_Primary = "2a07:a8c0::a8:3732"
        IPv6_Secondary = "2a07:a8c1::a8:3732"
    }
    
    # URLs et liens
    URLs = @{
        Logo = "https://files.catbox.moe/j3evd5.jpg"
        PayPal = "https://www.paypal.com/donate/?hosted_button_id=DMWR5MHMU78H2"
        Tipeee = "https://fr.tipeee.com/kontacktzbot"
        Telegram = "https://t.me/adzvanced"
        Website = "https://adz-vanced.com"
    }
    
    # Configuration système
    System = @{
        LogFile = if ($Portable) { ".\AdZvanced.log" } else { "$env:TEMP\AdZvanced.log" }
        BackupFile = if ($Portable) { ".\AdZvanced_Backup.json" } else { "$env:TEMP\AdZvanced_Backup.json" }
        TempLogo = if ($Portable) { ".\adzvanced_logo.jpg" } else { "$env:TEMP\adzvanced_logo_v10.jpg" }
    }
}

# === PALETTE COULEURS WEB 3.0 PREMIUM ===
$Global:Colors = @{
    # Couleurs principales
    Primary = [System.Drawing.Color]::FromArgb(147, 51, 234)      # Violet premium #9333ea
    PrimaryDark = [System.Drawing.Color]::FromArgb(109, 40, 217)   # Violet foncé #6d28d9
    PrimaryLight = [System.Drawing.Color]::FromArgb(196, 181, 253) # Violet clair #c4b5fd
    
    # Couleurs système
    Background = [System.Drawing.Color]::Black                     # Noir profond
    Surface = [System.Drawing.Color]::White                        # Blanc pur
    SurfaceElevated = [System.Drawing.Color]::FromArgb(248, 250, 252) # Gris très clair
    
    # Couleurs de texte
    TextPrimary = [System.Drawing.Color]::FromArgb(31, 41, 55)     # Gris foncé
    TextSecondary = [System.Drawing.Color]::FromArgb(107, 114, 128) # Gris moyen
    TextOnPrimary = [System.Drawing.Color]::White                   # Blanc
    
    # Couleurs d'état
    Success = [System.Drawing.Color]::FromArgb(34, 197, 94)        # Vert #22c55e
    Warning = [System.Drawing.Color]::FromArgb(245, 158, 11)       # Orange #f59e0b
    Error = [System.Drawing.Color]::FromArgb(239, 68, 68)          # Rouge #ef4444
    Info = [System.Drawing.Color]::FromArgb(59, 130, 246)          # Bleu #3b82f6
    
    # Couleurs terminal
    Terminal = [System.Drawing.Color]::FromArgb(34, 197, 94)       # Vert terminal
    TerminalBg = [System.Drawing.Color]::FromArgb(15, 23, 42)      # Noir bleuté
}

# === LOGGING AVANCÉ ===
function Write-AdZLog {
    param(
        [string]$Message,
        [ValidateSet("DEBUG","INFO","SUCCESS","WARNING","ERROR")]$Level = "INFO",
        [switch]$ShowConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console si debug ou demandé
    if ($Debug -or $ShowConsole) {
        $color = switch($Level) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "DEBUG" { "Cyan" }
            default { "White" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # Fichier log
    try {
        Add-Content -Path $Global:AdZConfig.System.LogFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Ignore les erreurs de log pour ne pas planter l'app
    }
}

# === GESTION D'ERREURS GLOBALE ===
trap {
    Write-AdZLog "Erreur critique: $($_.Exception.Message)" "ERROR" -ShowConsole
    Write-AdZLog "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
    
    if ($Global:MainForm) {
        [System.Windows.Forms.MessageBox]::Show(
            "Une erreur inattendue s'est produite.`n`nDétails: $($_.Exception.Message)`n`nConsultez le fichier de log pour plus d'informations.",
            "Erreur AdZ-Vanced",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    
    continue
}

# === FONCTIONS UTILITAIRES INTERFACE ===
function New-PremiumButton {
    param(
        [string]$Text,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = $Global:Colors.Primary,
        [System.Drawing.Color]$ForeColor = $Global:Colors.TextOnPrimary,
        [int]$FontSize = 12,
        [string]$FontFamily = "Segoe UI",
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Bold
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = $Size
    $button.Location = $Location
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font = New-Object System.Drawing.Font($FontFamily, $FontSize, $FontStyle)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.UseVisualStyleBackColor = $false
    
    # Effets hover premium
    $originalColor = $BackColor
    $hoverColor = [System.Drawing.Color]::FromArgb(
        [Math]::Max(0, $BackColor.R - 15),
        [Math]::Max(0, $BackColor.G - 15),
        [Math]::Max(0, $BackColor.B - 15)
    )
    
    $button.Add_MouseEnter({
        $this.BackColor = $hoverColor
    })
    
    $button.Add_MouseLeave({
        $this.BackColor = $originalColor
    })
    
    return $button
}

function New-PremiumLabel {
    param(
        [string]$Text,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$ForeColor = $Global:Colors.TextPrimary,
        [int]$FontSize = 10,
        [string]$FontFamily = "Segoe UI",
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular,
        [System.Drawing.ContentAlignment]$TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    )
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Size = $Size
    $label.Location = $Location
    $label.ForeColor = $ForeColor
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.Font = New-Object System.Drawing.Font($FontFamily, $FontSize, $FontStyle)
    $label.TextAlign = $TextAlign
    
    return $label
}

function New-PremiumPanel {
    param(
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = $Global:Colors.Surface,
        [int]$BorderRadius = 12
    )
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = $Size
    $panel.Location = $Location
    $panel.BackColor = $BackColor
    
    return $panel
}

# === FONCTIONS RÉSEAU AVANCÉES ===
function Test-InternetConnectivity {
    try {
        Write-AdZLog "Test de connectivité Internet..." "INFO"
        $response = Invoke-WebRequest -Uri "https://www.google.com" -Method Head -TimeoutSec 5 -UseBasicParsing
        Write-AdZLog "Connectivité Internet: OK" "SUCCESS"
        return $true
    } catch {
        Write-AdZLog "Pas de connectivité Internet: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

function Test-DNSServer {
    param([string]$DNSServer, [int]$TimeoutMs = 3000)
    
    try {
        Write-AdZLog "Test DNS $DNSServer..." "INFO"
        $result = Test-NetConnection -ComputerName $DNSServer -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($result) {
            Write-AdZLog "DNS $DNSServer: Accessible" "SUCCESS"
            return $true
        } else {
            Write-AdZLog "DNS $DNSServer: Non accessible" "WARNING"
            return $false
        }
    } catch {
        Write-AdZLog "Erreur test DNS $DNSServer : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-PublicIP {
    $providers = @(
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://icanhazip.com"
    )
    
    foreach ($provider in $providers) {
        try {
            Write-AdZLog "Récupération IP publique via $provider..." "DEBUG"
            $ip = (Invoke-WebRequest -Uri $provider -UseBasicParsing -TimeoutSec 3).Content.Trim()
            if ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                Write-AdZLog "IP publique détectée: $ip" "SUCCESS"
                return $ip
            }
        } catch {
            Write-AdZLog "Échec $provider : $($_.Exception.Message)" "DEBUG"
            continue
        }
    }
    
    Write-AdZLog "Impossible de détecter l'IP publique" "WARNING"
    return "Non détectée"
}

function Backup-CurrentDNSSettings {
    try {
        Write-AdZLog "Sauvegarde des paramètres DNS actuels..." "INFO"
        
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $backup = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = $Global:AdZConfig.Version
            System = "$($OSInfo.ProductName) $($OSInfo.Architecture)"
            Adapters = @()
        }
        
        foreach ($adapter in $adapters) {
            $adapterBackup = @{
                Index = $adapter.Index
                Description = $adapter.Description
                DNSServerSearchOrder = $adapter.DNSServerSearchOrder
                DNSServerSearchOrderIPv6 = @()
            }
            
            # Récupération DNS IPv6
            try {
                $ipv6DNS = netsh interface ipv6 show dnsservers name="$($adapter.Description)" 2>$null
                if ($ipv6DNS) {
                    $adapterBackup.DNSServerSearchOrderIPv6 = $ipv6DNS | Where-Object { $_ -match "^\s+[0-9a-f:]+" } | ForEach-Object { $_.Trim() }
                }
            } catch {
                Write-AdZLog "Erreur récupération IPv6 pour $($adapter.Description)" "DEBUG"
            }
            
            $backup.Adapters += $adapterBackup
        }
        
        $backupJson = $backup | ConvertTo-Json -Depth 4
        Set-Content -Path $Global:AdZConfig.System.BackupFile -Value $backupJson -Encoding UTF8
        
        Write-AdZLog "Sauvegarde créée: $($Global:AdZConfig.System.BackupFile)" "SUCCESS"
        return $true
        
    } catch {
        Write-AdZLog "Erreur sauvegarde DNS: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Restore-DNSFromBackup {
    param([bool]$RestoreToDefault = $false)
    
    try {
        if ($RestoreToDefault) {
            Write-AdZLog "Restauration DNS par défaut (DHCP)..." "INFO"
            
            $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            $successCount = 0
            
            foreach ($adapter in $adapters) {
                $name = $adapter.Description
                try {
                    Write-AdZLog "Restauration DHCP: $name" "INFO"
                    
                    netsh interface ipv4 set dnsservers name="$name" dhcp | Out-Null
                    netsh interface ipv6 set dnsservers name="$name" dhcp | Out-Null
                    
                    $successCount++
                    Write-AdZLog "DHCP appliqué: $name" "SUCCESS"
                    
                } catch {
                    Write-AdZLog "Erreur DHCP $name : $($_.Exception.Message)" "ERROR"
                }
            }
            
            if ($successCount -gt 0) {
                ipconfig /flushdns | Out-Null
                Write-AdZLog "DNS restaurés par défaut ($successCount adapters)" "SUCCESS"
                return $true
            }
            
            return $false
        }
        
        # Restauration depuis sauvegarde
        if (-not (Test-Path $Global:AdZConfig.System.BackupFile)) {
            Write-AdZLog "Aucune sauvegarde trouvée" "WARNING"
            return $false
        }
        
        $backupContent = Get-Content $Global:AdZConfig.System.BackupFile -Raw
        $backup = $backupContent | ConvertFrom-Json
        
        Write-AdZLog "Restauration depuis sauvegarde du $($backup.Timestamp)" "INFO"
        
        $successCount = 0
        foreach ($adapterBackup in $backup.Adapters) {
            $name = $adapterBackup.Description
            
            try {
                Write-AdZLog "Restauration: $name" "INFO"
                
                # IPv4
                if ($adapterBackup.DNSServerSearchOrder -and $adapterBackup.DNSServerSearchOrder.Count -gt 0) {
                    netsh interface ipv4 set dnsservers name="$name" static $($adapterBackup.DNSServerSearchOrder[0]) primary | Out-Null
                    
                    for ($i = 1; $i -lt $adapterBackup.DNSServerSearchOrder.Count; $i++) {
                        netsh interface ipv4 add dnsservers name="$name" $($adapterBackup.DNSServerSearchOrder[$i]) index=$($i + 1) | Out-Null
                    }
                }
                
                # IPv6
                if ($adapterBackup.DNSServerSearchOrderIPv6 -and $adapterBackup.DNSServerSearchOrderIPv6.Count -gt 0) {
                    netsh interface ipv6 set dnsservers name="$name" static $($adapterBackup.DNSServerSearchOrderIPv6[0]) primary | Out-Null
                    
                    for ($i = 1; $i -lt $adapterBackup.DNSServerSearchOrderIPv6.Count; $i++) {
                        netsh interface ipv6 add dnsservers name="$name" $($adapterBackup.DNSServerSearchOrderIPv6[$i]) index=$($i + 1) | Out-Null
                    }
                }
                
                $successCount++
                Write-AdZLog "DNS restaurés: $name" "SUCCESS"
                
            } catch {
                Write-AdZLog "Erreur restauration $name : $($_.Exception.Message)" "ERROR"
            }
        }
        
        if ($successCount -gt 0) {
            ipconfig /flushdns | Out-Null
            Write-AdZLog "Restauration terminée ($successCount adapters)" "SUCCESS"
            return $true
        }
        
        return $false
        
    } catch {
        Write-AdZLog "Erreur critique restauration: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# === FONCTIONS INTERFACE UTILISATEUR ===
function Update-StatusDisplay {
    param(
        [string]$Message,
        [ValidateSet("INFO","SUCCESS","WARNING","ERROR")]$Type = "INFO",
        [switch]$Append
    )
    
    if (-not $Global:StatusTextBox) { return }
    
    $color = switch($Type) {
        "SUCCESS" { $Global:Colors.Success }
        "WARNING" { $Global:Colors.Warning }
        "ERROR" { $Global:Colors.Error }
        default { $Global:Colors.Terminal }
    }
    
    if (-not $Append) {
        $Global:StatusTextBox.Clear()
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $fullMessage = "$timestamp - $Message`r`n"
    
    $Global:StatusTextBox.SelectionStart = $Global:StatusTextBox.TextLength
    $Global:StatusTextBox.SelectionColor = $color
    $Global:StatusTextBox.AppendText($fullMessage)
    $Global:StatusTextBox.ScrollToCaret()
    
    Write-AdZLog $Message $Type
    [System.Windows.Forms.Application]::DoEvents()
}

function Show-ProgressAnimation {
    param([string]$Message, [int]$DurationSeconds = 3)
    
    if (-not $Global:ProgressBar) { return }
    
    Update-StatusDisplay $Message "INFO" -Append
    
    $Global:ProgressBar.Visible = $true
    $Global:ProgressBar.Value = 0
    
    $steps = 50
    $stepDelay = [Math]::Max(20, ($DurationSeconds * 1000) / $steps)
    
    for ($i = 0; $i -le $steps; $i++) {
        $Global:ProgressBar.Value = [Math]::Min(100, ($i * 100) / $steps)
        Start-Sleep -Milliseconds $stepDelay
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    $Global:ProgressBar.Visible = $false
}

# === FONCTIONS PRINCIPALES DNS ===
function Install-AdZvancedDNS {
    try {
        Write-AdZLog "=== DÉBUT INSTALLATION DNS AdZ-Vanced ===" "INFO"
        
        $Global:InstallButton.Enabled = $false
        $Global:RestoreButton.Enabled = $false
        
        # Phase 1: Validation connectivité
        Update-StatusDisplay "🌐 Vérification de la connectivité Internet..." "INFO"
        if (-not (Test-InternetConnectivity)) {
            Update-StatusDisplay "❌ Pas de connexion Internet détectée" "ERROR" -Append
            Update-StatusDisplay "🔧 Vérifiez votre connexion et réessayez" "WARNING" -Append
            return $false
        }
        
        Show-ProgressAnimation "🔍 Validation des serveurs DNS AdZ-Vanced..." 2
        
        # Test des serveurs DNS
        $dnsTests = @(
            @{ Server = $Global:AdZConfig.DNS.IPv4_Primary; Name = "DNS Primaire" },
            @{ Server = $Global:AdZConfig.DNS.IPv4_Secondary; Name = "DNS Secondaire" }
        )
        
        $validDNS = 0
        foreach ($test in $dnsTests) {
            if (Test-DNSServer $test.Server) {
                Update-StatusDisplay "✅ $($test.Name) ($($test.Server)): Accessible" "SUCCESS" -Append
                $validDNS++
            } else {
                Update-StatusDisplay "⚠️ $($test.Name) ($($test.Server)): Non accessible" "WARNING" -Append
            }
        }
        
        if ($validDNS -eq 0) {
            Update-StatusDisplay "❌ Aucun serveur DNS AdZ-Vanced accessible" "ERROR" -Append
            Update-StatusDisplay "🌐 Vérifiez votre pare-feu ou connexion" "WARNING" -Append
            return $false
        }
        
        # Phase 2: IP publique
        Show-ProgressAnimation "🌍 Détection de votre adresse IP publique..." 2
        $publicIP = Get-PublicIP
        Update-StatusDisplay "🌍 Adresse IP publique: $publicIP" "INFO" -Append
        
        # Phase 3: Sauvegarde
        Show-ProgressAnimation "💾 Sauvegarde de vos paramètres actuels..." 2
        if (-not (Backup-CurrentDNSSettings)) {
            Update-StatusDisplay "⚠️ Impossible de sauvegarder (continuons quand même)" "WARNING" -Append
        } else {
            Update-StatusDisplay "✅ Paramètres actuels sauvegardés" "SUCCESS" -Append
        }
        
        # Phase 4: Configuration DNS
        Show-ProgressAnimation "🛡️ Configuration des cartes réseau..." 4
        
        $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        $configuredCount = 0
        $totalCount = $adapters.Count
        
        Update-StatusDisplay "📡 $totalCount carte(s) réseau détectée(s)" "INFO" -Append
        
        foreach ($adapter in $adapters) {
            $name = $adapter.Description
            Update-StatusDisplay "⚙️ Configuration: $name" "INFO" -Append
            
            try {
                # Configuration IPv4
                netsh interface ipv4 set dnsservers name="$name" static $($Global:AdZConfig.DNS.IPv4_Primary) primary | Out-Null
                netsh interface ipv4 add dnsservers name="$name" $($Global:AdZConfig.DNS.IPv4_Secondary) index=2 | Out-Null
                
                # Configuration IPv6
                try {
                    netsh interface ipv6 set dnsservers name="$name" static $($Global:AdZConfig.DNS.IPv6_Primary) primary | Out-Null
                    netsh interface ipv6 add dnsservers name="$name" $($Global:AdZConfig.DNS.IPv6_Secondary) index=2 | Out-Null
                    Update-StatusDisplay "   ✅ DNS IPv4 + IPv6 configurés" "SUCCESS" -Append
                } catch {
                    Update-StatusDisplay "   ✅ DNS IPv4 configuré (IPv6 ignoré)" "SUCCESS" -Append
                }
                
                $configuredCount++
                
            } catch {
                Update-StatusDisplay "   ❌ Erreur configuration: $($_.Exception.Message)" "ERROR" -Append
                Write-AdZLog "Erreur config adapter $name : $($_.Exception.Message)" "ERROR"
            }
        }
        
        # Phase 5: Finalisation
        Show-ProgressAnimation "🔄 Actualisation du cache DNS..." 2
        
        try {
            ipconfig /flushdns | Out-Null
            Update-StatusDisplay "🔄 Cache DNS vidé" "SUCCESS" -Append
        } catch {
            Update-StatusDisplay "⚠️ Impossible de vider le cache DNS" "WARNING" -Append
        }
        
        # Résultat final
        if ($configuredCount -gt 0) {
            Update-StatusDisplay "🎉 CONFIGURATION RÉUSSIE !" "SUCCESS" -Append
            Update-StatusDisplay "📊 $configuredCount/$totalCount carte(s) configurée(s)" "SUCCESS" -Append
            Update-StatusDisplay "🚀 Profitez d'une navigation saine et rapide !" "SUCCESS" -Append
            Update-StatusDisplay "🛡️ Publicités bloquées • Vie privée protégée" "INFO" -Append
            
            # Afficher boutons finaux
            $Global:FinalButtonsPanel.Visible = $true
            
            Write-AdZLog "Installation DNS AdZ-Vanced réussie ($configuredCount/$totalCount)" "SUCCESS"
            return $true
            
        } else {
            Update-StatusDisplay "❌ Aucune carte réseau n'a pu être configurée" "ERROR" -Append
            Update-StatusDisplay "🔧 Essayez de relancer en tant qu'administrateur" "WARNING" -Append
            return $false
        }
        
    } catch {
        Update-StatusDisplay "❌ Erreur critique: $($_.Exception.Message)" "ERROR" -Append
        Write-AdZLog "Erreur critique Install-AdZvancedDNS: $($_.Exception.Message)" "ERROR"
        return $false
        
    } finally {
        $Global:InstallButton.Enabled = $true
        $Global:RestoreButton.Enabled = $true
    }
}

function Restore-DefaultDNS {
    try {
        Write-AdZLog "=== DÉBUT RESTAURATION DNS ===" "INFO"
        
        $Global:InstallButton.Enabled = $false
        $Global:RestoreButton.Enabled = $false
        
        Update-StatusDisplay "🔄 Restauration des paramètres DNS par défaut..." "INFO"
        
        Show-ProgressAnimation "🔧 Restauration en cours..." 3
        
        $success = Restore-DNSFromBackup -RestoreToDefault $true
        
        if ($success) {
            Update-StatusDisplay "✅ DNS restaurés par défaut (DHCP)" "SUCCESS" -Append
            Update-StatusDisplay "📶 Retour aux serveurs de votre FAI" "INFO" -Append
            Update-StatusDisplay "🔄 Cache DNS vidé" "SUCCESS" -Append
            Update-StatusDisplay "ℹ️ Configuration réseau d'origine restaurée" "INFO" -Append
            
            # Afficher boutons finaux
            $Global:FinalButtonsPanel.Visible = $true
            
            Write-AdZLog "Restauration DNS réussie" "SUCCESS"
        } else {
            Update-StatusDisplay "❌ Erreur lors de la restauration" "ERROR" -Append
            Update-StatusDisplay "🔧 Essayez de relancer en tant qu'administrateur" "WARNING" -Append
        }
        
        return $success
        
    } catch {
        Update-StatusDisplay "❌ Erreur critique: $($_.Exception.Message)" "ERROR" -Append
        Write-AdZLog "Erreur critique Restore-DefaultDNS: $($_.Exception.Message)" "ERROR"
        return $false
        
    } finally {
        $Global:InstallButton.Enabled = $true
        $Global:RestoreButton.Enabled = $true
    }
}

# === CHARGEMENT LOGO ===
function Load-AdZvancedLogo {
    try {
        Write-AdZLog "Téléchargement du logo AdZ-Vanced..." "INFO"
        
        if (Test-InternetConnectivity) {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "AdZ-Vanced/1.0")
            $webClient.DownloadFile($Global:AdZConfig.URLs.Logo, $Global:AdZConfig.System.TempLogo)
            
            $fileInfo = Get-Item $Global:AdZConfig.System.TempLogo
            if ($fileInfo.Length -gt 5000) {
                Write-AdZLog "Logo téléchargé avec succès ($($fileInfo.Length) bytes)" "SUCCESS"
                return $Global:AdZConfig.System.TempLogo
            } else {
                Write-AdZLog "Fichier logo trop petit, utilisation du fallback" "WARNING"
                Remove-Item $Global:AdZConfig.System.TempLogo -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-AdZLog "Pas de connexion Internet pour le logo" "WARNING"
        }
    } catch {
        Write-AdZLog "Erreur téléchargement logo: $($_.Exception.Message)" "WARNING"
    }
    
    return $null
}

# === INTERFACE GRAPHIQUE PRINCIPALE ===
Write-AdZLog "=== DÉMARRAGE AdZ-Vanced v$($Global:AdZConfig.Version) ===" "INFO" -ShowConsole
Write-AdZLog "Build: $($Global:AdZConfig.Build) | Arch: $($OSInfo.Architecture) | OS: $($OSInfo.ProductName)" "INFO"

# Fenêtre principale
$Global:MainForm = New-Object System.Windows.Forms.Form
$Global:MainForm.Text = "$($Global:AdZConfig.AppName) v$($Global:AdZConfig.Version) - Configuration DNS Professionnelle"
$Global:MainForm.Size = New-Object System.Drawing.Size(700, 800)
$Global:MainForm.StartPosition = "CenterScreen"
$Global:MainForm.FormBorderStyle = "FixedDialog"
$Global:MainForm.MaximizeBox = $false
$Global:MainForm.BackColor = $Global:Colors.Background
$Global:MainForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Icône de l'application
try {
    $iconPath = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $Global:MainForm.Icon = $iconPath
} catch {
    Write-AdZLog "Impossible de charger l'icône de l'application" "DEBUG"
}

# Panel principal avec fond blanc
$mainPanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(670, 770)) -Location (New-Object System.Drawing.Point(15, 15))
$Global:MainForm.Controls.Add($mainPanel)

# === HEADER DÉGRADÉ PREMIUM ===
$headerPanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(670, 120)) -Location (New-Object System.Drawing.Point(0, 0)) -BackColor $Global:Colors.Primary
$mainPanel.Controls.Add($headerPanel)

# Titre principal avec effet premium
$titleLabel = New-PremiumLabel -Text $Global:AdZConfig.AppName -Size (New-Object System.Drawing.Size(670, 50)) -Location (New-Object System.Drawing.Point(0, 25)) -ForeColor $Global:Colors.TextOnPrimary -FontSize 28 -FontStyle Bold -TextAlign MiddleCenter
$headerPanel.Controls.Add($titleLabel)

# Version avec style élégant
$versionLabel = New-PremiumLabel -Text "v$($Global:AdZConfig.Version)" -Size (New-Object System.Drawing.Size(670, 20)) -Location (New-Object System.Drawing.Point(0, 75)) -ForeColor $Global:Colors.PrimaryLight -FontSize 12 -TextAlign MiddleCenter
$headerPanel.Controls.Add($versionLabel)

# Build info (coin supérieur droit)
$buildLabel = New-PremiumLabel -Text "Build $($Global:AdZConfig.Build)" -Size (New-Object System.Drawing.Size(150, 15)) -Location (New-Object System.Drawing.Point(510, 10)) -ForeColor $Global:Colors.PrimaryLight -FontSize 8 -TextAlign MiddleRight
$headerPanel.Controls.Add($buildLabel)

# Système info (coin supérieur gauche)
$sysLabel = New-PremiumLabel -Text "$($OSInfo.Architecture)" -Size (New-Object System.Drawing.Size(100, 15)) -Location (New-Object System.Drawing.Point(10, 10)) -ForeColor $Global:Colors.PrimaryLight -FontSize 8
$headerPanel.Controls.Add($sysLabel)

# === ZONE LOGO PREMIUM ===
$logoContainer = New-PremiumPanel -Size (New-Object System.Drawing.Size(240, 180)) -Location (New-Object System.Drawing.Point(215, 140))
$mainPanel.Controls.Add($logoContainer)

# Chargement du logo
$logoPath = Load-AdZvancedLogo

if ($logoPath -and (Test-Path $logoPath)) {
    try {
        $logoImage = New-Object System.Windows.Forms.PictureBox
        $logoImage.Image = [System.Drawing.Image]::FromFile($logoPath)
        $logoImage.SizeMode = 'StretchImage'
        $logoImage.Size = New-Object System.Drawing.Size(220, 160)
        $logoImage.Location = New-Object System.Drawing.Point(10, 10)
        $logoContainer.Controls.Add($logoImage)
        Write-AdZLog "Logo AdZ-Vanced affiché avec succès" "SUCCESS"
    } catch {
        Write-AdZLog "Erreur affichage logo: $($_.Exception.Message)" "WARNING"
        $logoPath = $null
    }
}

# Logo de fallback si nécessaire
if (-not $logoPath) {
    $logoFallback = New-PremiumLabel -Text "🛡️`nAdZ-Vanced`nLogo" -Size (New-Object System.Drawing.Size(220, 160)) -Location (New-Object System.Drawing.Point(10, 10)) -ForeColor $Global:Colors.Primary -FontSize 18 -FontStyle Bold -TextAlign MiddleCenter
    $logoFallback.BackColor = $Global:Colors.SurfaceElevated
    $logoContainer.Controls.Add($logoFallback)
}

# === MESSAGE MARKETING PREMIUM ===
$messagePanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(630, 90)) -Location (New-Object System.Drawing.Point(20, 340)) -BackColor $Global:Colors.SurfaceElevated
$mainPanel.Controls.Add($messagePanel)

$messageIcon = New-PremiumLabel -Text "🛡️" -Size (New-Object System.Drawing.Size(30, 30)) -Location (New-Object System.Drawing.Point(15, 15)) -ForeColor $Global:Colors.Primary -FontSize 20 -TextAlign MiddleCenter
$messagePanel.Controls.Add($messageIcon)

$messageTitle = New-PremiumLabel -Text "Navigation Sécurisée AdZ-Vanced" -Size (New-Object System.Drawing.Size(570, 25)) -Location (New-Object System.Drawing.Point(50, 15)) -ForeColor $Global:Colors.Primary -FontSize 14 -FontStyle Bold
$messagePanel.Controls.Add($messageTitle)

$messageText = New-PremiumLabel -Text "Grâce à AdZ-Vanced, vous allez enfin pouvoir profiter d'un surf sain et rapide. Pas de pub, pas de données personnelles qui fuitent et vive le contournement imposé par les FAI." -Size (New-Object System.Drawing.Size(570, 40)) -Location (New-Object System.Drawing.Point(50, 45)) -ForeColor $Global:Colors.TextSecondary -FontSize 10 -TextAlign MiddleLeft
$messagePanel.Controls.Add($messageText)

# === BOUTONS PRINCIPAUX PREMIUM ===
$buttonsPanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(630, 80)) -Location (New-Object System.Drawing.Point(20, 450)) -BackColor $Global:Colors.Surface
$mainPanel.Controls.Add($buttonsPanel)

# Bouton Installation (Premium Violet)
$Global:InstallButton = New-PremiumButton -Text "🚀 INSTALLER DNS AdZ-Vanced" -Size (New-Object System.Drawing.Size(300, 55)) -Location (New-Object System.Drawing.Point(20, 15)) -BackColor $Global:Colors.Primary -FontSize 13
$buttonsPanel.Controls.Add($Global:InstallButton)

# Bouton Restauration (Premium Gris)
$Global:RestoreButton = New-PremiumButton -Text "🔄 RESTAURER DNS PAR DÉFAUT" -Size (New-Object System.Drawing.Size(300, 55)) -Location (New-Object System.Drawing.Point(340, 15)) -BackColor $Global:Colors.TextSecondary -FontSize 13
$buttonsPanel.Controls.Add($Global:RestoreButton)

# === ZONE STATUT PREMIUM ===
$statusPanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(630, 200)) -Location (New-Object System.Drawing.Point(20, 550)) -BackColor $Global:Colors.Surface
$mainPanel.Controls.Add($statusPanel)

$statusTitle = New-PremiumLabel -Text "📋 Journal des opérations en temps réel" -Size (New-Object System.Drawing.Size(400, 25)) -Location (New-Object System.Drawing.Point(20, 15)) -ForeColor $Global:Colors.TextPrimary -FontSize 12 -FontStyle Bold
$statusPanel.Controls.Add($statusTitle)

# TextBox terminal style premium
$Global:StatusTextBox = New-Object System.Windows.Forms.RichTextBox
$Global:StatusTextBox.Size = New-Object System.Drawing.Size(590, 150)
$Global:StatusTextBox.Location = New-Object System.Drawing.Point(20, 45)
$Global:StatusTextBox.ReadOnly = $true
$Global:StatusTextBox.BackColor = $Global:Colors.TerminalBg
$Global:StatusTextBox.ForeColor = $Global:Colors.Terminal
$Global:StatusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
$Global:StatusTextBox.ScrollBars = "Vertical"
$Global:StatusTextBox.WordWrap = $true
$Global:StatusTextBox.Text = "AdZ-Vanced v$($Global:AdZConfig.Version) initialisé avec succès`r`n`r`nÉtat du système:`r`n• OS: $($OSInfo.ProductName) ($($OSInfo.Architecture))`r`n• PowerShell: $($PSVersionTable.PSVersion)`r`n• Privilèges: Administrateur ✓`r`n`r`nPrêt pour la configuration DNS !`r`n`r`nCliquez sur 'INSTALLER DNS' pour activer la protection AdZ-Vanced`r`nou sur 'RESTAURER DNS' pour revenir aux paramètres FAI."
$statusPanel.Controls.Add($Global:StatusTextBox)

# === BARRE DE PROGRESSION PREMIUM ===
$Global:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$Global:ProgressBar.Size = New-Object System.Drawing.Size(630, 8)
$Global:ProgressBar.Location = New-Object System.Drawing.Point(20, 760)
$Global:ProgressBar.Style = 'Continuous'
$Global:ProgressBar.ForeColor = $Global:Colors.Primary
$Global:ProgressBar.BackColor = $Global:Colors.PrimaryLight
$Global:ProgressBar.Visible = $false
$mainPanel.Controls.Add($Global:ProgressBar)

# === BOUTONS FINAUX PREMIUM (cachés initialement) ===
$Global:FinalButtonsPanel = New-PremiumPanel -Size (New-Object System.Drawing.Size(630, 45)) -Location (New-Object System.Drawing.Point(20, 775)) -BackColor $Global:Colors.Surface
$Global:FinalButtonsPanel.Visible = $false
$mainPanel.Controls.Add($Global:FinalButtonsPanel)

$donationButton = New-PremiumButton -Text "💝 Donation" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(20, 5)) -BackColor $Global:Colors.Primary -FontSize 10
$Global:FinalButtonsPanel.Controls.Add($donationButton)

$telegramButton = New-PremiumButton -Text "📱 Telegram" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(170, 5)) -BackColor $Global:Colors.Primary -FontSize 10
$Global:FinalButtonsPanel.Controls.Add($telegramButton)

$backupButton = New-PremiumButton -Text "💾 Sauvegarde" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(320, 5)) -BackColor $Global:Colors.Info -FontSize 10
$Global:FinalButtonsPanel.Controls.Add($backupButton)

$closeButton = New-PremiumButton -Text "❌ Fermer" -Size (New-Object System.Drawing.Size(140, 35)) -Location (New-Object System.Drawing.Point(470, 5)) -BackColor $Global:Colors.Error -FontSize 10
$Global:FinalButtonsPanel.Controls.Add($closeButton)

# === ÉVÉNEMENTS INTERFACE ===

# Installation DNS
$Global:InstallButton.Add_Click({
    try {
        Install-AdZvancedDNS
    } catch {
        Write-AdZLog "Erreur événement installation: $($_.Exception.Message)" "ERROR"
        Update-StatusDisplay "Erreur inattendue lors de l'installation" "ERROR"
    }
})

# Restauration DNS  
$Global:RestoreButton.Add_Click({
    try {
        Restore-DefaultDNS
    } catch {
        Write-AdZLog "Erreur événement restauration: $($_.Exception.Message)" "ERROR"
        Update-StatusDisplay "Erreur inattendue lors de la restauration" "ERROR"
    }
})

# Donation
$donationButton.Add_Click({
    try {
        $donationForm = New-Object System.Windows.Forms.Form
        $donationForm.Text = "💝 Soutenir AdZ-Vanced"
        $donationForm.Size = New-Object System.Drawing.Size(420, 250)
        $donationForm.StartPosition = "CenterParent"
        $donationForm.FormBorderStyle = "FixedDialog"
        $donationForm.MaximizeBox = $false
        $donationForm.BackColor = $Global:Colors.Surface
        
        $donTitle = New-PremiumLabel -Text "Soutenez le développement d'AdZ-Vanced" -Size (New-Object System.Drawing.Size(400, 30)) -Location (New-Object System.Drawing.Point(10, 20)) -ForeColor $Global:Colors.Primary -FontSize 12 -FontStyle Bold -TextAlign MiddleCenter
        $donationForm.Controls.Add($donTitle)
        
        $paypalBtn = New-PremiumButton -Text "💳 PayPal" -Size (New-Object System.Drawing.Size(350, 40)) -Location (New-Object System.Drawing.Point(35, 60)) -BackColor $Global:Colors.Info
        $paypalBtn.Add_Click({ Start-Process $Global:AdZConfig.URLs.PayPal })
        $donationForm.Controls.Add($paypalBtn)
        
        $tipeeeBtn = New-PremiumButton -Text "☕ Tipeee" -Size (New-Object System.Drawing.Size(350, 40)) -Location (New-Object System.Drawing.Point(35, 110)) -BackColor $Global:Colors.Success
        $tipeeeBtn.Add_Click({ Start-Process $Global:AdZConfig.URLs.Tipeee })
        $donationForm.Controls.Add($tipeeeBtn)
        
        $closeDonBtn = New-PremiumButton -Text "🔙 Retour" -Size (New-Object System.Drawing.Size(350, 40)) -Location (New-Object System.Drawing.Point(35, 160)) -BackColor $Global:Colors.TextSecondary
        $closeDonBtn.Add_Click({ $donationForm.Close() })
        $donationForm.Controls.Add($closeDonBtn)
        
        Write-AdZLog "Ouverture fenêtre donation" "INFO"
        $donationForm.ShowDialog($Global:MainForm) | Out-Null
        
    } catch {
        Write-AdZLog "Erreur donation: $($_.Exception.Message)" "ERROR"
    }
})

# Telegram
$telegramButton.Add_Click({
    try {
        Write-AdZLog "Ouverture Telegram AdZ-Vanced" "INFO"
        Start-Process $Global:AdZConfig.URLs.Telegram
    } catch {
        Write-AdZLog "Erreur ouverture Telegram: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir Telegram. URL: $($Global:AdZConfig.URLs.Telegram)", "Erreur", "OK", "Warning")
    }
})

# Sauvegarde
$backupButton.Add_Click({
    try {
        if (Test-Path $Global:AdZConfig.System.BackupFile) {
            $backupContent = Get-Content $Global:AdZConfig.System.BackupFile -Raw | ConvertFrom-Json
            $message = "Sauvegarde disponible du $($backupContent.Timestamp)`n`nSystème: $($backupContent.System)`nCartes réseau: $($backupContent.Adapters.Count)`n`nVoulez-vous restaurer cette sauvegarde ?"
            
            $result = [System.Windows.Forms.MessageBox]::Show($message, "Restaurer sauvegarde", "YesNo", "Question")
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-AdZLog "Restauration sauvegarde demandée par utilisateur" "INFO"
                
                $Global:InstallButton.Enabled = $false
                $Global:RestoreButton.Enabled = $false
                
                Update-StatusDisplay "🔄 Restauration depuis sauvegarde..." "INFO"
                $success = Restore-DNSFromBackup
                
                if ($success) {
                    Update-StatusDisplay "✅ Sauvegarde restaurée avec succès" "SUCCESS" -Append
                } else {
                    Update-StatusDisplay "❌ Échec restauration sauvegarde" "ERROR" -Append
                }
                
                $Global:InstallButton.Enabled = $true
                $Global:RestoreButton.Enabled = $true
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Aucune sauvegarde DNS disponible.`n`nUne sauvegarde est créée automatiquement lors de l'installation d'AdZ-Vanced.", "Pas de sauvegarde", "OK", "Information")
        }
    } catch {
        Write-AdZLog "Erreur sauvegarde: $($_.Exception.Message)" "ERROR"
    }
})

# Informations
$infoButton = New-PremiumButton -Text "ℹ️ Infos" -Size (New-Object System.Drawing.Size(100, 25)) -Location (New-Object System.Drawing.Point(550, 15)) -BackColor $Global:Colors.Info -FontSize 9
$statusPanel.Controls.Add($infoButton)

$infoButton.Add_Click({
    try {
        $infoText = @"
AdZ-Vanced v$($Global:AdZConfig.Version) - Configuration DNS Professionnelle

🛡️ SERVEURS DNS AdZ-Vanced:
• IPv4 Primaire: $($Global:AdZConfig.DNS.IPv4_Primary)
• IPv4 Secondaire: $($Global:AdZConfig.DNS.IPv4_Secondary)
• IPv6 Primaire: $($Global:AdZConfig.DNS.IPv6_Primary)
• IPv6 Secondaire: $($Global:AdZConfig.DNS.IPv6_Secondary)

🎯 AVANTAGES:
• Blocage automatique des publicités
• Protection de la vie privée
• Navigation plus rapide
• Contournement restrictions FAI
• Sécurité renforcée

💻 COMPATIBILITÉ:
• Windows 7, 8, 10, 11 (x86/x64)
• Toutes cartes réseau Ethernet/WiFi
• IPv4 et IPv6 supportés

🔧 SYSTÈME DÉTECTÉ:
• OS: $($OSInfo.ProductName)
• Architecture: $($OSInfo.Architecture)
• Version: $($OSInfo.Version)

© 2025 KontacktzBot - Tous droits réservés
Build: $($Global:AdZConfig.Build)
"@
        
        [System.Windows.Forms.MessageBox]::Show($infoText, "Informations AdZ-Vanced v$($Global:AdZConfig.Version)", "OK", "Information")
        Write-AdZLog "Affichage informations système" "INFO"
        
    } catch {
        Write-AdZLog "Erreur informations: $($_.Exception.Message)" "ERROR"
    }
})

# Fermeture
$closeButton.Add_Click({
    Write-AdZLog "Fermeture demandée par utilisateur" "INFO"
    $Global:MainForm.Close()
})

# Fermeture propre
$Global:MainForm.Add_FormClosing({
    Write-AdZLog "=== ARRÊT AdZ-Vanced ===" "INFO"
    
    # Nettoyage fichiers temporaires
    try {
        if ($Global:AdZConfig.System.TempLogo -and (Test-Path $Global:AdZConfig.System.TempLogo)) {
            Remove-Item $Global:AdZConfig.System.TempLogo -Force -ErrorAction SilentlyContinue
            Write-AdZLog "Fichiers temporaires nettoyés" "INFO"
        }
    } catch {
        Write-AdZLog "Erreur nettoyage: $($_.Exception.Message)" "DEBUG"
    }
    
    Write-AdZLog "AdZ-Vanced fermé proprement" "SUCCESS"
})

# === DÉMARRAGE APPLICATION ===
Write-AdZLog "Interface graphique initialisée avec succès" "SUCCESS"

# Configuration finale fenêtre
$Global:MainForm.TopMost = $true
$Global:MainForm.Add_Shown({ 
    $Global:MainForm.Activate()
    $Global:MainForm.TopMost = $false
    Write-AdZLog "AdZ-Vanced prêt à l'utilisation" "SUCCESS"
})

# Affichage
Write-AdZLog "Lancement interface utilisateur..." "INFO"
[void]$Global:MainForm.ShowDialog()

# Nettoyage final
Write-AdZLog "=== FIN AdZ-Vanced v$($Global:AdZConfig.Version) ===" "INFO" -ShowConsole