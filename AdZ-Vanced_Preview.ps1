Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === INTERFACE PREVIEW AdZ-Vanced v1.3 ===

# Couleurs
$colorFond = [System.Drawing.Color]::FromArgb(240, 240, 240)
$colorVert = [System.Drawing.Color]::FromArgb(40, 167, 69)
$colorOrange = [System.Drawing.Color]::FromArgb(255, 165, 0)
$colorBleu = [System.Drawing.Color]::FromArgb(31, 78, 121)
$colorNoirTexte = [System.Drawing.Color]::FromArgb(33, 37, 41)

# Fenêtre principale
$form = New-Object Windows.Forms.Form
$form.Text = "AdZ-Vanced v1.3 - Configuration DNS"
$form.Size = New-Object Drawing.Size(600, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $colorFond

# === EN-TÊTE ===
# Titre principal
$lblTitre = New-Object Windows.Forms.Label
$lblTitre.Text = "AdZ-Vanced v1.3"
$lblTitre.Font = New-Object Drawing.Font("Arial", 20, [Drawing.FontStyle]::Bold)
$lblTitre.ForeColor = $colorBleu
$lblTitre.BackColor = [Drawing.Color]::Transparent
$lblTitre.Size = New-Object Drawing.Size(580, 40)
$lblTitre.Location = New-Object Drawing.Point(10, 20)
$lblTitre.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblTitre)

# Sous-titre
$lblSousTitre = New-Object Windows.Forms.Label
$lblSousTitre.Text = "Pour un surf sain et rapide !"
$lblSousTitre.Font = New-Object Drawing.Font("Arial", 12)
$lblSousTitre.ForeColor = $colorNoirTexte
$lblSousTitre.BackColor = [Drawing.Color]::Transparent
$lblSousTitre.Size = New-Object Drawing.Size(580, 25)
$lblSousTitre.Location = New-Object Drawing.Point(10, 60)
$lblSousTitre.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblSousTitre)

# === LOGO (zone placeholder) ===
$logoPanel = New-Object Windows.Forms.Panel
$logoPanel.Size = New-Object Drawing.Size(200, 150)
$logoPanel.Location = New-Object Drawing.Point(200, 100)
$logoPanel.BackColor = [Drawing.Color]::White
$logoPanel.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($logoPanel)

$lblLogo = New-Object Windows.Forms.Label
$lblLogo.Text = "🛡️`nLOGO`nAdZ-Vanced"
$lblLogo.Font = New-Object Drawing.Font("Arial", 14, [Drawing.FontStyle]::Bold)
$lblLogo.ForeColor = $colorBleu
$lblLogo.BackColor = [Drawing.Color]::Transparent
$lblLogo.Size = New-Object Drawing.Size(200, 150)
$lblLogo.Location = New-Object Drawing.Point(0, 0)
$lblLogo.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$logoPanel.Controls.Add($lblLogo)

# === INFORMATIONS DNS ===
$panelInfo = New-Object Windows.Forms.Panel
$panelInfo.Size = New-Object Drawing.Size(560, 60)
$panelInfo.Location = New-Object Drawing.Point(20, 270)
$panelInfo.BackColor = [Drawing.Color]::FromArgb(248, 249, 250)
$panelInfo.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panelInfo)

$lblInfo = New-Object Windows.Forms.Label
$lblInfo.Text = "🛡️ Serveurs DNS sécurisés AdZ-Vanced"
$lblInfo.Font = New-Object Drawing.Font("Arial", 11, [Drawing.FontStyle]::Bold)
$lblInfo.ForeColor = $colorNoirTexte
$lblInfo.BackColor = [Drawing.Color]::Transparent
$lblInfo.Size = New-Object Drawing.Size(540, 25)
$lblInfo.Location = New-Object Drawing.Point(10, 10)
$lblInfo.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$panelInfo.Controls.Add($lblInfo)

$lblDNS = New-Object Windows.Forms.Label
$lblDNS.Text = "IPv4: 45.90.28.219 / 45.90.30.219"
$lblDNS.Font = New-Object Drawing.Font("Arial", 9)
$lblDNS.ForeColor = $colorNoirTexte
$lblDNS.BackColor = [Drawing.Color]::Transparent
$lblDNS.Size = New-Object Drawing.Size(540, 20)
$lblDNS.Location = New-Object Drawing.Point(10, 35)
$lblDNS.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$panelInfo.Controls.Add($lblDNS)

# === BOUTONS PRINCIPAUX ===
# Bouton Installer
$btnInstaller = New-Object Windows.Forms.Button
$btnInstaller.Text = "🚀 INSTALLER DNS"
$btnInstaller.Font = New-Object Drawing.Font("Arial", 12, [Drawing.FontStyle]::Bold)
$btnInstaller.Size = New-Object Drawing.Size(250, 50)
$btnInstaller.Location = New-Object Drawing.Point(50, 350)
$btnInstaller.BackColor = $colorVert
$btnInstaller.ForeColor = [Drawing.Color]::White
$btnInstaller.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$btnInstaller.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnInstaller)

# Bouton Restaurer
$btnRestaurer = New-Object Windows.Forms.Button
$btnRestaurer.Text = "🔄 RESTAURER DNS"
$btnRestaurer.Font = New-Object Drawing.Font("Arial", 12, [Drawing.FontStyle]::Bold)
$btnRestaurer.Size = New-Object Drawing.Size(250, 50)
$btnRestaurer.Location = New-Object Drawing.Point(320, 350)
$btnRestaurer.BackColor = $colorOrange
$btnRestaurer.ForeColor = [Drawing.Color]::White
$btnRestaurer.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$btnRestaurer.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnRestaurer)

# === ZONE DE STATUT ===
$lblStatutTitre = New-Object Windows.Forms.Label
$lblStatutTitre.Text = "📋 Statut :"
$lblStatutTitre.Font = New-Object Drawing.Font("Arial", 10, [Drawing.FontStyle]::Bold)
$lblStatutTitre.ForeColor = $colorNoirTexte
$lblStatutTitre.BackColor = [Drawing.Color]::Transparent
$lblStatutTitre.Size = New-Object Drawing.Size(100, 25)
$lblStatutTitre.Location = New-Object Drawing.Point(30, 420)
$form.Controls.Add($lblStatutTitre)

$txtStatut = New-Object Windows.Forms.RichTextBox
$txtStatut.Size = New-Object Drawing.Size(540, 150)
$txtStatut.Location = New-Object Drawing.Point(30, 450)
$txtStatut.ReadOnly = $true
$txtStatut.BackColor = [Drawing.Color]::Black
$txtStatut.ForeColor = [Drawing.Color]::White
$txtStatut.Font = New-Object Drawing.Font("Consolas", 9)
$txtStatut.Text = "Prêt à configurer vos DNS AdZ-Vanced...`n`nCliquez sur 'INSTALLER DNS' pour commencer`nou sur 'RESTAURER DNS' pour revenir aux paramètres par défaut.`n`nTous vos paramètres actuels seront sauvegardés automatiquement."
$form.Controls.Add($txtStatut)

# === BARRE DE PROGRESSION ===
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Size = New-Object Drawing.Size(540, 10)
$progressBar.Location = New-Object Drawing.Point(30, 610)
$progressBar.Style = 'Continuous'
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# === BOUTONS FINAUX ===
$btnDonation = New-Object Windows.Forms.Button
$btnDonation.Text = "💝 Donation"
$btnDonation.Size = New-Object Drawing.Size(120, 30)
$btnDonation.Location = New-Object Drawing.Point(50, 630)
$btnDonation.BackColor = $colorBleu
$btnDonation.ForeColor = [Drawing.Color]::White
$btnDonation.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($btnDonation)

$btnTelegram = New-Object Windows.Forms.Button
$btnTelegram.Text = "📱 Telegram"
$btnTelegram.Size = New-Object Drawing.Size(120, 30)
$btnTelegram.Location = New-Object Drawing.Point(180, 630)
$btnTelegram.BackColor = $colorBleu
$btnTelegram.ForeColor = [Drawing.Color]::White
$btnTelegram.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($btnTelegram)

$btnInfo = New-Object Windows.Forms.Button
$btnInfo.Text = "📄 Info"
$btnInfo.Size = New-Object Drawing.Size(120, 30)
$btnInfo.Location = New-Object Drawing.Point(310, 630)
$btnInfo.BackColor = $colorBleu
$btnInfo.ForeColor = [Drawing.Color]::White
$btnInfo.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($btnInfo)

$btnFermer = New-Object Windows.Forms.Button
$btnFermer.Text = "❌ Fermer"
$btnFermer.Size = New-Object Drawing.Size(120, 30)
$btnFermer.Location = New-Object Drawing.Point(440, 630)
$btnFermer.BackColor = [Drawing.Color]::FromArgb(220, 53, 69)
$btnFermer.ForeColor = [Drawing.Color]::White
$btnFermer.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$form.Controls.Add($btnFermer)

# === ÉVÉNEMENTS DE TEST ===
$btnInstaller.Add_Click({
    $txtStatut.Clear()
    $txtStatut.SelectionColor = [Drawing.Color]::Yellow
    $txtStatut.AppendText("🔍 Validation des serveurs DNS...`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Green
    $txtStatut.AppendText("✅ DNS 45.90.28.219 : Accessible`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Green
    $txtStatut.AppendText("✅ DNS 45.90.30.219 : Accessible`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Cyan
    $txtStatut.AppendText("🛡️ Configuration des cartes réseau...`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Green
    $txtStatut.AppendText("✅ Configuration DNS AdZ-Vanced appliquée avec succès !`n")
})

$btnRestaurer.Add_Click({
    $txtStatut.Clear()
    $txtStatut.SelectionColor = [Drawing.Color]::Yellow
    $txtStatut.AppendText("🔄 Restauration des paramètres par défaut...`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Green
    $txtStatut.AppendText("✅ DNS restaurés par défaut (DHCP)`n")
    $txtStatut.SelectionColor = [Drawing.Color]::Cyan
    $txtStatut.AppendText("📶 Vos paramètres réseau d'origine sont restaurés`n")
})

$btnFermer.Add_Click({ $form.Close() })

# === AFFICHAGE ===
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()