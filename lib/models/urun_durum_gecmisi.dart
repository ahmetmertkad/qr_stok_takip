// models/urun_durum_gecmisi.dart
class UrunDurumGecmisi {
  final int id;
  final String? oncekiDurum;
  final String yeniDurum;
  final String aciklama;
  final DateTime tarih;
  final int? yapan; // kullanıcı id (backend böyle döndürüyor)

  UrunDurumGecmisi({
    required this.id,
    required this.oncekiDurum,
    required this.yeniDurum,
    required this.aciklama,
    required this.tarih,
    required this.yapan,
  });

  factory UrunDurumGecmisi.fromJson(Map<String, dynamic> j) {
    return UrunDurumGecmisi(
      id: j['id'] as int,
      oncekiDurum: j['onceki_durum'] as String?,
      yeniDurum: j['yeni_durum'] as String,
      aciklama: (j['aciklama'] ?? '') as String,
      tarih: DateTime.parse(j['tarih'] as String),
      yapan: j['yapan'] as int?,
    );
  }
}
