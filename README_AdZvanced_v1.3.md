# 🛡️ AdZ-Vanced v1.3 - Configuration DNS Professionnelle

## 📖 Description
AdZ-Vanced est un outil professionnel pour configurer facilement les serveurs DNS AdZ-Vanced sur votre ordinateur Windows. Version 1.3 avec interface moderne et fonctionnalités avancées.

## ✨ Fonctionnalités principales
- 🎨 **Interface professionnelle moderne**
- 🔍 **Validation automatique des serveurs DNS**
- 💾 **Sauvegarde automatique des paramètres**
- 🔄 **Restauration en un clic**
- 📊 **Journal d'opérations détaillé**
- 🛡️ **Gestion sécurisée des privilèges administrateur**

---

## 🚀 Installation et Utilisation

### Méthode 1 : Script PowerShell
1. **Téléchargez** le fichier `AdZ-Vanced_v1.3.ps1`
2. **Clic droit** sur le fichier → **"Exécuter avec PowerShell"**
3. **Acceptez** l'élévation des privilèges administrateur
4. **Utilisez** l'interface graphique

### Méthode 2 : Fichier .exe compilé
1. **Compilez** avec le script fourni :
   ```powershell
   .\Compile_AdZvanced.ps1 -Install -Compile
   ```
2. **Exécutez** `AdZ-Vanced_v1.3.exe`
3. **Acceptez** les privilèges administrateur

---

## 🖥️ Guide d'utilisation

### 🔧 Configuration DNS AdZ-Vanced
1. **Cliquez** sur **"🚀 INSTALLER DNS AdZ-Vanced"**
2. **Attendez** la validation automatique des serveurs
3. **Suivez** les opérations dans le journal
4. **Confirmation** : "Configuration DNS AdZ-Vanced appliquée avec succès !"

### 🔄 Restauration paramètres par défaut
1. **Cliquez** sur **"🔄 RESTAURER DNS PAR DÉFAUT"**
2. **Confirmation** : Paramètres DHCP restaurés
3. **Alternative** : Utilisez le bouton **"💾 Sauvegarde"** pour restaurer une sauvegarde précédente

### 📋 Lecture du journal
Le journal affiche en temps réel :
- 🟢 **Messages verts** : Opérations réussies
- 🟡 **Messages jaunes** : Avertissements
- 🔴 **Messages rouges** : Erreurs
- ⚪ **Messages blancs** : Informations

---

## 🔧 Compilation vers .exe

### Prérequis
- Windows PowerShell 5.1+
- Module PS2EXE

### Instructions
```powershell
# 1. Installer PS2EXE
.\Compile_AdZvanced.ps1 -Install

# 2. Compiler l'application
.\Compile_AdZvanced.ps1 -Compile

# 3. Ou les deux en une commande
.\Compile_AdZvanced.ps1 -Install -Compile
```

### Résultat
- Fichier généré : `AdZ-Vanced_v1.3.exe`
- Taille approximative : 8-12 MB
- Privilèges administrateur : Automatiques

---

## 📱 Version Android (.APK)

### Concept développé
Un concept complet pour une version Android a été développé (voir `AdZvanced_Android_Concept.md`) incluant :

- 🏗️ **Architecture VpnService** pour contourner les limitations
- 🎨 **Interface Material Design** native
- 📊 **Statistiques et widgets** avancés
- 🚀 **Distribution Google Play Store**

### Développement requis
- **Android Studio** + Kotlin
- **Temps estimé** : 3-4 mois
- **Budget** : ~25$ (Google Play Developer)

---

## 🔒 Sécurité et Confidentialité

### Permissions requises
- **Administrateur** : Pour modifier les paramètres réseau
- **Internet** : Pour télécharger le logo et tester la connectivité
- **Système** : Pour accéder aux interfaces réseau

### Données collectées
- **AUCUNE** : L'application ne collecte aucune donnée personnelle
- **Local uniquement** : Toutes les opérations sont locales
- **Logs temporaires** : Fichiers de log stockés dans `%TEMP%`

### Sauvegarde
- **Fichier** : `%TEMP%\AdZvanced_DNS_Backup.json`
- **Contenu** : Configuration DNS précédente
- **Utilisation** : Restauration en cas de problème

---

## 🌐 Serveurs DNS AdZ-Vanced

### IPv4
- **Primaire** : `45.90.28.219`
- **Secondaire** : `45.90.30.219`

### IPv6
- **Primaire** : `2a07:a8c0::a8:3732`
- **Secondaire** : `2a07:a8c1::a8:3732`

### Avantages
- 🚫 **Blocage publicités** et trackers
- 🏃 **Navigation plus rapide**
- 🛡️ **Protection malware** et phishing
- 🌍 **Accès contenu géo-bloqué**

---

## 🆘 Dépannage

### L'application ne se lance pas
- **Vérifiez** : Windows PowerShell 5.1+ installé
- **Exécutez** en tant qu'administrateur
- **Débloquez** le fichier si téléchargé (Propriétés → Débloquer)

### Erreur "Aucun serveur DNS accessible"
- **Vérifiez** votre connexion Internet
- **Testez** manuellement : `ping 45.90.28.219`
- **Désactivez** temporairement antivirus/firewall

### DNS non appliqués
- **Redémarrez** l'application en tant qu'administrateur
- **Vérifiez** : `ipconfig /all` dans l'invite de commande
- **Videz** le cache DNS : `ipconfig /flushdns`

### Restauration impossible
- **Utilisez** le bouton "Sauvegarde" pour restaurer
- **Méthode manuelle** : 
  1. Panneau de configuration → Réseau
  2. Propriétés de la carte réseau
  3. IPv4 → Propriétés → "Obtenir automatiquement"

---

## 💝 Support et Donations

### Soutenir le projet
- 💳 **PayPal** : Bouton dans l'application
- ☕ **Tipeee** : Bouton dans l'application
- 📱 **Telegram** : Communauté @adzvanced

### Contact
- **Bugs** : Rapportez via Telegram
- **Suggestions** : Communauté Telegram
- **Support** : Documentation et FAQ

---

## 📋 Changelog

### v1.3 (Janvier 2025)
- ✨ Interface moderne et professionnelle
- ✅ Validation automatique des DNS
- 💾 Système de sauvegarde/restauration
- 📊 Journal d'opérations coloré
- 🔒 Gestion sécurisée des privilèges
- 📱 Concept Android développé
- 💻 Script de compilation .exe

### v1.2 (Précédent)
- 🎨 Interface graphique basique
- ⚙️ Configuration DNS IPv4/IPv6
- 🔄 Restauration DHCP
- 💝 Boutons donation et Telegram

---

## 📜 Licence
© 2025 KontacktzBot - Tous droits réservés

**AdZ-Vanced v1.3 - Pour une navigation plus saine et plus rapide !** 🚀