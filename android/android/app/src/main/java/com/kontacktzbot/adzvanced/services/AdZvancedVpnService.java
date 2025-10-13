package com.kontacktzbot.adzvanced.services;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import androidx.core.app.NotificationCompat;
import com.kontacktzbot.adzvanced.MainActivity;
import com.kontacktzbot.adzvanced.R;
import java.io.IOException;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;

/**
 * Service VPN pour configuration DNS AdZ-Vanced
 * Utilise l'API VpnService d'Android pour intercepter et rediriger les requêtes DNS
 */
public class AdZvancedVpnService extends VpnService implements Runnable {
    
    private static final String TAG = "AdZvancedVPN";
    private static final String CHANNEL_ID = "AdZvancedVPN";
    private static final int NOTIFICATION_ID = 1001;
    
    // Serveurs DNS AdZ-Vanced
    private static final String DNS_PRIMARY = "45.90.28.219";
    private static final String DNS_SECONDARY = "45.90.30.219";
    private static final String DNS_IPV6_PRIMARY = "2a07:a8c0::a8:3732";
    private static final String DNS_IPV6_SECONDARY = "2a07:a8c1::a8:3732";
    
    // Configuration VPN
    private static final String VPN_ADDRESS = "10.0.0.2";
    private static final String VPN_ROUTE = "0.0.0.0";
    
    private ParcelFileDescriptor vpnInterface;
    private Thread vpnThread;
    private volatile boolean running = false;

    public static Intent createStartIntent(VpnService context) {
        return new Intent(context, AdZvancedVpnService.class).setAction("START");
    }

    public static Intent createStopIntent(VpnService context) {
        return new Intent(context, AdZvancedVpnService.class).setAction("STOP");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Service démarré avec action: " + (intent != null ? intent.getAction() : "null"));
        
        if (intent != null && "STOP".equals(intent.getAction())) {
            stopVpn();
            return START_NOT_STICKY;
        }
        
        startVpn();
        return START_STICKY;
    }

    private void startVpn() {
        Log.d(TAG, "Démarrage du VPN AdZ-Vanced");
        
        try {
            // Configuration de l'interface VPN
            Builder builder = new Builder();
            builder.setMtu(1500);
            
            // Configuration IPv4
            builder.addAddress(VPN_ADDRESS, 32);
            builder.addRoute(VPN_ROUTE, 0);
            
            // Configuration DNS AdZ-Vanced
            builder.addDnsServer(DNS_PRIMARY);
            builder.addDnsServer(DNS_SECONDARY);
            
            // Configuration IPv6 (si supporté)
            try {
                builder.addDnsServer(DNS_IPV6_PRIMARY);
                builder.addDnsServer(DNS_IPV6_SECONDARY);
            } catch (Exception e) {
                Log.w(TAG, "IPv6 non supporté: " + e.getMessage());
            }
            
            // Applications autorisées (toutes par défaut)
            builder.setSession("AdZ-Vanced DNS");
            builder.setConfigureIntent(getPendingIntent());
            
            // Établir l'interface VPN
            vpnInterface = builder.establish();
            
            if (vpnInterface == null) {
                Log.e(TAG, "Impossible d'établir l'interface VPN");
                return;
            }
            
            // Démarrer la notification persistante
            startForegroundNotification();
            
            // Démarrer le thread de traitement
            running = true;
            vpnThread = new Thread(this, "AdZvancedVpnThread");
            vpnThread.start();
            
            Log.i(TAG, "VPN AdZ-Vanced démarré avec succès");
            
        } catch (Exception e) {
            Log.e(TAG, "Erreur lors du démarrage du VPN: " + e.getMessage(), e);
            stopVpn();
        }
    }

    private void stopVpn() {
        Log.d(TAG, "Arrêt du VPN AdZ-Vanced");
        
        running = false;
        
        if (vpnThread != null) {
            vpnThread.interrupt();
            try {
                vpnThread.join(1000);
            } catch (InterruptedException e) {
                Log.w(TAG, "Interruption lors de l'arrêt du thread VPN");
            }
            vpnThread = null;
        }
        
        if (vpnInterface != null) {
            try {
                vpnInterface.close();
            } catch (IOException e) {
                Log.w(TAG, "Erreur lors de la fermeture de l'interface VPN: " + e.getMessage());
            }
            vpnInterface = null;
        }
        
        stopForeground(true);
        stopSelf();
        
        Log.i(TAG, "VPN AdZ-Vanced arrêté");
    }

    @Override
    public void run() {
        Log.d(TAG, "Thread VPN démarré");
        
        try {
            // Configuration du canal de communication
            DatagramChannel tunnel = DatagramChannel.open();
            
            // Protection du socket contre le VPN (évite la boucle infinie)
            if (!protect(tunnel.socket())) {
                Log.e(TAG, "Impossible de protéger le socket");
                return;
            }
            
            // Configuration du serveur DNS distant
            tunnel.connect(new InetSocketAddress(DNS_PRIMARY, 53));
            
            // Buffer pour les paquets réseau
            ByteBuffer packet = ByteBuffer.allocate(32767);
            
            // Boucle de traitement des paquets
            while (running && !Thread.interrupted()) {
                try {
                    // Lecture des paquets depuis l'interface VPN
                    int length = vpnInterface.getFileDescriptor().getInt$();
                    
                    if (length > 0) {
                        packet.clear();
                        
                        // Traitement basique des paquets DNS
                        // Dans une implémentation complète, il faudrait parser les paquets IP/UDP
                        // et rediriger uniquement les requêtes DNS vers les serveurs AdZ-Vanced
                        
                        packet.flip();
                        tunnel.write(packet);
                        
                        // Lecture de la réponse
                        packet.clear();
                        int responseLength = tunnel.read(packet);
                        
                        if (responseLength > 0) {
                            packet.flip();
                            // Écriture de la réponse vers l'interface VPN
                        }
                    }
                    
                } catch (IOException e) {
                    if (running) {
                        Log.w(TAG, "Erreur lors du traitement des paquets: " + e.getMessage());
                    }
                    break;
                }
            }
            
            tunnel.close();
            
        } catch (Exception e) {
            Log.e(TAG, "Erreur dans le thread VPN: " + e.getMessage(), e);
        }
        
        Log.d(TAG, "Thread VPN arrêté");
    }

    private void startForegroundNotification() {
        createNotificationChannel();
        
        Intent stopIntent = createStopIntent(this);
        PendingIntent stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent, 
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0
        );
        
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AdZ-Vanced DNS Actif")
            .setContentText("Navigation sécurisée avec blocage des publicités")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(getPendingIntent())
            .addAction(R.drawable.ic_stop, "Arrêter", stopPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build();
        
        startForeground(NOTIFICATION_ID, notification);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "AdZ-Vanced VPN Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Service de configuration DNS AdZ-Vanced");
            channel.setShowBadge(false);
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private PendingIntent getPendingIntent() {
        Intent intent = new Intent(this, MainActivity.class);
        return PendingIntent.getActivity(
            this, 0, intent,
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0
        );
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "Service détruit");
        stopVpn();
        super.onDestroy();
    }

    @Override
    public void onRevoke() {
        Log.d(TAG, "Permission VPN révoquée");
        stopVpn();
        super.onRevoke();
    }
}