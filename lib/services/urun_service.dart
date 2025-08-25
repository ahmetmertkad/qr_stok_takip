// lib/services/urun_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:siparis_takip/models/aktivite.dart';

import 'package:siparis_takip/services/token_manager.dart';
import 'package:siparis_takip/services/refresh_coordinator.dart';

import '../models/urun.dart';
import '../models/detayli_urun.dart';

class UrunService {
  // Android emulator: 10.0.2.2, iOS simulator: localhost
  static const String _baseUrl = 'http://10.0.2.2:8000/urun/urunler';
  static const String _authBase = 'http://10.0.2.2:8000/api';
  static const String _logsBaseUrl =
      'http://10.0.2.2:8000/urun/urun-durum-gecmisi';
  static const Duration _timeout = Duration(seconds: 20);

  // -------------------- ORTAK YARDIMCILAR --------------------

  static Map<String, String> _bearerFrom(String? access) => {
    'Content-Type': 'application/json',
    if (access != null) 'Authorization': 'Bearer $access',
  };

  /// doSend(access) çağrısını yapar; 401 olursa tekil refresh ve retry.
  static Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function(String? access) doSend,
  ) async {
    String? access = await TokenManager.getAccess();

    http.Response r;
    try {
      r = await doSend(access).timeout(_timeout);
    } on TimeoutException {
      rethrow;
    }

    if (r.statusCode != 401) return r;

    final ok = await RefreshCoordinator.I.refreshOnce(_authBase);
    if (!ok) return r;

    final latest = await TokenManager.getAccess();
    return doSend(latest).timeout(_timeout);
  }

  // -------------------- İŞLEVLER --------------------

  /// ✅ Ürün Ekleme
  static Future<String?> urunEkle({
    required String ad,
    required String modelNo,
    required String stokKodu,
    required int adet,
  }) async {
    final uri = Uri.parse('$_baseUrl/');
    final resp = await _sendWithAutoRefresh(
      (access) => http.post(
        uri,
        headers: _bearerFrom(access),
        body: json.encode({
          'ad': ad,
          'model_no': modelNo,
          'stok_kodu': stokKodu,
          'adet': adet,
        }),
      ),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['qr_kod'];
    } else {
      throw Exception('Ürün ekleme hatası: ${resp.statusCode}\n${resp.body}');
    }
  }

  /// ✅ Dropdown için adlar
  static Future<List<String>> getAdlar() async {
    final uri = Uri.parse('$_baseUrl/filtre-secimleri/');
    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return List<String>.from(data['adlar'] ?? []);
    } else {
      throw Exception("Adlar alınamadı: ${resp.statusCode}\n${resp.body}");
    }
  }

  /// ✅ Kullanıcı adları (dropdown için)
  // UrunService içinde

  static Future<List<String>> getKullaniciAdlari() async {
    final uri = Uri.parse('$_logsBaseUrl/kullanici-adlari/'); // <-- DOĞRU

    final resp = await _sendWithAutoRefresh(
      (a) => http.get(uri, headers: _bearerFrom(a)),
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return List<String>.from(data);
    } else {
      throw Exception(
        'Kullanıcı adları alınamadı: ${resp.statusCode}\n${resp.body}',
      );
    }
  }

  /// ✅ Username'e göre aktivite listesi
  static Future<List<Aktivite>> kullaniciAktiviteleriByUsername(
    String username,
  ) async {
    // /urun-durum-gecmisi/kullanici/<username>/
    final uri = Uri.parse(
      '$_logsBaseUrl/kullanici/${Uri.encodeComponent(username)}/',
    );

    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data
          .map((e) => Aktivite.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (resp.statusCode == 404) {
      // kullanıcı yoksa boş liste döndür
      return <Aktivite>[];
    } else {
      throw Exception(
        "Aktiviteler alınamadı: ${resp.statusCode}\n${resp.body}",
      );
    }
  }

  /// ✅ Seçilen ada göre modeller
  static Future<List<String>> getModeller(String ad) async {
    final uri = Uri.parse(
      '$_baseUrl/modeller/',
    ).replace(queryParameters: {'ad': ad});

    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return List<String>.from(data['modeller'] ?? []);
    } else {
      throw Exception("Modeller alınamadı: ${resp.statusCode}\n${resp.body}");
    }
  }

  /// ✅ Ürün detay + durum geçmişi (tek ürün)
  static Future<Map<String, dynamic>> getDetayliBilgi({
    required int urunId,
  }) async {
    final uri = Uri.parse("$_baseUrl/$urunId/detayli-bilgi/");
    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception("Ürün detay bilgisi alınamadı: ${resp.statusCode}");
    }
  }

  /// ✅ Ad + model_no ile filtreleme
  static Future<List<Urun>> filtrele({
    required String ad,
    required String modelNo,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/filtrele/',
    ).replace(queryParameters: {'ad': ad, 'model_no': modelNo});

    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data.map((e) => Urun.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception("Filtreleme hatası: ${resp.statusCode}\n${resp.body}");
    }
  }

  /// ✅ QR ile ürün bulma (stok_kodu)
  static Future<Urun?> qrIleBul(String stokKodu) async {
    final uri = Uri.parse(
      '$_baseUrl/qr-bul/',
    ).replace(queryParameters: {'stok_kodu': stokKodu});

    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return Urun.fromJson(data as Map<String, dynamic>);
    } else if (resp.statusCode == 404) {
      return null; // ürün bulunamadı
    } else {
      throw Exception("QR ile ürün bulma hatası: ${resp.statusCode}");
    }
  }

  /// ✅ DURUM DEĞİŞTİR (geçmiş kaydı da tutulur)
  /// POST /urunler/{id}/durum-degistir/
  static Future<Urun?> durumDegistir({
    required int urunId,
    required String yeniDurum,
    String? aciklama,
  }) async {
    final uri = Uri.parse('$_baseUrl/$urunId/durum-degistir/');
    final resp = await _sendWithAutoRefresh(
      (access) => http.post(
        uri,
        headers: _bearerFrom(access),
        body: json.encode({
          'yeni_durum': yeniDurum,
          'aciklama': aciklama ?? '',
        }),
      ),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      if (data is Map && data.containsKey('detail')) {
        // Örn: {"detail":"Durum zaten bu değer."}
        return null;
      }
      return Urun.fromJson(data as Map<String, dynamic>);
    } else if (resp.statusCode == 400) {
      return null; // Geçersiz durum vb.
    } else {
      throw Exception(
        'Durum değiştir hatası: ${resp.statusCode}\n${resp.body}',
      );
    }
  }

  /// 🆕 Detaylı liste (ürün + durum geçmişi), duruma göre filtre
  /// GET /urunler/detayli-liste/?durum=...&durum_list=...&limit=...
  static Future<List<DetayliUrun>> detayliListe({
    String? durum,
    List<String>? durumList,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (durum != null && durum.isNotEmpty) params['durum'] = durum;
    if (durumList != null && durumList.isNotEmpty) {
      params['durum_list'] = durumList.join(',');
    }
    if (limit != null && limit > 0) params['limit'] = '$limit';

    final uri = Uri.parse(
      '$_baseUrl/detayli-liste/',
    ).replace(queryParameters: params);

    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      return data
          .map((e) => DetayliUrun.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (resp.statusCode == 400) {
      throw Exception('Geçersiz istek (400): ${resp.body}');
    } else if (resp.statusCode == 401) {
      throw Exception('Yetkisiz (401): token kontrol edin.');
    } else {
      throw Exception('detayli-liste hatası: ${resp.statusCode} ${resp.body}');
    }
  }

  /// 🆕 Durum seçenekleri
  /// GET /urunler/durum-secimleri/
  static Future<List<Map<String, String>>> getDurumSecimleri() async {
    final uri = Uri.parse('$_baseUrl/durum-secimleri/');
    final resp = await _sendWithAutoRefresh(
      (access) => http.get(uri, headers: _bearerFrom(access)),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final list = (data['choices'] as List?) ?? [];
      return List<Map<String, String>>.from(
        list.map(
          (e) => {'value': e['value'] as String, 'label': e['label'] as String},
        ),
      );
    } else {
      throw Exception('Durum seçimleri alınamadı: ${resp.statusCode}');
    }
  }
}
