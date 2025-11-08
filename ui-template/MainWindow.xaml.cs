using System;
using System.Diagnostics;
using System.Windows;

namespace AdZVancedApp
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void Donation_Click(object sender, RoutedEventArgs e)
        {
            Process.Start(new ProcessStartInfo("https://www.paypal.com/ncp/payment/MGLWSKGF79JN8") { UseShellExecute = true });
        }
        private void Telegram_Click(object sender, RoutedEventArgs e)
        {
            Process.Start(new ProcessStartInfo("https://t.me/adzvanced") { UseShellExecute = true });
        }
        private void Info_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show(
                "🚫 Adieu les pubs !\n🕵️‍♀️ Bloquez les traceurs\n🛡 Protection contre les sites dangereux\n🌍 Contournez la censure des FAI\n🔒 Flux internet chiffré\n📉 Moins de données chargées\n⚡️ Temps de réponse plus rapide\n\nEt surtout\n💯 Gratuit, multiplateforme et support en français !",
                "AdZ-Vanced – Fonctions", MessageBoxButton.OK, MessageBoxImage.Information);
        }
        private void VoirDNS_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show(
                "IPV4 : 45.90.28.219 et 45.90.30.219\nIPV6 : 2a07:a8c0::a8:3732 et 2a07:a8c1::a8:3732",
                "AdZ-Vanced – DNS", MessageBoxButton.OK, MessageBoxImage.Information);
        }
        private void Logs_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Aucun fichier log trouvé.\n(ou personnalise ici pour ouvrir un fichier)", "Logs", MessageBoxButton.OK, MessageBoxImage.Information);
        }
        private void Fermer_Click(object sender, RoutedEventArgs e)
        {
            var res = MessageBox.Show(
                "Avant de quitter, tu peux soutenir le projet via le bouton Don.\nContinuer ?", "AdZ-Vanced", MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (res == MessageBoxResult.Yes)
                this.Close();
        }
    }
}
