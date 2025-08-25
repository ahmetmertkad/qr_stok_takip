import 'package:flutter/material.dart';
import 'package:siparis_takip/models/urun.dart';
import 'package:siparis_takip/services/urun_service.dart';

class UrunTanimlamaSayfasi extends StatefulWidget {
  final Urun urun;

  const UrunTanimlamaSayfasi({super.key, required this.urun});

  @override
  State<UrunTanimlamaSayfasi> createState() => _UrunTanimlamaSayfasiState();
}

class _UrunTanimlamaSayfasiState extends State<UrunTanimlamaSayfasi> {
  final _aciklamaCtrl = TextEditingController();
  bool _loading = false;

  // DRF choices ile aynı olmalı
  static const List<String> _durumlar = [
    'stokta',
    'satildi',
    'incelemede',
    'hasarli',
    'iade',
    'rezerve',
    'silindi',
  ];

  String? _yeniDurum;

  @override
  void initState() {
    super.initState();
    _yeniDurum = widget.urun.durum; // mevcut durum seçili gelsin
  }

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_yeniDurum == null || _yeniDurum!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yeni bir durum seçin.')),
      );
      return;
    }

    setState(() => _loading = true);

    final guncelUrun = await UrunService.durumDegistir(
      urunId: widget.urun.id!,
      yeniDurum: _yeniDurum!,
      aciklama: _aciklamaCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (guncelUrun != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Durum güncellendi.')));
      Navigator.of(context).pop(guncelUrun); // üst sayfaya güncel ürünü gönder
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi ya da zaten aynı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Tanımlama"),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${widget.urun.ad} - ${widget.urun.modelNo}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Stok Kodu: ${widget.urun.stokKodu}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mevcut Durum: ${widget.urun.durum}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  value: _yeniDurum,
                  decoration: InputDecoration(
                    labelText: "Yeni Durum",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items:
                      _durumlar
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged:
                      _loading
                          ? null
                          : (val) => setState(() => _yeniDurum = val),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _aciklamaCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Açıklama (opsiyonel)",
                    hintText: "Örn: Taşıma sırasında çizik tespit edildi.",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text("Kaydet"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
