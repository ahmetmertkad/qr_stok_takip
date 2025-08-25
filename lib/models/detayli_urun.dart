// models/detayli_urun.dart
import 'urun.dart';
import 'urun_durum_gecmisi.dart';

class DetayliUrun {
  final Urun urun;
  final List<UrunDurumGecmisi> durumGecmisi;

  DetayliUrun({required this.urun, required this.durumGecmisi});

  factory DetayliUrun.fromJson(Map<String, dynamic> j) {
    final urunJson = j['urun'] as Map<String, dynamic>;
    final List<dynamic> list = j['durum_gecmisi'] as List<dynamic>;
    return DetayliUrun(
      urun: Urun.fromJson(urunJson),
      durumGecmisi:
          list
              .map((e) => UrunDurumGecmisi.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
