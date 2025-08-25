// lib/sayfalar/ana_sayfa.dart
import 'package:flutter/material.dart';
import 'package:siparis_takip/sayfalar/oturum/giris.dart';
import 'package:siparis_takip/sayfalar/oturum/rol_degistirme.dart';
import 'package:siparis_takip/sayfalar/oturum/hesap_durum.dart';
import 'package:siparis_takip/sayfalar/urun/kullanici_aktiviteleri_sayfasi.dart';
import 'package:siparis_takip/sayfalar/urun/urun_olustur.dart';
import 'package:siparis_takip/sayfalar/urun/urun_arama_sayfasi.dart';
import 'package:siparis_takip/sayfalar/urun/qr_galeriden_okuma_sayfasi.dart';
import 'package:siparis_takip/sayfalar/urun/urun_detayli_liste.dart';
import 'package:siparis_takip/services/token_manager.dart';

class AnaSayfa extends StatelessWidget {
  final String kullaniciAdi;
  final String role; // "yonetici" | "personel" | "depo_gorevlisi"

  const AnaSayfa({super.key, required this.kullaniciAdi, required this.role});

  String get formattedUsername {
    if (kullaniciAdi.isEmpty) return "Kullanıcı";
    return kullaniciAdi[0].toUpperCase() + kullaniciAdi.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hoş Geldin, $formattedUsername"),
        backgroundColor: Colors.indigo.shade600,
        actions: [
          if (role == "yonetici") ...[
            IconButton(
              tooltip: "Kullanıcılar",
              icon: const Icon(Icons.people, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HesapDurum()),
                );
              },
            ),
          ],
          IconButton(
            tooltip: "Çıkış Yap",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await TokenManager.clear();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                );
              }
            },
          ),
        ],
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
                      _profilKarti(),
                      const SizedBox(height: 16),

                      // ---------- YÖNETİCİ ----------
                      if (role == "yonetici") ...[
                        _buildAnaButon(
                          context,
                          Icons.people,
                          "Kullanıcı Durumları",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HesapDurum(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.history,
                          "Kullanıcı Aktiviteleri",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => const KullaniciAktiviteleriSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.verified_user,
                          "Rol Değiştir",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RolDegistirmeSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.qr_code_2,
                          "Ürün Oluştur",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunOlusturSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.search,
                          "Ürünleri Filtrele",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunAramaSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.qr_code_scanner,
                          "QR Kod Oku",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QRGaleridenOkumaSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.view_list,
                          "Detaylı Liste",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunDetayliListeSayfasi(),
                            ),
                          ),
                        ),
                      ],

                      // ---------- PERSONEL ----------
                      if (role == "personel") ...[
                        _buildAnaButon(
                          context,
                          Icons.qr_code_2,
                          "Ürün Oluştur",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunOlusturSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.search,
                          "Ürünleri Filtrele",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunAramaSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.view_list,
                          "Detaylı Liste",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunDetayliListeSayfasi(),
                            ),
                          ),
                        ),
                      ],

                      // ---------- DEPO GÖREVLİSİ ----------
                      if (role == "depo_gorevlisi") ...[
                        _buildAnaButon(
                          context,
                          Icons.search,
                          "Ürünleri Filtrele",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunAramaSayfasi(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAnaButon(
                          context,
                          Icons.view_list,
                          "Detaylı Liste",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UrunDetayliListeSayfasi(),
                            ),
                          ),
                        ),
                      ],
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

  // -------------------- WIDGETLAR --------------------
  Widget _profilKarti() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.indigo, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedUsername,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor.withOpacity(.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _roleColor.withOpacity(.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, size: 16, color: _roleColor),
                      const SizedBox(width: 6),
                      Text(
                        _roleLabel,
                        style: TextStyle(
                          color: _roleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _roleColor {
    switch (role) {
      case "yonetici":
        return Colors.indigo;
      case "depo_gorevlisi":
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  String get _roleLabel {
    switch (role) {
      case "yonetici":
        return "Yönetici";
      case "depo_gorevlisi":
        return "Depo Görevlisi";
      default:
        return "Personel";
    }
  }

  Widget _buildAnaButon(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
