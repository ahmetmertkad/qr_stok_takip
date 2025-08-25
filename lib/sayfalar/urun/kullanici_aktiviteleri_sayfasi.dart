// lib/screens/kullanici_aktiviteleri_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siparis_takip/models/aktivite.dart';
import 'package:siparis_takip/services/urun_service.dart'; // getKullaniciAdlari + kullaniciAktiviteleriByUsername

class KullaniciAktiviteleriSayfasi extends StatefulWidget {
  const KullaniciAktiviteleriSayfasi({super.key});

  @override
  State<KullaniciAktiviteleriSayfasi> createState() =>
      _KullaniciAktiviteleriSayfasiState();
}

class _KullaniciAktiviteleriSayfasiState
    extends State<KullaniciAktiviteleriSayfasi> {
  final _fmt = DateFormat('dd.MM.yyyy HH:mm');

  late Future<List<String>> _namesFuture;
  String? _selectedUsername;

  List<Aktivite>? _logs;
  bool _loadingLogs = false;

  @override
  void initState() {
    super.initState();
    _namesFuture = UrunService.getKullaniciAdlari();
  }

  Future<void> _fetchLogs() async {
    if (_selectedUsername == null) return;
    setState(() => _loadingLogs = true);
    try {
      final data = await UrunService.kullaniciAktiviteleriByUsername(
        _selectedUsername!,
      );
      setState(() => _logs = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Aktiviteler alınamadı: $e')));
    } finally {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Color _statusColor(String code) {
    switch (code) {
      case 'stokta':
        return Colors.blue.shade600;
      case 'satildi':
        return Colors.green.shade600;
      case 'incelemede':
        return Colors.orange.shade700;
      case 'hasarli':
        return Colors.red.shade600;
      case 'iade':
        return Colors.purple.shade600;
      case 'rezerve':
        return Colors.teal.shade600;
      case 'silindi':
        return Colors.grey.shade700;
      default:
        return Colors.indigo.shade600;
    }
  }

  Widget _chip(String label, String code) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: _statusColor(code),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = "Kullanıcı Aktiviteleri";

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
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
        child: FutureBuilder<List<String>>(
          future: _namesFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorCard(
                message: "Kullanıcı listesi alınamadı",
                detail: snap.error.toString(),
                onRetry:
                    () => setState(
                      () => _namesFuture = UrunService.getKullaniciAdlari(),
                    ),
              );
            }
            final usernames = snap.data ?? [];
            if (usernames.isEmpty) {
              return _EmptyCard(
                text: "Hiç kullanıcı bulunamadı.",
                onRefresh:
                    () => setState(
                      () => _namesFuture = UrunService.getKullaniciAdlari(),
                    ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kullanıcı seç",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedUsername,
                                items:
                                    usernames
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    _loadingLogs
                                        ? null
                                        : (val) => setState(
                                          () => _selectedUsername = val,
                                        ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  hintText: "Seçiniz",
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  (_selectedUsername == null || _loadingLogs)
                                      ? null
                                      : _fetchLogs,
                              icon:
                                  _loadingLogs
                                      ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.search),
                              label: const Text("Getir"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        Expanded(
                          child:
                              _logs == null
                                  ? const Center(
                                    child: Text(
                                      "Bir kullanıcı seçip 'Getir' butonuna basın.",
                                    ),
                                  )
                                  : _logs!.isEmpty
                                  ? const Center(
                                    child: Text(
                                      "Bu kullanıcıya ait aktivite bulunamadı.",
                                    ),
                                  )
                                  : RefreshIndicator(
                                    onRefresh: () async => _fetchLogs(),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _logs!.length,
                                      separatorBuilder:
                                          (_, __) => const Divider(height: 16),
                                      itemBuilder: (context, i) {
                                        final a = _logs![i];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.history,
                                            color: Colors.indigo,
                                          ),
                                          title: Row(
                                            children: [
                                              Flexible(
                                                child: _chip(
                                                  a.oncekiDurumLabel ?? '-',
                                                  a.oncekiDurum ?? '',
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Flexible(
                                                child: _chip(
                                                  a.yeniDurumLabel,
                                                  a.yeniDurum,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Ürün ID: ${a.urun}  •  ${_fmt.format(a.tarih)}",
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Yapan: ${a.yapanUsername ?? '-'}",
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Açıklama: ${(a.aciklama?.trim().isEmpty ?? true) ? '—' : a.aciklama!.trim()}",
                                                ),
                                              ],
                                            ),
                                          ),
                                          isThreeLine: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  final VoidCallback onRefresh;
  const _EmptyCard({required this.text, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(text, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yenile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorCard({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(detail, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
