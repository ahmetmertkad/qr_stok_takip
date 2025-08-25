import 'package:flutter/material.dart';
import 'package:siparis_takip/models/kullanici.dart';
import 'package:siparis_takip/services/api_service.dart';

class RolDegistirmeSayfasi extends StatefulWidget {
  const RolDegistirmeSayfasi({super.key});

  @override
  State<RolDegistirmeSayfasi> createState() => _RolDegistirmeSayfasiState();
}

class _RolDegistirmeSayfasiState extends State<RolDegistirmeSayfasi> {
  List<Kullanici> kullanicilar = [];
  bool yukleniyor = true;

  final List<String> roller = ['personel', 'yonetici', 'depo_gorevlisi'];

  @override
  void initState() {
    super.initState();
    _kullanicilariGetir();
  }

  Future<void> _kullanicilariGetir() async {
    try {
      final gelenler = await ApiService.getKullaniciListesi(); // tokensiz
      if (!mounted) return;
      setState(() {
        kullanicilar =
            gelenler.map((json) => Kullanici.fromJson(json)).toList();
        yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      yukleniyor = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kullanıcılar alınamadı: $e")));
      setState(() {});
    }
  }

  Future<void> _rolDegistir(Kullanici k, String yeniRol) async {
    // Optimistic UI: önce ekranda güncelle
    final idx = kullanicilar.indexOf(k);
    final eski = k.role;

    setState(() {
      kullanicilar[idx] = Kullanici(
        id: k.id,
        username: k.username,
        isActive: k.isActive,
        role: yeniRol,
      );
    });

    final sonuc = await ApiService.updateKullaniciRol(
      // tokensiz
      userId: k.id,
      rol: yeniRol,
    );

    final ok = (sonuc['success'] ?? false) as bool;
    if (!ok) {
      // geri al
      if (!mounted) return;
      setState(() {
        kullanicilar[idx] = Kullanici(
          id: k.id,
          username: k.username,
          isActive: k.isActive,
          role: eski,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sonuc['message'] ?? "Rol değiştirilemedi")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sonuc['message'] ?? "Rol güncellendi")),
      );
      // Sunucuyla tam senkron için tekrar çekmek istersen:
      // await _kullanicilariGetir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rol Değiştirme"),
        backgroundColor: Colors.indigo.shade600,
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
                    final String? secilenRol =
                        roller.contains(k.role) ? k.role : null;

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Text(
                                  k.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Mevcut rol: ${k.role ?? 'Tanımsız'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Rol Seç",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.indigo.shade50,
                              ),
                              value: secilenRol,
                              items:
                                  roller
                                      .map(
                                        (rol) => DropdownMenuItem(
                                          value: rol,
                                          child: Text(rol),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (yeniRol) {
                                if (yeniRol != null && yeniRol != k.role) {
                                  _rolDegistir(k, yeniRol);
                                }
                              },
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
