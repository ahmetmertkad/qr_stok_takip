// lib/sayfalar/oturum/hesap_durum.dart
import 'package:flutter/material.dart';
import 'package:siparis_takip/models/kullanici.dart';
import 'package:siparis_takip/services/api_service.dart';

class HesapDurum extends StatefulWidget {
  const HesapDurum({super.key}); // accessToken kaldırıldı

  @override
  State<HesapDurum> createState() => _HesapDurumState();
}

class _HesapDurumState extends State<HesapDurum> {
  List<Kullanici> kullanicilar = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kullanicilariGetir();
  }

  Future<void> _kullanicilariGetir() async {
    try {
      final gelenler = await ApiService.getKullaniciListesi(); // parametre yok
      if (!mounted) return;
      setState(() {
        kullanicilar = gelenler.map((j) => Kullanici.fromJson(j)).toList();
        yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => yukleniyor = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kullanıcılar alınamadı: $e')));
    }
  }

  Future<void> _durumuDegistir(Kullanici k, bool yeniDurum) async {
    final index = kullanicilar.indexOf(k);

    setState(() {
      kullanicilar[index] = Kullanici(
        id: k.id,
        username: k.username,
        isActive: yeniDurum,
        role: k.role,
      );
    });

    final sonuc = await ApiService.updateKullaniciDurum(
      userId: k.id,
      isActive: yeniDurum,
    ); // accessToken parametresi yok

    final basarili = (sonuc['success'] ?? false) as bool;
    if (!basarili) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sonuc['message'] ?? "Durum güncellenemedi")),
      );
      _kullanicilariGetir(); // geri al/senkronize et
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hesap Durumları",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: kullanicilar.length,
                  itemBuilder: (context, index) {
                    final k = kullanicilar[index];
                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  k.isActive ? Colors.green : Colors.red,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    k.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${k.role ?? 'Rol yok'} | ${k.isActive ? 'Aktif' : 'Pasif'}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: k.isActive,
                              activeColor: Colors.indigo,
                              onChanged: (val) => _durumuDegistir(k, val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
