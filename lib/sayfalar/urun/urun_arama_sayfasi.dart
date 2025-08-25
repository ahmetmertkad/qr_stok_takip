import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:siparis_takip/models/urun.dart';
import 'package:siparis_takip/services/urun_service.dart';

class UrunAramaSayfasi extends StatefulWidget {
  const UrunAramaSayfasi({super.key});

  @override
  State<UrunAramaSayfasi> createState() => _UrunAramaSayfasiState();
}

class _UrunAramaSayfasiState extends State<UrunAramaSayfasi> {
  List<String> adlar = [];
  List<String> modeller = [];
  String? seciliAd;
  String? seciliModel;
  List<Urun> urunler = [];
  bool yukleniyor = false;

  Map<String, dynamic>? seciliDetay;
  bool detayYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _adlariGetir();
  }

  Future<void> _adlariGetir() async {
    try {
      final gelenAdlar = await UrunService.getAdlar();
      setState(() {
        adlar = gelenAdlar;
      });
    } catch (e) {
      print("Adlar alınamadı: $e");
    }
  }

  Future<void> _modelleriGetir(String ad) async {
    try {
      final gelenModeller = await UrunService.getModeller(ad);
      setState(() {
        modeller = gelenModeller;
        seciliModel = null;
      });
    } catch (e) {
      print("Modeller alınamadı: $e");
    }
  }

  Future<void> _urunleriFiltrele() async {
    if (seciliAd == null || seciliModel == null) return;

    setState(() {
      yukleniyor = true;
      urunler = [];
      seciliDetay = null;
    });

    try {
      final gelenUrunler = await UrunService.filtrele(
        ad: seciliAd!,
        modelNo: seciliModel!,
      );
      setState(() {
        urunler = gelenUrunler;
        yukleniyor = false;
      });
    } catch (e) {
      print("Ürünler alınamadı: $e");
      setState(() {
        yukleniyor = false;
      });
    }
  }

  Future<void> _detayGetir(Urun urun) async {
    setState(() {
      detayYukleniyor = true;
      seciliDetay = null;
    });

    try {
      final detay = await UrunService.getDetayliBilgi(urunId: urun.id!);
      setState(() {
        seciliDetay = detay;
        detayYukleniyor = false;
      });
    } catch (e) {
      print("Detay alınamadı: $e");
      setState(() => detayYukleniyor = false);
    }
  }

  Widget _buildDropdown<T>(
    String label,
    List<T> items,
    T? value,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDetayKarti() {
    if (detayYukleniyor) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (seciliDetay == null) return const SizedBox();

    final urun = seciliDetay!['urun'];
    final durumlar = List<Map<String, dynamic>>.from(
      seciliDetay!['durum_gecmisi'],
    );

    return Card(
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${urun['ad']} - ${urun['model_no']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Stok Kodu: ${urun['stok_kodu']}"),
            const SizedBox(height: 10),
            const Text(
              "Durum Geçmişi:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...durumlar.map(
              (d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timeline),
                title: Text(d['durum'] ?? d['yeni_durum_label'] ?? '-'),
                subtitle: Text(
                  "Tarih: ${d['tarih']} - Yapan: ${d['yapan_username'] ?? '?'}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Arama"),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.search, size: 48, color: Colors.indigo),
                      const SizedBox(height: 16),
                      const Text(
                        "Ürünleri Filtrele",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown("Ürün Adı", adlar, seciliAd, (val) {
                        setState(() {
                          seciliAd = val;
                          modeller = [];
                          seciliModel = null;
                          urunler = [];
                          seciliDetay = null;
                        });
                        if (val != null) _modelleriGetir(val);
                      }),
                      _buildDropdown("Model No", modeller, seciliModel, (val) {
                        setState(() => seciliModel = val);
                      }),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _urunleriFiltrele,
                        icon: const Icon(Icons.search),
                        label: const Text("Ara"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetayKarti(),
                      yukleniyor
                          ? const CircularProgressIndicator()
                          : urunler.isEmpty
                          ? const Center(child: Text("Hiçbir ürün bulunamadı."))
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: urunler.length,
                            itemBuilder: (context, index) {
                              final u = urunler[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text("${u.ad} - ${u.modelNo}"),
                                  subtitle: Text("Stok Kodu: ${u.stokKodu}"),
                                  trailing: Image.network(
                                    u.qrKod ?? '',
                                    width: 50,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            const Icon(Icons.qr_code),
                                  ),
                                  onTap: () => _detayGetir(u),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
