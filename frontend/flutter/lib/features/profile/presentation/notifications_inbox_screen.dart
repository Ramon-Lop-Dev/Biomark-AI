import 'package:flutter/material.dart';
import '../../../biomark_brand.dart';
import '../../../core/design/biomark_glass_surface.dart';
import '../data/notifications_api.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final _api = NotificationsApi();
  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  int _tabIndex = 0; // 0: Todas, 1: Alertas, 2: Recordatorios, 3: Sistema

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = result.items;
        _unreadCount = result.unreadCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las notificaciones. Comprueba tu conexión.';
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification item) async {
    if (item.isRead) return;
    try {
      await _api.markAsRead(item.id);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: item.id,
            type: item.type,
            title: item.title,
            message: item.message,
            isRead: true,
            createdAt: item.createdAt,
            extraData: item.extraData,
          );
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) {
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
            extraData: n.extraData,
          );
        }).toList();
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las notificaciones marcadas como leídas.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron actualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<AppNotification> get _filteredNotifications {
    if (_tabIndex == 1) {
      return _notifications.where((n) => n.type == 'ALERTA_EPIDEMIOLOGICA').toList();
    } else if (_tabIndex == 2) {
      return _notifications.where((n) => n.type == 'RECORDATORIO').toList();
    } else if (_tabIndex == 3) {
      return _notifications.where((n) => n.type == 'SISTEMA').toList();
    }
    return _notifications;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'ALERTA_EPIDEMIOLOGICA':
        return const Color(0xFFE53935);
      case 'RECORDATORIO':
        return const Color(0xFF00897B);
      case 'SISTEMA':
      default:
        return BiomarkColors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ALERTA_EPIDEMIOLOGICA':
        return Icons.warning_amber_rounded;
      case 'RECORDATORIO':
        return Icons.alarm_on_rounded;
      case 'SISTEMA':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Bandeja de Avisos',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Leídas', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros tipo chip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Todas (${_notifications.length})', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('Alertas MINSA', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('Recordatorios', 2),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sistema', 3),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(_error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _loadData,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : filtered.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 100),
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: isDark ? Colors.white24 : Colors.black26,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tienes avisos en esta sección',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black45,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final color = _typeColor(item.type);
                                  final icon = _typeIcon(item.type);

                                  return InkWell(
                                    onTap: () => _markAsRead(item),
                                    borderRadius: BorderRadius.circular(16),
                                    child: BiomarkGlassSurface(
                                      padding: const EdgeInsets.all(14),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: color.withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Icon(icon, color: color, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.title,
                                                        style: TextStyle(
                                                          fontWeight: item.isRead
                                                              ? FontWeight.w600
                                                              : FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!item.isRead) ...[
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: BiomarkColors.blue,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Text(
                                                      _formatDate(item.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white54 : Colors.black45,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  item.message,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    height: 1.35,
                                                    color: isDark
                                                        ? (item.isRead ? Colors.white70 : Colors.white)
                                                        : (item.isRead ? Colors.black87 : Colors.black),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _tabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? BiomarkColors.blue
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? BiomarkColors.blue : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
