// lib/services/refresh_coordinator.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';

class RefreshCoordinator {
  RefreshCoordinator._();
  static final RefreshCoordinator I = RefreshCoordinator._();

  bool _isRefreshing = false;
  final List<Completer<void>> _waiters = [];
  static const Duration _timeout = Duration(seconds: 20);

  /// Her yerden bunu çağır: 401 alınca tek sefer refresh yapar.
  Future<bool> refreshOnce(String authBase) async {
    if (_isRefreshing) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
      // Buraya geldiğinde ya refresh başarılıdır ya da temizlenmiştir.
      // Token var mı yok mu kontrolü çağıran tarafa bırakılır.
      return (await TokenManager.getAccess()) != null;
    }

    _isRefreshing = true;
    try {
      final refresh = await TokenManager.getRefresh();
      if (refresh == null) return false;

      final uri = Uri.parse('$authBase/token/yenile/');
      final r = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh': refresh}),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;
        if (newAccess != null) {
          await TokenManager.updateAccess(newAccess);
          if (newRefresh != null) {
            await TokenManager.updateRefresh(newRefresh);
          }
          // bekleyenleri uyandır
          for (final w in _waiters) {
            if (!w.isCompleted) w.complete();
          }
          _waiters.clear();
          return true;
        }
      }

      // refresh de bitti/blacklist: her şeyi sil
      await TokenManager.clear();
      for (final w in _waiters) {
        if (!w.isCompleted) w.complete();
      }
      _waiters.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
