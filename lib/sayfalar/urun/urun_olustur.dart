// lib/sayfalar/urun/urun_olustur.dart
import 'dart:convert';
import 'package:flutter/material.dart';
// http artık kullanılmıyor; merkezi servis kullanacağız
import 'package:siparis_takip/services/urun_service.dart';

class UrunOlusturSayfasi extends StatefulWidget {
  const UrunOlusturSayfasi({super.key});

  @override
  State<UrunOlusturSayfasi> createState() => _UrunOlusturSayfasiState();
}

class _UrunOlusturSayfasiState extends State<UrunOlusturSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _modelNoController = TextEditingController();
  final _stokKoduController = TextEditingController();
  final _adetController = TextEditingController(text: '1');

  bool isLoading = false;
  String? qrUrl; // tam (absolute) URL tutacağız

  static const _base = 'http://10.0.2.2:8000';

  String? _absoluteMediaUrl(dynamic path) {
    if (path == null) return null;
    final p = path.toString();
    if (p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    final normalized = p.startsWith('/') ? p : '/$p';
    return '$_base$normalized';
  }

  Future<void> _urunOlustur() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      qrUrl = null;
    });

    try {
      // ✅ Artık token taşımıyoruz; UrunService access'i kendisi alır,
      // 401'de RefreshCoordinator ile yeniler ve tekrar dener.
      final qrPath = await UrunService.urunEkle(
        ad: _adController.text.trim(),
        modelNo: _modelNoController.text.trim(),
        stokKodu: _stokKoduController.text.trim(),
        adet: int.tryParse(_adetController.text.trim()) ?? 1,
      );

      setState(() => isLoading = false);

      if (qrPath != null) {
        setState(() {
          qrUrl = _absoluteMediaUrl(qrPath);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Ürün başarıyla oluşturuldu.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Ürün oluşturulamadı.")),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(fontSize: 15),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (labelText == 'Adet') {
            final n = int.tryParse(value?.trim() ?? '');
            if (n == null || n <= 0) return 'Geçerli bir adet girin';
            return null;
          }
          return (value == null || value.trim().isEmpty)
              ? '$labelText gerekli'
              : null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _adController.dispose();
    _modelNoController.dispose();
    _stokKoduController.dispose();
    _adetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("Ürün Oluştur"),
        backgroundColor: Colors.indigo,
        elevation: 2,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(_adController, "Ürün Adı"),
                      _buildTextField(_modelNoController, "Model No"),
                      _buildTextField(_stokKoduController, "Stok Kodu"),
                      _buildTextField(
                        _adetController,
                        "Adet",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _urunOlustur,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.check),
                          label: const Text("Kaydet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (qrUrl != null)
                        Column(
                          children: [
                            const Text(
                              "Oluşturulan QR Kod",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                qrUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 80,
                                    ),
                              ),
                            ),
                          ],
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
