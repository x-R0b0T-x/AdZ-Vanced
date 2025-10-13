# ================================================================
# Compilateur Universel AdZ-Vanced v1.0
# Compatible Windows 7-11 | x86/x64 | Distribution Professionnelle
# © 2025 KontacktzBot
# ================================================================

param(
    [switch]$Install,
    [switch]$CompileWindows,
    [switch]$All,
    [switch]$Clean,
    [string]$OutputDir = ".\dist"
)

$ErrorActionPreference = "Stop"

# === CONFIGURATION COMPILATION ===
$CompileConfig = @{
    AppName = "AdZ-Vanced"
    Version = "1.0.0.0"
    Publisher = "KontacktzBot"
    Copyright = "© 2025 KontacktzBot. Tous droits réservés."
    Description = "Configuration DNS professionnelle AdZ-Vanced - Navigation saine et rapide"
    
    # Fichiers source
    SourceScript = ".\AdZ-Vanced_Windows_v1.0_Pro.ps1"
    
    # Architectures supportées
    Architectures = @("x86", "x64")
    
    # Compatibilité Windows
    MinWindows = "Windows 7"
    MaxWindows = "Windows 11"
}

Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "    COMPILATEUR UNIVERSEL AdZ-Vanced v1.0" -ForegroundColor Magenta
Write-Host "    Compatible $($CompileConfig.MinWindows) → $($CompileConfig.MaxWindows)" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""

# === DÉTECTION SYSTÈME ===
$SystemInfo = @{
    OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    Architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    DotNetVersion = [System.Environment]::Version.ToString()
}

Write-Host "🖥️  SYSTÈME DÉTECTÉ:" -ForegroundColor Cyan
Write-Host "   OS: $($SystemInfo.OS)" -ForegroundColor White
Write-Host "   Architecture: $($SystemInfo.Architecture)" -ForegroundColor White
Write-Host "   PowerShell: $($SystemInfo.PowerShellVersion)" -ForegroundColor White
Write-Host "   .NET Framework: $($SystemInfo.DotNetVersion)" -ForegroundColor White
Write-Host ""

# === NETTOYAGE ===
if ($Clean) {
    Write-Host "🧹 NETTOYAGE..." -ForegroundColor Yellow
    
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force
        Write-Host "✅ Dossier de sortie nettoyé" -ForegroundColor Green
    }
    
    $tempFiles = @(
        ".\*.exe",
        ".\adzvanced_logo*.jpg",
        ".\AdZvanced*.log"
    )
    
    foreach ($pattern in $tempFiles) {
        Get-ChildItem $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    Write-Host "✅ Fichiers temporaires nettoyés" -ForegroundColor Green
    Write-Host ""
}

# === INSTALLATION OUTILS ===
if ($Install -or $All) {
    Write-Host "🔧 INSTALLATION DES OUTILS DE COMPILATION..." -ForegroundColor Yellow
    Write-Host ""
    
    # Vérification PS2EXE
    try {
        $ps2exe = Get-Module -ListAvailable -Name PS2EXE
        
        if (-not $ps2exe) {
            Write-Host "📦 Installation de PS2EXE..." -ForegroundColor Cyan
            
            # Installation avec retry
            $retryCount = 0
            do {
                try {
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                    Install-Module PS2EXE -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck
                    Import-Module PS2EXE -Force
                    break
                } catch {
                    $retryCount++
                    if ($retryCount -ge 3) {
                        throw "Impossible d'installer PS2EXE après 3 tentatives"
                    }
                    Write-Host "⚠️  Tentative $retryCount échouée, retry..." -ForegroundColor Yellow
                    Start-Sleep 2
                }
            } while ($retryCount -lt 3)
            
            Write-Host "✅ PS2EXE installé avec succès" -ForegroundColor Green
            
        } else {
            Write-Host "✅ PS2EXE déjà installé (v$($ps2exe.Version))" -ForegroundColor Green
            Import-Module PS2EXE -Force
        }
        
        # Vérification installation
        $ps2exeCmd = Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue
        if (-not $ps2exeCmd) {
            throw "PS2EXE non disponible après installation"
        }
        
        Write-Host "✅ Outils de compilation prêts" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "❌ ERREUR INSTALLATION OUTILS:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 SOLUTIONS:" -ForegroundColor Yellow
        Write-Host "1. Exécutez PowerShell en tant qu'Administrateur" -ForegroundColor White
        Write-Host "2. Activez l'exécution de scripts: Set-ExecutionPolicy RemoteSigned" -ForegroundColor White
        Write-Host "3. Vérifiez votre connexion Internet" -ForegroundColor White
        exit 1
    }
}

# === COMPILATION WINDOWS ===
if ($CompileWindows -or $All) {
    Write-Host "🚀 COMPILATION AdZ-Vanced WINDOWS..." -ForegroundColor Yellow
    Write-Host ""
    
    # Vérification fichier source
    if (-not (Test-Path $CompileConfig.SourceScript)) {
        Write-Host "❌ Fichier source non trouvé: $($CompileConfig.SourceScript)" -ForegroundColor Red
        Write-Host "📁 Assurez-vous que le script PowerShell est dans le même dossier" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "📄 Script source: $($CompileConfig.SourceScript)" -ForegroundColor Green
    $sourceSize = [Math]::Round((Get-Item $CompileConfig.SourceScript).Length / 1KB, 1)
    Write-Host "📏 Taille source: $sourceSize KB" -ForegroundColor Green
    Write-Host ""
    
    # Création dossier de sortie
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        Write-Host "📁 Dossier créé: $OutputDir" -ForegroundColor Green
    }
    
    # Compilation pour chaque architecture
    foreach ($arch in $CompileConfig.Architectures) {
        Write-Host "⚙️  COMPILATION $arch..." -ForegroundColor Cyan
        
        $outputFile = Join-Path $OutputDir "$($CompileConfig.AppName)_v1.0_Windows_$arch.exe"
        $iconFile = ".\adzvanced.ico"
        
        try {
            # Paramètres de compilation optimisés
            $compileParams = @{
                InputFile = $CompileConfig.SourceScript
                OutputFile = $outputFile
                NoConsole = $true
                RequireAdmin = $true
                x64 = ($arch -eq "x64")
                
                # Métadonnées
                Title = "$($CompileConfig.AppName) v1.0"
                Description = $CompileConfig.Description
                Company = $CompileConfig.Publisher
                Product = $CompileConfig.AppName
                Copyright = $CompileConfig.Copyright
                Version = $CompileConfig.Version
                
                # Optimisations
                Verbose = $false
                NoError = $false
                NoOutput = $false
            }
            
            # Icône si disponible
            if (Test-Path $iconFile) {
                $compileParams.IconFile = $iconFile
                Write-Host "   🎨 Icône intégrée: $iconFile" -ForegroundColor Green
            }
            
            Write-Host "   ⚡ Compilation en cours..." -ForegroundColor White
            
            # Compilation
            Invoke-PS2EXE @compileParams
            
            # Vérification résultat
            if (Test-Path $outputFile) {
                $fileInfo = Get-Item $outputFile
                $sizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)
                
                Write-Host "   ✅ SUCCÈS: $($fileInfo.Name)" -ForegroundColor Green
                Write-Host "   📏 Taille: $sizeMB MB" -ForegroundColor White
                Write-Host "   📅 Créé: $($fileInfo.CreationTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
                
            } else {
                Write-Host "   ❌ Échec compilation $arch" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "   ❌ ERREUR $arch : $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
    # Création exécutable universel (x86 compatible partout)
    Write-Host "🌍 CRÉATION EXÉCUTABLE UNIVERSEL..." -ForegroundColor Cyan
    
    $universalFile = Join-Path $OutputDir "$($CompileConfig.AppName)_v1.0_Universal.exe"
    
    try {
        $universalParams = @{
            InputFile = $CompileConfig.SourceScript
            OutputFile = $universalFile
            NoConsole = $true
            RequireAdmin = $true
            x64 = $false  # x86 pour compatibilité maximale
            
            Title = "$($CompileConfig.AppName) v1.0 Universal"
            Description = "$($CompileConfig.Description) - Compatible Windows 7-11 (x86/x64)"
            Company = $CompileConfig.Publisher
            Product = "$($CompileConfig.AppName) Universal"
            Copyright = $CompileConfig.Copyright
            Version = $CompileConfig.Version
        }
        
        if (Test-Path ".\adzvanced.ico") {
            $universalParams.IconFile = ".\adzvanced.ico"
        }
        
        Invoke-PS2EXE @universalParams
        
        if (Test-Path $universalFile) {
            $fileInfo = Get-Item $universalFile
            $sizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)
            
            Write-Host "✅ UNIVERSEL CRÉÉ: $($fileInfo.Name)" -ForegroundColor Green
            Write-Host "📏 Taille: $sizeMB MB" -ForegroundColor White
            Write-Host "🖥️  Compatible: Windows 7-11 (x86/x64)" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Erreur compilation universelle: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# === RÉSUMÉ FINAL ===
if ($CompileWindows -or $All) {
    Write-Host "📊 RÉSUMÉ DE COMPILATION" -ForegroundColor Magenta
    Write-Host "========================" -ForegroundColor Magenta
    
    if (Test-Path $OutputDir) {
        $files = Get-ChildItem "$OutputDir\*.exe"
        
        if ($files.Count -gt 0) {
            Write-Host "✅ $($files.Count) exécutable(s) créé(s):" -ForegroundColor Green
            
            foreach ($file in $files) {
                $sizeMB = [Math]::Round($file.Length / 1MB, 2)
                Write-Host "   📄 $($file.Name) ($sizeMB MB)" -ForegroundColor White
            }
            
            Write-Host ""
            Write-Host "📁 Dossier de sortie: $OutputDir" -ForegroundColor Cyan
            Write-Host ""
            
            # Recommandations distribution
            Write-Host "🚀 RECOMMANDATIONS DISTRIBUTION:" -ForegroundColor Yellow
            Write-Host "1. AdZ-Vanced_v1.0_Universal.exe → Distribution générale" -ForegroundColor White
            Write-Host "2. AdZ-Vanced_v1.0_Windows_x64.exe → Utilisateurs 64-bit" -ForegroundColor White
            Write-Host "3. AdZ-Vanced_v1.0_Windows_x86.exe → Anciens systèmes 32-bit" -ForegroundColor White
            Write-Host ""
            
            # Instructions utilisateur
            Write-Host "📋 INSTRUCTIONS UTILISATEUR:" -ForegroundColor Yellow
            Write-Host "1. Télécharger l'exécutable approprié" -ForegroundColor White
            Write-Host "2. Clic droit → 'Exécuter en tant qu'administrateur'" -ForegroundColor White
            Write-Host "3. Accepter l'élévation UAC" -ForegroundColor White
            Write-Host "4. Utiliser l'interface graphique" -ForegroundColor White
            
        } else {
            Write-Host "❌ Aucun exécutable créé" -ForegroundColor Red
        }
        
    } else {
        Write-Host "❌ Dossier de sortie non trouvé" -ForegroundColor Red
    }
}

# === INSTRUCTIONS D'UTILISATION ===
if (-not $Install -and -not $CompileWindows -and -not $All -and -not $Clean) {
    Write-Host "🔧 COMPILATEUR UNIVERSEL AdZ-Vanced" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 COMMANDES DISPONIBLES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  .\Compile_Universal_AdZvanced.ps1 -Install" -ForegroundColor White
    Write-Host "    📦 Installe les outils de compilation (PS2EXE)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Compile_Universal_AdZvanced.ps1 -CompileWindows" -ForegroundColor White
    Write-Host "    🚀 Compile les exécutables Windows (x86, x64, Universal)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Compile_Universal_AdZvanced.ps1 -All" -ForegroundColor White
    Write-Host "    ⚡ Installation + Compilation complète" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Compile_Universal_AdZvanced.ps1 -Clean" -ForegroundColor White
    Write-Host "    🧹 Nettoie les fichiers temporaires et de sortie" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📁 FICHIERS REQUIS:" -ForegroundColor Yellow
    Write-Host "  • AdZ-Vanced_Windows_v1.0_Pro.ps1 (script source)" -ForegroundColor White
    Write-Host "  • adzvanced.ico (optionnel, icône application)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 RÉSULTATS:" -ForegroundColor Yellow
    Write-Host "  • AdZ-Vanced_v1.0_Universal.exe (recommandé)" -ForegroundColor White
    Write-Host "  • AdZ-Vanced_v1.0_Windows_x64.exe (64-bit)" -ForegroundColor White
    Write-Host "  • AdZ-Vanced_v1.0_Windows_x86.exe (32-bit)" -ForegroundColor White
    Write-Host ""
    Write-Host "🖥️  COMPATIBILITÉ:" -ForegroundColor Yellow
    Write-Host "  • Windows 7, 8, 8.1, 10, 11" -ForegroundColor White
    Write-Host "  • Architectures x86 et x64" -ForegroundColor White
    Write-Host "  • PowerShell 5.1+ (intégré Windows)" -ForegroundColor White
}

Write-Host "================================================================" -ForegroundColor Magenta