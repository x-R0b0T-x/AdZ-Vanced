import React, { useState } from 'react';

const AdZvancedPreview = () => {
  const [status, setStatus] = useState("Prêt à configurer vos DNS AdZ-Vanced...\n\nCliquez sur 'INSTALLER DNS' pour commencer\nou sur 'RESTAURER DNS' pour revenir aux paramètres par défaut.\n\nTous vos paramètres actuels seront sauvegardés automatiquement.");
  const [progress, setProgress] = useState(0);

  const handleInstall = () => {
    setStatus("");
    let messages = [
      { text: "🔍 Validation des serveurs DNS...", delay: 500 },
      { text: "✅ DNS AdZ-Vanced : Accessible", delay: 1000 },
      { text: "🛡️ Configuration des cartes réseau...", delay: 1500 },
      { text: "⚡ Application des paramètres de sécurité...", delay: 2000 },
      { text: "✅ Configuration DNS AdZ-Vanced appliquée avec succès !", delay: 2500 },
      { text: "🎉 Profitez maintenant d'un surf sain et rapide !", delay: 3000 },
    ];

    let currentStatus = "";
    messages.forEach((msg, index) => {
      setTimeout(() => {
        currentStatus += msg.text + "\n";
        setStatus(currentStatus);
        setProgress(((index + 1) / messages.length) * 100);
      }, msg.delay);
    });
  };

  const handleRestore = () => {
    setStatus("");
    let messages = [
      { text: "🔄 Restauration des paramètres par défaut...", delay: 500 },
      { text: "📶 Retour aux DNS de votre FAI...", delay: 1000 },
      { text: "✅ DNS restaurés par défaut (DHCP)", delay: 1500 },
      { text: "ℹ️  Vos paramètres réseau d'origine sont restaurés", delay: 2000 },
    ];

    let currentStatus = "";
    messages.forEach((msg, index) => {
      setTimeout(() => {
        currentStatus += msg.text + "\n";
        setStatus(currentStatus);
        setProgress(((index + 1) / messages.length) * 100);
      }, msg.delay);
    });
  };

  return (
    <div className="min-h-screen bg-black p-4">
      <div className="max-w-2xl mx-auto bg-white rounded-2xl shadow-2xl overflow-hidden border border-purple-200">
        
        {/* En-tête Web 3.0 */}
        <div className="bg-gradient-to-r from-purple-900 via-purple-700 to-purple-900 p-8 text-center">
          <h1 className="text-5xl font-bold text-white mb-2 tracking-wide">AdZ-Vanced</h1>
          <p className="text-purple-200 text-sm">v1.3</p>
        </div>

        {/* Logo */}
        <div className="p-8 text-center bg-white">
          <div className="mx-auto w-48 h-36 rounded-xl overflow-hidden shadow-lg border-2 border-purple-100">
            <img 
              src="https://files.catbox.moe/j3evd5.jpg" 
              alt="AdZ-Vanced Logo" 
              className="w-full h-full object-cover"
              onError={(e) => {
                e.target.style.display = 'none';
                e.target.nextSibling.style.display = 'flex';
              }}
            />
            <div className="w-full h-full bg-gradient-to-br from-purple-100 to-purple-200 flex items-center justify-center" style={{display: 'none'}}>
              <div className="text-center">
                <div className="text-4xl mb-2">🛡️</div>
                <div className="font-bold text-purple-800">LOGO</div>
                <div className="text-sm text-purple-600">AdZ-Vanced</div>
              </div>
            </div>
          </div>
        </div>

        {/* Message marketing */}
        <div className="mx-6 mb-8 bg-gradient-to-r from-purple-50 to-purple-100 border-l-4 border-purple-500 rounded-r-lg p-6">
          <div className="text-gray-800 text-center leading-relaxed">
            <strong className="text-purple-800">Grâce à AdZ-Vanced</strong>, vous allez enfin pouvoir profiter d'un <strong>surf sain et rapide</strong>. 
            Pas de pub, pas de données personnelles qui fuitent et vive le contournement imposé par les FAI.
          </div>
        </div>

        {/* Boutons principaux */}
        <div className="px-6 mb-8 grid grid-cols-2 gap-6">
          <button 
            onClick={handleInstall}
            className="bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white font-bold py-5 px-6 rounded-xl transition-all duration-300 shadow-lg hover:shadow-xl transform hover:scale-105"
          >
            🚀 INSTALLER DNS
          </button>
          <button 
            onClick={handleRestore}
            className="bg-gradient-to-r from-gray-700 to-gray-800 hover:from-gray-800 hover:to-gray-900 text-white font-bold py-5 px-6 rounded-xl transition-all duration-300 shadow-lg hover:shadow-xl transform hover:scale-105"
          >
            🔄 RESTAURER DNS
          </button>
        </div>

        {/* Zone de statut */}
        <div className="px-6 mb-6">
          <div className="font-bold text-gray-800 mb-3 flex items-center">
            <span className="text-purple-600 mr-2">📋</span> Journal des opérations
          </div>
          <div className="bg-black text-green-400 p-5 rounded-xl h-40 overflow-y-auto font-mono text-sm border border-purple-200 shadow-inner">
            <div className="whitespace-pre-wrap">{status}</div>
          </div>
        </div>

        {/* Barre de progression */}
        <div className="px-6 mb-6">
          <div className="w-full bg-gray-200 rounded-full h-3 shadow-inner">
            <div 
              className="bg-gradient-to-r from-purple-500 to-purple-600 h-3 rounded-full transition-all duration-700 shadow-sm"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </div>

        {/* Boutons finaux */}
        <div className="px-6 pb-6 grid grid-cols-4 gap-3">
          <button className="bg-purple-600 hover:bg-purple-700 text-white text-sm py-3 px-3 rounded-lg transition-all duration-200 shadow hover:shadow-md">
            💝 Donation
          </button>
          <button className="bg-purple-600 hover:bg-purple-700 text-white text-sm py-3 px-3 rounded-lg transition-all duration-200 shadow hover:shadow-md">
            📱 Telegram
          </button>
          <button className="bg-purple-600 hover:bg-purple-700 text-white text-sm py-3 px-3 rounded-lg transition-all duration-200 shadow hover:shadow-md">
            📄 Info
          </button>
          <button className="bg-gray-800 hover:bg-black text-white text-sm py-3 px-3 rounded-lg transition-all duration-200 shadow hover:shadow-md">
            ❌ Fermer
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdZvancedPreview;