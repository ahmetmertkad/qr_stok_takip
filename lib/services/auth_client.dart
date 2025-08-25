// lib/services/auth_client.dart  (DÜZELTİLMİŞ)
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class AuthClient {
  AuthClient({
    required this.baseUrl, // Örn: http://10.0.2.2:8000/api  veya  http://10.0.2.2:8000/urun
    required this.authBase, // DAİMA: http://10.0.2.2:8000/api  (refresh burada)
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  final String baseUrl;
  final String authBase; // /api kökü
  final http.Client _inner;

  static const Duration _timeout = Duration(seconds: 20);

  // ---------- Public API ----------
  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return _inner.get(uri, headers: headers);
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return _inner.post(uri, headers: headers, body: json.encode(body));
    });
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return _inner.put(uri, headers: headers, body: json.encode(body));
    });
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendWithAutoRefresh(() async {
      final headers = await _authHeadersAsync();
      return _inner.delete(uri, headers: headers);
    });
  }

  // ---------- Core: 401 -> refresh -> retry-once ----------
  Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function() sender,
  ) async {
    http.Response r;
    try {
      r = await sender().timeout(_timeout);
    } on TimeoutException {
      rethrow;
    }

    if (r.statusCode != 401) return r;

    final ok = await _refreshAccessToken();
    if (!ok) return r;

    // Tekrar dene (1 kez), güncel access header'ı _authHeadersAsync() ile yeniden alınır
    return sender().timeout(_timeout);
  }

  // Her istekten hemen önce güncel access’i oku
  Future<Map<String, String>> _authHeadersAsync() async {
    final access = await TokenManager.getAccess();
    return {
      'Content-Type': 'application/json',
      if (access != null) 'Authorization': 'Bearer $access',
    };
  }

  // ---------- Refresh logic ----------
  Future<bool> _refreshAccessToken() async {
    final refresh = await TokenManager.getRefresh();
    if (refresh == null) return false;

    final uri = Uri.parse(
      '$authBase/token/yenile/',
    ); // <-- DAİMA /api üzerinden
    final r = await _inner
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refresh}),
        )
        .timeout(_timeout);

    if (r.statusCode == 200) {
      final data = json.decode(r.body) as Map<String, dynamic>;
      final newAccess = data['access'] as String?;
      final newRefresh = data['refresh'] as String?; // ROTATE açıksa gelir
      if (newAccess != null) {
        await TokenManager.updateAccess(newAccess);
        if (newRefresh != null) {
          await TokenManager.updateRefresh(newRefresh);
        }
        return true;
      }
    }

    // Refresh da geçersiz/blacklist/expire → temizle
    await TokenManager.clear();
    return false;
  }
}
