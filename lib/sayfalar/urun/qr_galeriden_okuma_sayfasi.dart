import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:siparis_takip/models/urun.dart';
import 'package:siparis_takip/services/urun_service.dart';
import 'package:siparis_takip/sayfalar/urun/urun_tanimlama_sayfasi.dart';

class QRGaleridenOkumaSayfasi extends StatefulWidget {
  const QRGaleridenOkumaSayfasi({super.key});

  @override
  State<QRGaleridenOkumaSayfasi> createState() =>
      _QRGaleridenOkumaSayfasiState();
}

class _QRGaleridenOkumaSayfasiState extends State<QRGaleridenOkumaSayfasi> {
  String? okunanQR;
  bool isLoading = false;

  Future<void> qrKodluResmiOku() async {
    final picker = ImagePicker();
    final resim = await picker.pickImage(source: ImageSource.gallery);

    if (resim == null) return;

    setState(() {
      isLoading = true;
      okunanQR = null;
    });

    try {
      final qrMetni = await QrCodeToolsPlugin.decodeFrom(resim.path);

      if (qrMetni == null) {
        _showSnackBar("QR kod okunamadı.");
        return;
      }

      final bolunmus = qrMetni.split('-').map((e) => e.trim()).toList();
      final stokKodu =
          bolunmus.length >= 2
              ? '${bolunmus[bolunmus.length - 2]}-${bolunmus[bolunmus.length - 1]}'
              : qrMetni.trim();

      setState(() {
        okunanQR = stokKodu;
      });

      final urun = await UrunService.qrIleBul(stokKodu);

      if (!mounted) return;

      if (urun != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UrunTanimlamaSayfasi(urun: urun)),
        );
      } else {
        _showSnackBar("Ürün bulunamadı.");
      }
    } catch (e) {
      _showSnackBar("QR kod okunamadı: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Kodlu Resimden Oku"),
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
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 60,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Galeriden QR Kodlu Görsel Seç",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: qrKodluResmiOku,
                  icon: const Icon(Icons.image),
                  label: const Text("QR Kodlu Resmi Seç"),
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
                ),
                const SizedBox(height: 24),
                if (isLoading) const CircularProgressIndicator(),
                if (okunanQR != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Okunan Stok Kodu: $okunanQR",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
