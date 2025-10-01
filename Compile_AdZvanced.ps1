# Script de compilation AdZ-Vanced v1.3 vers .exe
# Nécessite PS2EXE : Install-Module PS2EXE -Force

param(
    [switch]$Install,
    [switch]$Compile
)

Write-Host "=== AdZ-Vanced v1.3 - Compilation Tool ===" -ForegroundColor Cyan

if ($Install) {
    Write-Host "Installation de PS2EXE..." -ForegroundColor Yellow
    
    # Vérification et installation de PS2EXE
    if (-not (Get-Module -ListAvailable -Name PS2EXE)) {
        try {
            Install-Module PS2EXE -Force -Scope CurrentUser
            Write-Host "✅ PS2EXE installé avec succès" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Erreur lors de l'installation de PS2EXE : $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ PS2EXE déjà installé" -ForegroundColor Green
    }
}

if ($Compile) {
    Write-Host "Compilation d'AdZ-Vanced v1.3..." -ForegroundColor Yellow
    
    # Vérification du fichier source
    $sourceFile = ".\AdZ-Vanced_v1.3.ps1"
    if (-not (Test-Path $sourceFile)) {
        Write-Host "❌ Fichier source non trouvé : $sourceFile" -ForegroundColor Red
        exit 1
    }
    
    # Paramètres de compilation
    $outputFile = ".\AdZ-Vanced_v1.3.exe"
    $iconFile = ".\adzvanced_icon.ico" # Optionnel
    
    try {
        # Compilation avec PS2EXE
        $compileParams = @{
            InputFile = $sourceFile
            OutputFile = $outputFile
            NoConsole = $true
            RequireAdmin = $true
            Title = "AdZ-Vanced v1.3"
            Description = "Outil DNS professionnel AdZ-Vanced"
            Company = "KontacktzBot"
            Product = "AdZ-Vanced"
            Copyright = "© 2025 KontacktzBot"
            Version = "1.3.0.0"
        }
        
        # Ajouter l'icône si elle existe
        if (Test-Path $iconFile) {
            $compileParams.IconFile = $iconFile
        }
        
        Import-Module PS2EXE
        Invoke-PS2EXE @compileParams
        
        if (Test-Path $outputFile) {
            Write-Host "✅ Compilation réussie : $outputFile" -ForegroundColor Green
            
            # Informations sur le fichier
            $fileInfo = Get-Item $outputFile
            Write-Host "📁 Taille du fichier : $([Math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
            Write-Host "📅 Date de création : $($fileInfo.CreationTime)" -ForegroundColor Cyan
        } else {
            Write-Host "❌ La compilation a échoué" -ForegroundColor Red
            exit 1
        }
        
    }
    catch {
        Write-Host "❌ Erreur lors de la compilation : $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Instructions d'utilisation
if (-not $Install -and -not $Compile) {
    Write-Host @"
Instructions de compilation :

1. Installer PS2EXE :
   .\Compile_AdZvanced.ps1 -Install

2. Compiler AdZ-Vanced :
   .\Compile_AdZvanced.ps1 -Compile

3. Ou les deux en une fois :
   .\Compile_AdZvanced.ps1 -Install -Compile

Le fichier AdZ-Vanced_v1.3.exe sera créé dans le répertoire courant.

Note : L'exécution nécessite des privilèges administrateur.
"@ -ForegroundColor White
}

Write-Host "=== Terminé ===" -ForegroundColor Cyan