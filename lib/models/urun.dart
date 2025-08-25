class Urun {
  final int id;
  final String ad;
  final String modelNo;
  final String stokKodu;
  final String? qrKod;
  final String durum;

  Urun({
    required this.id,
    required this.ad,
    required this.modelNo,
    required this.stokKodu,
    required this.qrKod,
    required this.durum,
  });

  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      id: json['id'],
      ad: json['ad'],
      modelNo: json['model_no'],
      stokKodu: json['stok_kodu'],
      qrKod: json['qr_kod'], // null olabilir, bu yüzden String? dedik
      durum: json['durum'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'model_no': modelNo,
      'stok_kodu': stokKodu,
      'qr_kod': qrKod,
      'durum': durum,
    };
  }
}
