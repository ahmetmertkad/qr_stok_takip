// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // <-- eklendi (Platform için)
import 'package:http/http.dart' as http;

import 'package:siparis_takip/services/token_manager.dart';
import 'package:siparis_takip/services/refresh_coordinator.dart';

class ApiService {
  // /api kökü
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static const Duration _timeout = Duration(seconds: 20);

  // -------------------- Ortak yardımcılar --------------------

  static Map<String, String> _bearer(String? access) => {
    'Content-Type': 'application/json',
    if (access != null) 'Authorization': 'Bearer $access',
  };

  static Future<Map<String, String>> _authHeadersAsync() async {
    final access = await TokenManager.getAccess();
    return _bearer(access);
  }

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  /// 401 alırsa: **tekil refresh** → **aynı isteği yeniden dener**
  static Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function() sender,
  ) async {
    http.Response r;
    try {
      r = await sender().timeout(_timeout);
    } on TimeoutException {
      rethrow;
    }

    if (r.statusCode != 401) return r;

    final ok = await RefreshCoordinator.I.refreshOnce(_baseUrl);
    if (!ok) return r;

    // Yeni access header’ı _authHeadersAsync() ile yeniden alınır
    return sender().timeout(_timeout);
  }

  // -------------------- HTTP sarmalayıcılar --------------------

  static Future<http.Response> get(String path, {Map<String, String>? query}) {
    final uri = _uri(path, query);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return http.get(uri, headers: headers);
    });
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) {
    final uri = _uri(path);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return http.post(uri, headers: headers, body: json.encode(body));
    });
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) {
    final uri = _uri(path);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return http.put(uri, headers: headers, body: json.encode(body));
    });
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) {
    final uri = _uri(path);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return http.patch(uri, headers: headers, body: json.encode(body));
    });
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? query,
  }) {
    final uri = _uri(path, query);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return http.delete(uri, headers: headers);
    });
  }

  // -------------------- Hazır uç noktalar (örnekler) --------------------

  /// Giriş
  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final r = await http
        .post(
          _uri('/giris/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body) as Map<String, dynamic>;
      final access = decoded['access'] as String?;
      final refresh = decoded['refresh'] as String?;
      if (access != null && refresh != null) {
        await TokenManager.saveTokens(access: access, refresh: refresh);
      }
      return {
        'success': true,
        'access': access,
        'refresh': refresh,
        'username': decoded['kullanici']?['username'],
        'role': decoded['kullanici']?['role'],
      };
    }
    return {
      'success': false,
      'message': _safeMessage(r.body) ?? 'Giriş başarısız',
      'statusCode': r.statusCode,
    };
  }

  /// Kayıt
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
  }) async {
    final r = await http
        .post(
          _uri('/kayit/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    if (r.statusCode == 200 || r.statusCode == 201) {
      return {'success': true, 'message': 'Kayıt başarılı'};
    } else {
      return {
        'success': false,
        'message': _safeMessage(r.body) ?? 'Bir hata oluştu',
        'statusCode': r.statusCode,
      };
    }
  }

  /// Kullanıcı listesi
  static Future<List<Map<String, dynamic>>> getKullaniciListesi() async {
    final resp = await get('/kullanici_listesi/');
    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Kullanıcı listesi alınamadı: ${resp.statusCode}');
  }

  /// Rol güncelle
  static Future<Map<String, dynamic>> updateKullaniciRol({
    required int userId,
    required String rol,
  }) async {
    final resp = await put('/rol/$userId/', {'role': rol});
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return {
        'success': true,
        'data': data['kullanici'],
        'message': data['mesaj'] ?? 'Rol güncellendi',
      };
    } else {
      return {
        'success': false,
        'message': _safeMessage(resp.body) ?? 'Bir hata oluştu',
        'statusCode': resp.statusCode,
      };
    }
  }

  /// Aktiflik güncelle
  static Future<Map<String, dynamic>> updateKullaniciDurum({
    required int userId,
    required bool isActive,
  }) async {
    final resp = await put('/durum/$userId/', {'is_active': isActive});
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return {
        'success': true,
        'data': data['kullanici'],
        'message': data['mesaj'] ?? 'Durum güncellendi',
      };
    } else {
      return {
        'success': false,
        'message': _safeMessage(resp.body) ?? 'Bir hata oluştu',
        'statusCode': resp.statusCode,
      };
    }
  }

  // -------------------- FCM token uç noktaları --------------------

  /// Cihazın FCM token’ını backend’e kaydeder.
  /// Backend: POST /api/fcm/register/  ->  {token, platform}
  static Future<void> registerFcmToken(String fcmToken) async {
    final resp = await post('/fcm/register/', {
      'token': fcmToken,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'FCM token kaydedilemedi: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  /// (Opsiyonel) Çıkışta token’ı backend’den düşmek için.
  /// Backend: POST /api/fcm/unregister/  ->  {token}
  static Future<void> unregisterFcmToken(String fcmToken) async {
    try {
      final resp = await post('/fcm/unregister/', {'token': fcmToken});
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        // Sessiz geçmek istersen burayı yutabilirsin
        // throw Exception('FCM token silinemedi: ${resp.statusCode}');
      }
    } catch (_) {
      // yut
    }
  }

  // -------------------- yardımcılar --------------------

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String? _safeMessage(String body) {
    final m = _safeDecode(body);
    return (m['mesaj'] ?? m['message'] ?? m['detail'] ?? m['error']) as String?;
  }
}
