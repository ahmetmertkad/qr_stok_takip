// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:siparis_takip/sayfalar/oturum/giris.dart';

/// App kapalıyken/arkaplanda gelen FCM mesajlarını işler.
/// Bu fonksiyon farklı bir isolate'ta çalışır; o yüzden
/// mutlaka entry-point ve initialize guard ekliyoruz.
@pragma('vm:entry-point') // <<< ÖNEMLİ
Future<void> _firebaseBg(RemoteMessage message) async {
  // Default app yoksa burada başlat (release'de şart)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  // debug:
  // print('BG notification: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama (foreground) için Firebase'i başlat
  await Firebase.initializeApp();

  // Background mesaj handler'ı bağla (runApp'ten önce olmalı)
  FirebaseMessaging.onBackgroundMessage(_firebaseBg);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipariş Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GirisSayfasi(),
    );
  }
}
