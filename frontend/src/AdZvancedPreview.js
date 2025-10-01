import React, { useState } from 'react';

const AdZvancedPreview = () => {
  const [status, setStatus] = useState("Prêt à configurer vos DNS AdZ-Vanced...\n\nCliquez sur 'INSTALLER DNS' pour commencer\nou sur 'RESTAURER DNS' pour revenir aux paramètres par défaut.\n\nTous vos paramètres actuels seront sauvegardés automatiquement.");
  const [progress, setProgress] = useState(0);

  const handleInstall = () => {
    setStatus("");
    let messages = [
      { text: "🔍 Validation des serveurs DNS...", color: "text-yellow-400", delay: 500 },
      { text: "✅ DNS 45.90.28.219 : Accessible", color: "text-green-400", delay: 1000 },
      { text: "✅ DNS 45.90.30.219 : Accessible", color: "text-green-400", delay: 1500 },
      { text: "🛡️ Configuration des cartes réseau...", color: "text-cyan-400", delay: 2000 },
      { text: "✅ Configuration DNS AdZ-Vanced appliquée avec succès !", color: "text-green-400", delay: 2500 },
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
      { text: "🔄 Restauration des paramètres par défaut...", color: "text-yellow-400", delay: 500 },
      { text: "✅ DNS restaurés par défaut (DHCP)", color: "text-green-400", delay: 1000 },
      { text: "📶 Vos paramètres réseau d'origine sont restaurés", color: "text-cyan-400", delay: 1500 },
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
    <div className="min-h-screen bg-gray-100 p-4">
      <div className="max-w-2xl mx-auto bg-gray-200 rounded-lg shadow-lg overflow-hidden">
        
        {/* En-tête */}
        <div className="bg-gray-200 p-6 text-center border-b">
          <h1 className="text-3xl font-bold text-blue-800 mb-2">AdZ-Vanced v1.3</h1>
          <p className="text-lg text-gray-700">Pour un surf sain et rapide !</p>
        </div>

        {/* Logo */}
        <div className="p-6 text-center">
          <div className="mx-auto w-48 h-36 bg-white border-2 border-gray-300 rounded flex items-center justify-center">
            <div className="text-center">
              <div className="text-4xl mb-2">🛡️</div>
              <div className="font-bold text-blue-800">LOGO</div>
              <div className="text-sm text-blue-800">AdZ-Vanced</div>
            </div>
          </div>
        </div>

        {/* Informations DNS */}
        <div className="mx-6 mb-6 bg-gray-50 border border-gray-300 rounded p-4 text-center">
          <div className="font-bold text-gray-800 mb-2">🛡️ Serveurs DNS sécurisés AdZ-Vanced</div>
          <div className="text-sm text-gray-700">IPv4: 45.90.28.219 / 45.90.30.219</div>
        </div>

        {/* Boutons principaux */}
        <div className="px-6 mb-6 grid grid-cols-2 gap-4">
          <button 
            onClick={handleInstall}
            className="bg-green-600 hover:bg-green-700 text-white font-bold py-4 px-6 rounded transition-colors"
          >
            🚀 INSTALLER DNS
          </button>
          <button 
            onClick={handleRestore}
            className="bg-orange-500 hover:bg-orange-600 text-white font-bold py-4 px-6 rounded transition-colors"
          >
            🔄 RESTAURER DNS
          </button>
        </div>

        {/* Zone de statut */}
        <div className="px-6 mb-4">
          <div className="font-bold text-gray-800 mb-2">📋 Statut :</div>
          <div className="bg-black text-white p-4 rounded h-40 overflow-y-auto font-mono text-sm">
            <div className="whitespace-pre-wrap">{status}</div>
          </div>
        </div>

        {/* Barre de progression */}
        <div className="px-6 mb-4">
          <div className="w-full bg-gray-300 rounded-full h-2">
            <div 
              className="bg-blue-600 h-2 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        </div>

        {/* Boutons finaux */}
        <div className="px-6 pb-6 grid grid-cols-4 gap-2">
          <button className="bg-blue-800 hover:bg-blue-900 text-white text-sm py-2 px-3 rounded transition-colors">
            💝 Donation
          </button>
          <button className="bg-blue-800 hover:bg-blue-900 text-white text-sm py-2 px-3 rounded transition-colors">
            📱 Telegram
          </button>
          <button className="bg-blue-800 hover:bg-blue-900 text-white text-sm py-2 px-3 rounded transition-colors">
            📄 Info
          </button>
          <button className="bg-red-600 hover:bg-red-700 text-white text-sm py-2 px-3 rounded transition-colors">
            ❌ Fermer
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdZvancedPreview;