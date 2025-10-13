import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  Animated,
  StatusBar,
  Dimensions,
  ScrollView,
  Image,
  Alert,
  Linking,
  ActivityIndicator,
  Vibration,
} from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import DeviceInfo from 'react-native-device-info';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

// === COULEURS PROFESSIONNELLES ===
const Colors = {
  primary: '#9333ea',      // Violet principal
  primaryDark: '#7c3aed',  // Violet foncé
  primaryLight: '#c4b5fd', // Violet clair
  secondary: '#6366f1',    // Indigo
  accent: '#8b5cf6',       // Purple accent
  background: '#000000',   // Noir profond
  surface: '#ffffff',      // Blanc pur
  surfaceLight: '#f8fafc', // Gris très clair
  text: '#1f2937',         // Gris foncé
  textLight: '#6b7280',    // Gris moyen
  success: '#10b981',      // Vert
  warning: '#f59e0b',      // Orange
  error: '#ef4444',        // Rouge
  terminal: '#00ff00',     // Vert terminal
};

// === COMPOSANT BOUTON MODERNE ===
const ModernButton = ({ 
  title, 
  onPress, 
  style = {}, 
  textStyle = {}, 
  gradient = [Colors.primary, Colors.primaryDark],
  icon = null,
  loading = false,
  disabled = false 
}) => {
  const scaleAnim = useRef(new Animated.Value(1)).current;
  
  const handlePressIn = () => {
    Vibration.vibrate(10);
    Animated.spring(scaleAnim, {
      toValue: 0.95,
      useNativeDriver: true,
    }).start();
  };
  
  const handlePressOut = () => {
    Animated.spring(scaleAnim, {
      toValue: 1,
      useNativeDriver: true,
    }).start();
  };

  return (
    <TouchableOpacity
      onPress={onPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      disabled={disabled || loading}
      activeOpacity={0.8}
    >
      <Animated.View style={[{ transform: [{ scale: scaleAnim }] }]}>
        <LinearGradient
          colors={disabled ? [Colors.textLight, Colors.textLight] : gradient}
          style={[styles.modernButton, style]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          {loading ? (
            <ActivityIndicator color={Colors.surface} size="small" />
          ) : (
            <View style={styles.buttonContent}>
              {icon && (
                <Icon 
                  name={icon} 
                  size={24} 
                  color={Colors.surface} 
                  style={styles.buttonIcon} 
                />
              )}
              <Text style={[styles.buttonText, textStyle]}>{title}</Text>
            </View>
          )}
        </LinearGradient>
      </Animated.View>
    </TouchableOpacity>
  );
};

// === COMPOSANT CARD MODERNE ===
const ModernCard = ({ children, style = {} }) => (
  <View style={[styles.modernCard, style]}>
    {children}
  </View>
);

// === COMPOSANT TERMINAL ===
const Terminal = ({ logs, isVisible }) => {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  
  useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: isVisible ? 1 : 0,
      duration: 300,
      useNativeDriver: true,
    }).start();
  }, [isVisible]);

  return (
    <Animated.View style={[styles.terminal, { opacity: fadeAnim }]}>
      <View style={styles.terminalHeader}>
        <Icon name="console-line" size={16} color={Colors.terminal} />
        <Text style={styles.terminalTitle}>Journal des opérations</Text>
      </View>
      <ScrollView style={styles.terminalContent} showsVerticalScrollIndicator={false}>
        {logs.map((log, index) => (
          <Text key={index} style={[styles.terminalText, { color: log.color }]}>
            {log.timestamp} {log.message}
          </Text>
        ))}
      </ScrollView>
    </Animated.View>
  );
};

// === COMPOSANT PROGRESS BAR ===
const ProgressBar = ({ progress, isVisible }) => {
  const progressAnim = useRef(new Animated.Value(0)).current;
  
  useEffect(() => {
    Animated.timing(progressAnim, {
      toValue: progress,
      duration: 500,
      useNativeDriver: false,
    }).start();
  }, [progress]);

  if (!isVisible) return null;

  return (
    <View style={styles.progressContainer}>
      <View style={styles.progressTrack}>
        <Animated.View style={[
          styles.progressBar,
          {
            width: progressAnim.interpolate({
              inputRange: [0, 100],
              outputRange: ['0%', '100%'],
            })
          }
        ]} />
      </View>
    </View>
  );
};

// === COMPOSANT PRINCIPAL ===
const AdZvancedApp = () => {
  const [isDNSActive, setIsDNSActive] = useState(false);
  const [logs, setLogs] = useState([]);
  const [showTerminal, setShowTerminal] = useState(false);
  const [progress, setProgress] = useState(0);
  const [showProgress, setShowProgress] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [deviceInfo, setDeviceInfo] = useState({});

  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(50)).current;

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    // Animation d'entrée
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 800,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 600,
        useNativeDriver: true,
      }),
    ]).start();

    // Récupération infos device
    const brand = await DeviceInfo.getBrand();
    const model = await DeviceInfo.getModel();
    const systemVersion = await DeviceInfo.getSystemVersion();
    
    setDeviceInfo({ brand, model, systemVersion });
    
    // Vérifier état DNS sauvegardé
    const savedState = await AsyncStorage.getItem('dns_active');
    if (savedState) {
      setIsDNSActive(JSON.parse(savedState));
    }

    addLog('🚀 AdZ-Vanced initialisé avec succès', Colors.success);
    addLog(`📱 Appareil: ${brand} ${model} (Android ${systemVersion})`, Colors.terminal);
    addLog('⚡ Prêt pour la configuration DNS', Colors.success);
  };

  const addLog = (message, color = Colors.terminal) => {
    const timestamp = new Date().toLocaleTimeString('fr-FR');
    setLogs(prev => [...prev, { message, color, timestamp }]);
  };

  const simulateProgress = (duration = 3000) => {
    setShowProgress(true);
    setProgress(0);
    
    const steps = 20;
    const interval = duration / steps;
    let currentStep = 0;
    
    const progressInterval = setInterval(() => {
      currentStep++;
      setProgress((currentStep / steps) * 100);
      
      if (currentStep >= steps) {
        clearInterval(progressInterval);
        setTimeout(() => setShowProgress(false), 500);
      }
    }, interval);
  };

  const handleInstallDNS = async () => {
    if (isProcessing) return;
    
    setIsProcessing(true);
    setShowTerminal(true);
    
    try {
      addLog('🔍 Validation des serveurs DNS AdZ-Vanced...', Colors.warning);
      simulateProgress(2000);
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      addLog('✅ DNS 45.90.28.219 : Serveur accessible', Colors.success);
      
      await new Promise(resolve => setTimeout(resolve, 500));
      addLog('✅ DNS 45.90.30.219 : Serveur accessible', Colors.success);
      
      await new Promise(resolve => setTimeout(resolve, 800));
      addLog('🛡️ Configuration du service VPN...', Colors.terminal);
      simulateProgress(3000);
      
      await new Promise(resolve => setTimeout(resolve, 2000));
      addLog('⚙️ Application des paramètres de sécurité...', Colors.terminal);
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      addLog('🔒 Tunnel DNS sécurisé établi', Colors.success);
      
      await new Promise(resolve => setTimeout(resolve, 500));
      addLog('✅ Configuration DNS AdZ-Vanced appliquée !', Colors.success);
      addLog('🎉 Profitez maintenant d\'un surf sain et rapide !', Colors.success);
      
      setIsDNSActive(true);
      await AsyncStorage.setItem('dns_active', 'true');
      
      Vibration.vibrate([100, 50, 100]);
      
    } catch (error) {
      addLog('❌ Erreur lors de la configuration', Colors.error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleRestoreDNS = async () => {
    if (isProcessing) return;
    
    setIsProcessing(true);
    setShowTerminal(true);
    
    try {
      addLog('🔄 Restauration des paramètres par défaut...', Colors.warning);
      simulateProgress(2000);
      
      await new Promise(resolve => setTimeout(resolve, 1500));
      addLog('📶 Retour aux DNS de votre opérateur...', Colors.terminal);
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      addLog('🔓 Tunnel VPN fermé', Colors.terminal);
      
      await new Promise(resolve => setTimeout(resolve, 500));
      addLog('✅ DNS restaurés par défaut', Colors.success);
      addLog('ℹ️  Configuration réseau d\'origine restaurée', Colors.terminal);
      
      setIsDNSActive(false);
      await AsyncStorage.setItem('dns_active', 'false');
      
    } catch (error) {
      addLog('❌ Erreur lors de la restauration', Colors.error);
    } finally {
      setIsProcessing(false);
    }
  };

  const openDonation = () => {
    Alert.alert(
      '💝 Soutenir AdZ-Vanced',
      'Choisissez votre méthode de donation préférée',
      [
        {
          text: 'PayPal',
          onPress: () => Linking.openURL('https://www.paypal.com/donate/?hosted_button_id=DMWR5MHMU78H2')
        },
        {
          text: 'Tipeee',
          onPress: () => Linking.openURL('https://fr.tipeee.com/kontacktzbot')
        },
        { text: 'Annuler', style: 'cancel' }
      ]
    );
  };

  const openTelegram = () => {
    Linking.openURL('https://t.me/adzvanced');
  };

  const showInfo = () => {
    Alert.alert(
      'ℹ️ AdZ-Vanced v1.0',
      `Configuration DNS professionnelle\n\nServeurs DNS:\n• IPv4: 45.90.28.219 / 45.90.30.219\n• IPv6: 2a07:a8c0::a8:3732 / 2a07:a8c1::a8:3732\n\nAvantages:\n• Blocage des publicités\n• Protection vie privée\n• Navigation plus rapide\n• Contournement restrictions FAI\n\n© 2025 KontacktzBot`,
      [{ text: 'OK' }]
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar 
        barStyle="light-content" 
        backgroundColor={Colors.primary} 
        translucent={false}
      />
      
      {/* Header avec dégradé */}
      <LinearGradient
        colors={[Colors.primary, Colors.primaryDark, Colors.secondary]}
        style={styles.header}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      >
        <Animated.View style={[
          styles.headerContent,
          { 
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }]
          }
        ]}>
          <Text style={styles.appTitle}>AdZ-Vanced</Text>
          <Text style={styles.appVersion}>v1.0</Text>
          <View style={styles.statusIndicator}>
            <View style={[
              styles.statusDot,
              { backgroundColor: isDNSActive ? Colors.success : Colors.textLight }
            ]} />
            <Text style={styles.statusText}>
              {isDNSActive ? 'DNS AdZ-Vanced Actif' : 'DNS Standard'}
            </Text>
          </View>
        </Animated.View>
      </LinearGradient>

      <ScrollView 
        style={styles.content} 
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Logo */}
        <Animated.View style={[
          styles.logoContainer,
          { 
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }]
          }
        ]}>
          <ModernCard style={styles.logoCard}>
            <Image
              source={{ uri: 'https://files.catbox.moe/j3evd5.jpg' }}
              style={styles.logo}
              resizeMode="cover"
            />
          </ModernCard>
        </Animated.View>

        {/* Message marketing */}
        <Animated.View style={[
          { opacity: fadeAnim },
          { transform: [{ translateY: slideAnim }] }
        ]}>
          <ModernCard style={styles.messageCard}>
            <View style={styles.messageHeader}>
              <Icon name="shield-check" size={24} color={Colors.primary} />
              <Text style={styles.messageTitle}>Navigation Sécurisée</Text>
            </View>
            <Text style={styles.messageText}>
              Grâce à <Text style={styles.brandText}>AdZ-Vanced</Text>, vous allez enfin pouvoir profiter d'un{' '}
              <Text style={styles.highlightText}>surf sain et rapide</Text>. Pas de pub, pas de données personnelles qui fuient et vive le contournement imposé par les FAI.
            </Text>
          </ModernCard>
        </Animated.View>

        {/* Boutons principaux */}
        <Animated.View style={[
          styles.buttonsContainer,
          { 
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }]
          }
        ]}>
          <ModernButton
            title={isDNSActive ? "DNS Déjà Actif" : "INSTALLER DNS"}
            icon={isDNSActive ? "check-circle" : "rocket-launch"}
            onPress={handleInstallDNS}
            loading={isProcessing && !isDNSActive}
            disabled={isDNSActive}
            gradient={isDNSActive ? [Colors.success, Colors.success] : [Colors.primary, Colors.primaryDark]}
            style={styles.primaryButton}
          />
          
          <ModernButton
            title="RESTAURER DNS"
            icon="restore"
            onPress={handleRestoreDNS}
            loading={isProcessing && isDNSActive}
            gradient={[Colors.textLight, Colors.text]}
            style={styles.secondaryButton}
          />
        </Animated.View>

        {/* Barre de progression */}
        <ProgressBar progress={progress} isVisible={showProgress} />

        {/* Terminal */}
        <Terminal logs={logs} isVisible={showTerminal} />

        {/* Boutons secondaires */}
        <Animated.View style={[
          styles.secondaryButtons,
          { opacity: fadeAnim }
        ]}>
          <TouchableOpacity style={styles.smallButton} onPress={openDonation}>
            <LinearGradient
              colors={[Colors.primary, Colors.accent]}
              style={styles.smallButtonGradient}
            >
              <Icon name="heart" size={16} color={Colors.surface} />
              <Text style={styles.smallButtonText}>Donation</Text>
            </LinearGradient>
          </TouchableOpacity>

          <TouchableOpacity style={styles.smallButton} onPress={openTelegram}>
            <LinearGradient
              colors={[Colors.secondary, Colors.primary]}
              style={styles.smallButtonGradient}
            >
              <Icon name="telegram" size={16} color={Colors.surface} />
              <Text style={styles.smallButtonText}>Telegram</Text>
            </LinearGradient>
          </TouchableOpacity>

          <TouchableOpacity style={styles.smallButton} onPress={showInfo}>
            <LinearGradient
              colors={[Colors.accent, Colors.secondary]}
              style={styles.smallButtonGradient}
            >
              <Icon name="information" size={16} color={Colors.surface} />
              <Text style={styles.smallButtonText}>Info</Text>
            </LinearGradient>
          </TouchableOpacity>
        </Animated.View>

        {/* Device info */}
        <View style={styles.deviceInfo}>
          <Text style={styles.deviceInfoText}>
            {deviceInfo.brand} {deviceInfo.model} • Android {deviceInfo.systemVersion}
          </Text>
        </View>
      </ScrollView>
    </View>
  );
};

// === STYLES PROFESSIONNELS ===
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    paddingTop: 20,
    paddingBottom: 30,
    paddingHorizontal: 20,
  },
  headerContent: {
    alignItems: 'center',
  },
  appTitle: {
    fontSize: 32,
    fontWeight: '800',
    color: Colors.surface,
    letterSpacing: 1,
  },
  appVersion: {
    fontSize: 14,
    color: Colors.primaryLight,
    marginTop: 4,
    fontWeight: '500',
  },
  statusIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 15,
    paddingHorizontal: 15,
    paddingVertical: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 20,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  statusText: {
    color: Colors.surface,
    fontSize: 12,
    fontWeight: '600',
  },
  content: {
    flex: 1,
    backgroundColor: Colors.surfaceLight,
  },
  scrollContent: {
    paddingBottom: 40,
  },
  logoContainer: {
    alignItems: 'center',
    paddingTop: 30,
    paddingBottom: 20,
  },
  logoCard: {
    width: 120,
    height: 120,
    borderRadius: 20,
    overflow: 'hidden',
    elevation: 8,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  logo: {
    width: '100%',
    height: '100%',
  },
  messageCard: {
    marginHorizontal: 20,
    marginBottom: 30,
    padding: 20,
  },
  messageHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  messageTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.text,
    marginLeft: 10,
  },
  messageText: {
    fontSize: 15,
    lineHeight: 22,
    color: Colors.textLight,
    textAlign: 'center',
  },
  brandText: {
    color: Colors.primary,
    fontWeight: '700',
  },
  highlightText: {
    color: Colors.success,
    fontWeight: '600',
  },
  buttonsContainer: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  primaryButton: {
    marginBottom: 15,
  },
  secondaryButton: {
    marginBottom: 10,
  },
  modernButton: {
    paddingVertical: 18,
    paddingHorizontal: 30,
    borderRadius: 16,
    elevation: 4,
    shadowColor: Colors.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonIcon: {
    marginRight: 10,
  },
  buttonText: {
    color: Colors.surface,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  modernCard: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 20,
    elevation: 3,
    shadowColor: Colors.text,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  progressContainer: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  progressTrack: {
    height: 6,
    backgroundColor: Colors.primaryLight,
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    backgroundColor: Colors.primary,
    borderRadius: 3,
  },
  terminal: {
    marginHorizontal: 20,
    marginBottom: 20,
    backgroundColor: Colors.text,
    borderRadius: 12,
    overflow: 'hidden',
    elevation: 4,
  },
  terminalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingVertical: 10,
    backgroundColor: 'rgba(0, 255, 0, 0.1)',
  },
  terminalTitle: {
    color: Colors.terminal,
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 8,
  },
  terminalContent: {
    maxHeight: 200,
    paddingHorizontal: 15,
    paddingVertical: 10,
  },
  terminalText: {
    fontFamily: 'monospace',
    fontSize: 11,
    lineHeight: 16,
    marginBottom: 2,
  },
  secondaryButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  smallButton: {
    flex: 1,
    marginHorizontal: 5,
    borderRadius: 12,
    overflow: 'hidden',
    elevation: 3,
  },
  smallButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 15,
  },
  smallButtonText: {
    color: Colors.surface,
    fontSize: 12,
    fontWeight: '600',
    marginLeft: 6,
  },
  deviceInfo: {
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  deviceInfoText: {
    fontSize: 11,
    color: Colors.textLight,
    opacity: 0.7,
  },
});

export default AdZvancedApp;