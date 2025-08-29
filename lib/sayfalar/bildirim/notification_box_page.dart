import 'package:flutter/material.dart';
import 'package:siparis_takip/services/api_service.dart';
import 'package:siparis_takip/services/notification_service.dart'
    show unreadCounter, NotificationService;

class NotificationBoxPage extends StatefulWidget {
  const NotificationBoxPage({super.key});

  @override
  State<NotificationBoxPage> createState() => _NotificationBoxPageState();
}

class _NotificationBoxPageState extends State<NotificationBoxPage> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await ApiService.fetchNotifications(); // /notifications/
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
    await NotificationService.I.refreshUnreadPublic();
  }

  Future<void> _markRead(int index) async {
    final id = _items[index]['id'] as int;
    final wasUnread = _items[index]['is_read'] == false;
    final ok = await ApiService.markNotificationRead(id); // PATCH /mark-read/
    if (ok && mounted) {
      setState(() => _items[index]['is_read'] = true);
      if (wasUnread && unreadCounter.value > 0) {
        unreadCounter.value -= 1;
      }
    }
  }

  Future<void> _markAllRead() async {
    final ok =
        await ApiService.markAllNotificationsRead(); // POST /mark-all-read/
    if (ok && mounted) {
      for (final e in _items) {
        e['is_read'] = true;
      }
      unreadCounter.value = 0;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Kutusu'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Hepsi okundu'),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = _items[i];
                    final isRead = (e['is_read'] as bool?) ?? false;
                    return ListTile(
                      leading: Icon(
                        isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(e['title'] ?? ''),
                      subtitle: Text(e['body'] ?? ''),
                      trailing:
                          isRead
                              ? null
                              : const Icon(Icons.brightness_1, size: 10),
                      onTap: () => _markRead(i),
                    );
                  },
                ),
              ),
    );
  }
}
