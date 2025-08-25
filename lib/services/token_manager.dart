// lib/services/token_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setString(_kRefresh, refresh);
  }

  static Future<String?> getAccess() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  static Future<String?> getRefresh() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  static Future<void> updateAccess(String access) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
  }

  static Future<void> updateRefresh(String refresh) async {
    // << EKLENDİ
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRefresh, refresh);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }
}
