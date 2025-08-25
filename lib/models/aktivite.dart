// lib/models/aktivite.dart
class Aktivite {
  final int id;
  final int urun;
  final String? oncekiDurum;
  final String? oncekiDurumLabel;
  final String yeniDurum;
  final String yeniDurumLabel;
  final String? aciklama;
  final DateTime tarih;
  final int? yapan;
  final String? yapanUsername;

  Aktivite({
    required this.id,
    required this.urun,
    required this.oncekiDurum,
    required this.oncekiDurumLabel,
    required this.yeniDurum,
    required this.yeniDurumLabel,
    required this.aciklama,
    required this.tarih,
    required this.yapan,
    required this.yapanUsername,
  });

  factory Aktivite.fromJson(Map<String, dynamic> j) {
    return Aktivite(
      id: j['id'] as int,
      urun: j['urun'] as int,
      oncekiDurum: j['onceki_durum'] as String?,
      oncekiDurumLabel: j['onceki_durum_label'] as String?,
      yeniDurum: j['yeni_durum'] as String,
      yeniDurumLabel: j['yeni_durum_label'] as String,
      aciklama: j['aciklama'] as String?,
      tarih: DateTime.parse(j['tarih'] as String),
      yapan: j['yapan'] as int?,
      yapanUsername: j['yapan_username'] as String?,
    );
  }
}
