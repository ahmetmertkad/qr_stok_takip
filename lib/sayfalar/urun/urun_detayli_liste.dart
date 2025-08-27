// lib/sayfalar/urun/urun_detayli_liste.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siparis_takip/models/urun.dart';
import 'package:siparis_takip/models/detayli_urun.dart';
import 'package:siparis_takip/models/urun_durum_gecmisi.dart';
import 'package:siparis_takip/services/urun_service.dart';
import 'package:siparis_takip/sayfalar/urun/urun_tanimlama_sayfasi.dart';

class UrunDetayliListeSayfasi extends StatefulWidget {
  const UrunDetayliListeSayfasi({super.key}); // token kaldırıldı

  @override
  State<UrunDetayliListeSayfasi> createState() =>
      _UrunDetayliListeSayfasiState();
}

class _UrunDetayliListeSayfasiState extends State<UrunDetayliListeSayfasi> {
  static const durumlar = <String>[
    'stokta',
    'satildi',
    'incelemede',
    'hasarli',
    'iade',
    'rezerve',
    'silindi',
  ];

  final Set<String> _seciliDurumlar = {'stokta'};
  Future<List<DetayliUrun>>? _future;
  bool _loading = false;
  int? _limit;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  void _yukle() {
    final f = UrunService.detayliListe(
      // token parametresi yok
      durumList: _seciliDurumlar.isEmpty ? null : _seciliDurumlar.toList(),
      limit: _limit,
    );

    setState(() {
      _loading = true;
      _future = f;
    });

    f.whenComplete(() {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  Future<void> _yenile() async {
    _yukle();
    final f = _future;
    if (f != null) await f;
  }

  void _toggleDurum(String d) {
    if (_loading) return;
    setState(() {
      if (_seciliDurumlar.contains(d)) {
        _seciliDurumlar.remove(d);
      } else {
        _seciliDurumlar.add(d);
      }
    });
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final chipsDisabled = _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ürünler • Detaylı Liste",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtreler',
            onPressed: chipsDisabled ? null : () => _acFiltreSheet(context),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _yenile,
          child: FutureBuilder<List<DetayliUrun>>(
            future: _future,
            builder: (context, snap) {
              if (_future == null ||
                  _loading ||
                  snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hata: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _yenile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final liste = snap.data ?? [];
              if (liste.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Kayıt bulunamadı'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _yenile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yenile'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: liste.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final d = liste[i];
                  final u = d.urun;
                  return _UrunKart(
                    urun: u,
                    gecmis: d.durumGecmisi,
                    onDuzenle: () async {
                      final guncel = await Navigator.push<Urun?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UrunTanimlamaSayfasi(urun: u),
                        ),
                      );
                      if (guncel != null) _yukle();
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: -6,
            children:
                durumlar.map((d) {
                  final secili = _seciliDurumlar.contains(d);
                  return FilterChip(
                    selected: secili,
                    onSelected: _loading ? null : (_) => _toggleDurum(d),
                    label: Text(d),
                    selectedColor: Colors.indigo.shade200,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  void _acFiltreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final tmp = Set<String>.from(_seciliDurumlar);
        final limitCtrl = TextEditingController(text: _limit?.toString() ?? '');

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtreler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Durumlar'),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder:
                        (context, setSt) => Wrap(
                          spacing: 8,
                          children:
                              durumlar.map((d) {
                                final sec = tmp.contains(d);
                                return FilterChip(
                                  selected: sec,
                                  onSelected:
                                      (_) => setSt(() {
                                        sec ? tmp.remove(d) : tmp.add(d);
                                      }),
                                  label: Text(d),
                                );
                              }).toList(),
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Limit (opsiyonel)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Örn: 50',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _seciliDurumlar.clear();
                            _limit = null;
                          });
                          Navigator.pop(context);
                          _yukle();
                        },
                        child: const Text('Temizle'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _seciliDurumlar
                              ..clear()
                              ..addAll(tmp);
                            final t = limitCtrl.text.trim();
                            _limit = t.isEmpty ? null : int.tryParse(t);
                          });
                          Navigator.pop(context);
                          _yukle();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Uygula'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UrunKart extends StatelessWidget {
  final Urun urun;
  final List<UrunDurumGecmisi> gecmis;
  final VoidCallback onDuzenle;

  const _UrunKart({
    required this.urun,
    required this.gecmis,
    required this.onDuzenle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            '${urun.ad} • ${urun.modelNo}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Stok Kodu: ${urun.stokKodu}\nDurum: ${urun.durum}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Durum değiştir',
            onPressed: onDuzenle,
          ),
          children: [
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Durum Geçmişi',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 8),
            if (gecmis.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Geçmiş bulunmuyor'),
              )
            else
              ...gecmis.map(
                (g) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text('${g.oncekiDurum ?? '—'} → ${g.yeniDurum}'),
                  subtitle: Text(
                    '${_fmt(g.tarih)}  ${g.aciklama.isEmpty ? '' : '• ${g.aciklama}'}',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Stok kodunu kopyala',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: urun.stokKodu));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stok kodu kopyalandı')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  static String _two(int n) => n.toString().padLeft(2, '0');
}
