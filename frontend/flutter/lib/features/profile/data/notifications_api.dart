import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> extraData;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.extraData = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return AppNotification(
      id: '${json['id'] ?? ''}',
      type: '${json['tipo'] ?? 'SISTEMA'}',
      title: '${json['titulo'] ?? (json['tipo'] == 'ALERTA_EPIDEMIOLOGICA' ? 'Alerta Epidemiológica' : json['tipo'] == 'RECORDATORIO' ? 'Recordatorio de Salud' : 'Aviso del Sistema')}',
      message: '${json['mensaje'] ?? ''}',
      isRead: json['leida'] == true || json['fecha_lectura'] != null,
      createdAt: parseDate(json['fecha_creacion']),
      extraData: json['datos_adicionales'] is Map<String, dynamic>
          ? json['datos_adicionales'] as Map<String, dynamic>
          : const {},
    );
  }
}

class NotificationsResult {
  final List<AppNotification> items;
  final int total;
  final int unreadCount;

  const NotificationsResult({
    required this.items,
    required this.total,
    required this.unreadCount,
  });
}

class NotificationsApi {
  final http.Client _client;

  NotificationsApi({http.Client? client}) : _client = client ?? http.Client();

  static final _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      };

  Future<NotificationsResult> fetchNotifications({
    int limit = 30,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final uri = Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/notifications').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (unreadOnly) 'solo_no_leidas': 'true',
      },
    );

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cargar notificaciones (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = data['notificaciones'] as List? ?? [];
    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();

    return NotificationsResult(
      items: items,
      total: data['total'] is num ? (data['total'] as num).toInt() : items.length,
      unreadCount: data['no_leidas'] is num ? (data['no_leidas'] as num).toInt() : 0,
    );
  }

  Future<void> markAsRead(String id) async {
    final uri = Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/notifications/$id/read');
    final response = await _client.patch(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo marcar la notificación como leída');
    }
  }

  Future<void> markAllAsRead() async {
    final uri = Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/notifications/read-all');
    final response = await _client.patch(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudieron marcar todas las notificaciones');
    }
  }

  void dispose() {
    _client.close();
  }
}
