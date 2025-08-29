// lib/sayfalar/bildirim/notification_box_page.dart
import 'package:flutter/material.dart';
import 'package:siparis_takip/services/api_service.dart';
import 'package:siparis_takip/services/notification_service.dart'
    show NotificationService, unreadCounter;

class NotificationBoxPage extends StatefulWidget {
  const NotificationBoxPage({super.key});

  @override
  State<NotificationBoxPage> createState() => _NotificationBoxPageState();
}

class _NotificationBoxPageState extends State<NotificationBoxPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _showUnreadOnly = false; // İstemci tarafı filtresi

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final list = await ApiService.fetchNotifications(); // GET /notifications/
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
      if (initial) {
        await NotificationService.I.refreshUnreadPublic();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bildirimler yüklenemedi: $e')));
    }
  }

  Future<void> _refresh() async {
    await _load();
    await NotificationService.I.refreshUnreadPublic();
  }

  Future<void> _markRead(int index) async {
    final id = _filteredItems[index]['id'] as int;
    // Filtre açıkken de doğru öğeyi güncellemek için orijinal listedeki indexi bul
    final realIndex = _items.indexWhere((e) => e['id'] == id);
    if (realIndex == -1) return;

    final wasUnread = _items[realIndex]['is_read'] == false;
    final ok = await ApiService.markNotificationRead(id); // PATCH /mark-read/
    if (ok && mounted) {
      setState(() => _items[realIndex]['is_read'] = true);
      if (wasUnread && unreadCounter.value > 0) {
        unreadCounter.value -= 1;
      }
    }
  }

  Future<void> _markAllRead() async {
    final unreadExists = _items.any((e) => e['is_read'] == false);
    if (!unreadExists) return;

    final ok =
        await ApiService.markAllNotificationsRead(); // POST /mark-all-read/
    if (ok && mounted) {
      setState(() {
        for (final e in _items) {
          e['is_read'] = true;
        }
      });
      unreadCounter.value = 0;
    }
  }

  List<dynamic> get _filteredItems =>
      _showUnreadOnly
          ? _items.where((e) => e['is_read'] == false).toList()
          : _items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unreadCount = _items.where((e) => e['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        // Açık temalarda görünürlük için tema tabanlı renkler
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Bildirim Kutusu'),
        actions: [
          IconButton(
            tooltip:
                _showUnreadOnly
                    ? 'Tümünü göster'
                    : 'Sadece okunmamışları göster',
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt_off : Icons.filter_alt,
            ),
            onPressed: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor:
                    cs.primary, // beyaz değil, tema rengi → görünür
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Hepsi okundu'),
            ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refresh,
                child:
                    _filteredItems.isEmpty
                        ? ListView(
                          children: const [SizedBox(height: 80), _EmptyState()],
                        )
                        : ListView.separated(
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = _filteredItems[i];
                            final isRead = (e['is_read'] as bool?) ?? false;
                            final title = (e['title'] ?? '').toString();
                            final body = (e['body'] ?? '').toString();
                            final createdAt = _parseDate(e['created_at']);

                            return ListTile(
                              leading: Icon(
                                isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                // Okunmamışta sarı vurgu, okunmuşta nötr gri
                                color:
                                    isRead ? cs.onSurfaceVariant : Colors.amber,
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight:
                                      isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (body.isNotEmpty)
                                    Text(
                                      body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: cs.onSurface.withOpacity(.85),
                                      ),
                                    ),
                                  if (createdAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        _humanize(createdAt),
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing:
                                  isRead
                                      ? null
                                      : Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.red, // 🔴 okunmamış rozet
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                              onTap: () => _markRead(i),
                            );
                          },
                        ),
              ),
    );
  }

  // ISO 8601 -> local DateTime
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.tryParse(value.toString())?.toLocal();
    } catch (_) {
      return null;
    }
  }

  // "x dk önce" basit TR gösterim
  static String _humanize(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';

    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '$weeks hf önce';

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.notifications_none, size: 64, color: cs.secondaryContainer),
        const SizedBox(height: 12),
        Text(
          'Bildirim yok',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Yeni bildirimler geldiğinde burada görünecek.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
