class GunlukItem {
  final DateTime tarih;
  final int adet;
  GunlukItem(this.tarih, this.adet);

  factory GunlukItem.fromJson(Map<String, dynamic> j) =>
      GunlukItem(DateTime.parse(j['tarih'].toString()), j['adet'] as int);
}

class SonDegisimItem {
  final String urun;
  final String? onceki;
  final String yeni;
  final String yapan;
  final DateTime tarih;
  SonDegisimItem(this.urun, this.onceki, this.yeni, this.yapan, this.tarih);

  factory SonDegisimItem.fromJson(Map<String, dynamic> j) => SonDegisimItem(
    j['urun'].toString(),
    j['onceki'] == null ? null : j['onceki'].toString(),
    j['yeni'].toString(),
    j['yapan'].toString(),
    DateTime.parse(j['tarih'].toString()),
  );
}

class TopKullaniciItem {
  final String kullanici;
  final int adet;
  TopKullaniciItem(this.kullanici, this.adet);

  factory TopKullaniciItem.fromJson(Map<String, dynamic> j) =>
      TopKullaniciItem(j['kullanici'].toString(), j['adet'] as int);
}

class KritikStokItem {
  final String ad;
  final String modelNo;
  final int adet;
  KritikStokItem(this.ad, this.modelNo, this.adet);

  factory KritikStokItem.fromJson(Map<String, dynamic> j) => KritikStokItem(
    j['ad'].toString(),
    j['model_no'].toString(),
    j['adet'] as int,
  );
}

class DashboardData {
  final int toplamUrun;
  final int bugunEklenen;
  final Map<String, int> durumSayilari;
  final List<GunlukItem> son7GunEklenen;
  final List<SonDegisimItem> sonDegisimler;
  final List<TopKullaniciItem> topKullanicilar;
  final List<KritikStokItem> kritikStok;

  DashboardData({
    required this.toplamUrun,
    required this.bugunEklenen,
    required this.durumSayilari,
    required this.son7GunEklenen,
    required this.sonDegisimler,
    required this.topKullanicilar,
    required this.kritikStok,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    toplamUrun: j['toplam_urun'] as int,
    bugunEklenen: j['bugun_eklenen'] as int,
    durumSayilari: Map<String, int>.from(j['durum_sayilari'] as Map),
    son7GunEklenen:
        List.from(
          j['son_7_gun_eklenen'],
        ).map<GunlukItem>((e) => GunlukItem.fromJson(e)).toList(),
    sonDegisimler:
        List.from(
          j['son_degisimler'],
        ).map<SonDegisimItem>((e) => SonDegisimItem.fromJson(e)).toList(),
    topKullanicilar:
        List.from(
          j['top_kullanicilar'],
        ).map<TopKullaniciItem>((e) => TopKullaniciItem.fromJson(e)).toList(),
    kritikStok:
        List.from(
          j['kritik_stok'],
        ).map<KritikStokItem>((e) => KritikStokItem.fromJson(e)).toList(),
  );
}
