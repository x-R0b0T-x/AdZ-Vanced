# Script de compilation AdZ-Vanced v1.0 vers .exe
# Version distribution finale

param(
    [switch]$Install,
    [switch]$Compile,
    [switch]$All
)

$ErrorActionPreference = "Stop"

Write-Host "===========================================" -ForegroundColor Magenta
Write-Host "    AdZ-Vanced v1.0 - Compilation Tool    " -ForegroundColor Magenta  
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host ""

if ($All) {
    $Install = $true
    $Compile = $true
}

# === INSTALLATION PS2EXE ===
if ($Install) {
    Write-Host "🔧 Installation de PS2EXE..." -ForegroundColor Yellow
    
    try {
        # Vérifier si PS2EXE est déjà installé
        $ps2exeModule = Get-Module -ListAvailable -Name PS2EXE
        
        if (-not $ps2exeModule) {
            Write-Host "📦 Téléchargement et installation de PS2EXE..." -ForegroundColor Cyan
            Install-Module PS2EXE -Force -Scope CurrentUser -AllowClobber
            Import-Module PS2EXE -Force
            Write-Host "✅ PS2EXE installé avec succès !" -ForegroundColor Green
        } else {
            Write-Host "✅ PS2EXE déjà installé" -ForegroundColor Green
            Import-Module PS2EXE -Force
        }
    }
    catch {
        Write-Host "❌ Erreur lors de l'installation de PS2EXE :" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# === COMPILATION ===
if ($Compile) {
    Write-Host ""
    Write-Host "🚀 Compilation d'AdZ-Vanced v1.0..." -ForegroundColor Yellow
    
    # Vérification des fichiers sources
    $sourceFile = ".\AdZ-Vanced_v1.0.ps1"
    if (-not (Test-Path $sourceFile)) {
        Write-Host "❌ Fichier source non trouvé : $sourceFile" -ForegroundColor Red
        Write-Host "📁 Assurez-vous que le fichier AdZ-Vanced_v1.0.ps1 est dans le même dossier" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "📄 Fichier source trouvé : $sourceFile" -ForegroundColor Green
    
    # Configuration de la compilation
    $outputFile = ".\AdZ-Vanced.exe"
    $iconFile = ".\adzvanced.ico"
    
    Write-Host "🎯 Fichier de sortie : $outputFile" -ForegroundColor Cyan
    
    try {
        # Paramètres de compilation optimisés
        $compileParams = @{
            InputFile = $sourceFile
            OutputFile = $outputFile
            NoConsole = $true
            RequireAdmin = $true
            Title = "AdZ-Vanced v1.0"
            Description = "Configuration DNS professionnelle AdZ-Vanced"
            Company = "KontacktzBot"
            Product = "AdZ-Vanced"
            Copyright = "© 2025 KontacktzBot. Tous droits réservés."
            Version = "1.0.0.0"
            Verbose = $false
            NoError = $false
            NoOutput = $false
            x64 = $true
        }
        
        # Ajouter l'icône si elle existe
        if (Test-Path $iconFile) {
            $compileParams.IconFile = $iconFile
            Write-Host "🎨 Icône trouvée et intégrée : $iconFile" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Aucune icône trouvée (optionnel)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "⚙️  Compilation en cours..." -ForegroundColor Cyan
        
        # Compilation avec PS2EXE
        Invoke-PS2EXE @compileParams
        
        # Vérification du résultat
        if (Test-Path $outputFile) {
            $fileInfo = Get-Item $outputFile
            Write-Host ""
            Write-Host "🎉 COMPILATION RÉUSSIE !" -ForegroundColor Green
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host "📁 Fichier créé : $($fileInfo.Name)" -ForegroundColor White
            Write-Host "📏 Taille : $([Math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
            Write-Host "📅 Date : $($fileInfo.CreationTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "🚀 Prêt pour la distribution !" -ForegroundColor Magenta
            Write-Host ""
            Write-Host "📋 INSTRUCTIONS D'INSTALLATION :" -ForegroundColor Yellow
            Write-Host "1. Copiez le fichier AdZ-Vanced.exe sur l'ordinateur cible" -ForegroundColor White
            Write-Host "2. Faites clic droit → 'Exécuter en tant qu'administrateur'" -ForegroundColor White
            Write-Host "3. L'interface AdZ-Vanced s'ouvre automatiquement" -ForegroundColor White
            Write-Host "4. Cliquez sur 'INSTALLER DNS' pour configurer" -ForegroundColor White
        } else {
            Write-Host "❌ ERREUR : Le fichier compilé n'a pas été créé" -ForegroundColor Red
            exit 1
        }
        
    }
    catch {
        Write-Host ""
        Write-Host "❌ ERREUR LORS DE LA COMPILATION :" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 SOLUTIONS POSSIBLES :" -ForegroundColor Yellow
        Write-Host "1. Vérifiez que PowerShell est exécuté en tant qu'administrateur" -ForegroundColor White
        Write-Host "2. Réessayez avec : .\Compile_AdZvanced_v1.0.ps1 -Install -Compile" -ForegroundColor White
        Write-Host "3. Vérifiez que le fichier .ps1 n'est pas bloqué (Propriétés → Débloquer)" -ForegroundColor White
        exit 1
    }
}

# === INSTRUCTIONS D'UTILISATION ===
if (-not $Install -and -not $Compile) {
    Write-Host "🔧 OUTIL DE COMPILATION AdZ-Vanced v1.0" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 COMMANDES DISPONIBLES :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  .\Compile_AdZvanced_v1.0.ps1 -Install" -ForegroundColor White
    Write-Host "    📦 Installe les outils nécessaires (PS2EXE)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Compile_AdZvanced_v1.0.ps1 -Compile" -ForegroundColor White  
    Write-Host "    🚀 Compile AdZ-Vanced.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\Compile_AdZvanced_v1.0.ps1 -All" -ForegroundColor White
    Write-Host "    ⚡ Installation + Compilation automatique" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📁 FICHIERS REQUIS :" -ForegroundColor Yellow
    Write-Host "  • AdZ-Vanced_v1.0.ps1 (script source)" -ForegroundColor White
    Write-Host "  • adzvanced.ico (optionnel, pour l'icône)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 RÉSULTAT :" -ForegroundColor Yellow
    Write-Host "  • AdZ-Vanced.exe (prêt pour distribution)" -ForegroundColor White
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Magenta