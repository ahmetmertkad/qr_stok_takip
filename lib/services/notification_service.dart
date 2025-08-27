import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:siparis_takip/services/api_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Android kanal (sabit kalsın)
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Yüksek Öncelikli Bildirimler',
        description: 'Ön planda gösterilen ve önemli bildirimler için kanal',
        importance: Importance.max,
      );

  Future<void> initAfterLogin({BuildContext? context}) async {
    // Firebase başlatılmış mı emin ol
    try {
      Firebase.app();
    } catch (_) {
      await Firebase.initializeApp();
    }

    // Bildirim izni
    final perm = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${perm.authorizationStatus}');

    // iOS ön plan davranışı (Android’de etkisiz)
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local Notifications init (DEFAULT ICON: @mipmap/ic_launcher)
    await _initLocalNotifications();

    // --- TOKEN KAYIT ---
    String? token = await _fm.getToken();
    debugPrint('FCM TOKEN (ilk): $token');
    if (token != null) {
      try {
        await ApiService.registerFcmToken(token);
        debugPrint('FCM token /api/devices/ ile kaydedildi.');
      } catch (e) {
        final msg = e.toString();
        // token zaten kayıtlıysa akışı bozma
        if (msg.contains('already exists')) {
          debugPrint('FCM token zaten kayıtlı, devam ediliyor.');
        } else {
          debugPrint('devices POST error: $e');
        }
      }
    }

    // Listener'ları tek sefer kur
    if (!_initialized) {
      _initialized = true;

      _fm.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM TOKEN REFRESH: $newToken');
        try {
          await ApiService.registerFcmToken(newToken);
        } catch (e) {
          if (!e.toString().contains('already exists')) {
            debugPrint('Token refresh kaydetme hatası: $e');
          }
        }
      });

      // ÖN PLAN: local notification ile göster
      FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
        final title = m.notification?.title ?? 'Bildirim';
        final body = m.notification?.body ?? '';
        await _showLocal(title: title, body: body, payload: m.data);
      });

      // ARKA PLANDA bildirime tıklama
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
        _handleNavigation(m.data);
      });

      // Uygulama tamamen kapalıyken bildirime tıklayıp açma
      final initial = await _fm.getInitialMessage();
      if (initial != null) {
        _handleNavigation(initial.data);
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    // Android kanal oluştur
    await _flnp
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // DEFAULT ICON: uygulama launcher iconu
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flnp.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        // İstersen burada payload’a göre sayfa yönlendirme yapabilirsin.
      },
    );
  }

  Future<void> _showLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    // icon belirtmedik -> initialization’daki default (@mipmap/ic_launcher) kullanılır
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // benzersiz id
      title,
      body,
      details,
    );
  }

  void _handleNavigation(Map<String, dynamic> data) {
    // Örn:
    // if (data['type'] == 'urun_ekleme') { ... sayfaya git ... }
  }
}
