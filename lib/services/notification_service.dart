// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:siparis_takip/services/api_service.dart'; // fetchUnreadCount(), registerFcmToken()

/// AppBar zil rozetinde kullanacağın global sayaç
final ValueNotifier<int> unreadCounter = ValueNotifier<int>(0);

/// Uygulama içi “bildirim geldi” olaylarını dinlemek istersen
final StreamController<Map<String, dynamic>> notificationStream =
    StreamController<Map<String, dynamic>>.broadcast();

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Android kanal (sabit)
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'Yüksek Öncelikli Bildirimler',
        description: 'Ön planda gösterilen ve önemli bildirimler için kanal',
        importance: Importance.max,
      );

  /// Login tamamlandıktan sonra çağır (token kaydı ve dinleyiciler burada kurulur)
  Future<void> initAfterLogin({BuildContext? context}) async {
    // Firebase init
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

    // iOS foreground davranışı (Android’de etkisiz)
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local Notifications init
    await _initLocalNotifications();

    // --- TOKEN KAYIT ---
    final token = await _fm.getToken();
    debugPrint('FCM TOKEN (ilk): $token');
    if (token != null) {
      await _safeRegisterToken(token);
    }

    // Login sonrası unread sayıyı çek (zil rozeti)
    await _refreshUnread();

    // Listener’ları tek sefer kur
    if (_initialized) return;
    _initialized = true;

    // Token yenilenirse kaydet
    _fm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM TOKEN REFRESH: $newToken');
      await _safeRegisterToken(newToken);
    });

    // ÖN PLAN: local notification + sayaç artır + event yayınla
    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      final title = m.notification?.title ?? 'Bildirim';
      final body = m.notification?.body ?? '';
      await _showLocal(title: title, body: body, payload: m.data);

      // sayaç +1 (kutuda okundu yapınca sen azaltacaksın)
      unreadCounter.value = unreadCounter.value + 1;

      // İstersen ekranlarda dinle
      notificationStream.add({'title': title, 'body': body, 'data': m.data});
    });

    // ARKA PLAN: bildirime tıklayıp app’e gelince
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
      _handleNavigation(m.data);
    });

    // APP KAPALIYKEN: bildirime tıklayıp açıldıysa
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _handleNavigation(initial.data);
    }
  }

  /// Dışarıdan da çağrılabilsin (örn. bildirim ekranından geri dönünce)
  Future<void> refreshUnreadPublic() => _refreshUnread();

  // ------------------ PRIVATE ------------------

  Future<void> _initLocalNotifications() async {
    await _flnp
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flnp.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        // İstersen payload’a göre sayfa yönlendirme yap.
        // _handleNavigation(parsePayload(resp.payload));
      },
    );
  }

  Future<void> _showLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // benzersiz id
      title,
      body,
      details,
      payload: payload == null ? null : payload.toString(),
    );
  }

  Future<void> _refreshUnread() async {
    try {
      final count =
          await ApiService.fetchUnreadCount(); // <-- DRF: /notifications/unread-count/
      unreadCounter.value = count;
    } catch (e) {
      debugPrint('unread-count hatası: $e');
    }
  }

  Future<void> _safeRegisterToken(String token) async {
    try {
      await ApiService.registerFcmToken(token); // <-- DRF: /devices/
      debugPrint('FCM token kaydedildi.');
    } catch (e) {
      final msg = e.toString();
      // unique token zaten varsa akışı bozma
      if (msg.contains('already exists')) {
        debugPrint('FCM token zaten kayıtlı.');
      } else {
        debugPrint('FCM token kayıt hatası: $e');
      }
    }
  }

  void _handleNavigation(Map<String, dynamic> data) {
    // Örn:
    // if (data['type'] == 'urun_ekleme') { // ilgili sayfaya git }
  }
}
