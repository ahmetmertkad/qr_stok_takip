// lib/models/urun_durum_model.dart
class UrunDurumModel {
  final String modelNo;
  final Map<String, int> durumlar;

  UrunDurumModel({required this.modelNo, required this.durumlar});

  factory UrunDurumModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> raw = Map<String, dynamic>.from(
      json['durumlar'] ?? {},
    );
    final Map<String, int> parsed = {};
    raw.forEach((k, v) {
      parsed[k] = (v as num).toInt();
    });

    return UrunDurumModel(
      modelNo: json['model_no'] as String? ?? '',
      durumlar: parsed,
    );
  }
}
