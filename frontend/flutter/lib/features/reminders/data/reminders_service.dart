// Servicio HTTP para recordatorios.
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReminderException implements Exception {
  final String message;
  final int? statusCode;

  const ReminderException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class Reminder {
  final String id;
  final String usuarioId;
  final String tipo; // VACUNA, MEDICAMENTO, CITA, CONTROL
  final String titulo;
  final String? descripcion;
  final DateTime fechaRecordatorio;
  final String? hora;
  final String estado; // PENDIENTE, ENVIADO, COMPLETADO, CANCELADO
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  const Reminder({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    this.descripcion,
    required this.fechaRecordatorio,
    this.hora,
    required this.estado,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'MEDICAMENTO',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      fechaRecordatorio: DateTime.tryParse(
            json['fecha_programada'] as String? ?? json['fecha_recordatorio'] as String? ?? '',
          ) ??
          DateTime.now(),
      hora: json['hora'] as String? ?? RemindersService.formatHour(json['fecha_programada'] as String?),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      fechaCreacion: DateTime.tryParse(
            json['fecha_creacion'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'] as String)
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_programada': fechaRecordatorio.toIso8601String(),
      'hora': hora,
      'estado': estado,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion?.toIso8601String(),
    };
  }
}

class RemindersService {
  RemindersService({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final http.Client _client;

  /// Obtiene todos los recordatorios del usuario.
  Future<List<Reminder>> getReminders() async {
    final response = await _client
        .get(
          Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/reminders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _parseJson(response.body);
      throw ReminderException(_errorMessage(body, 'Error al obtener recordatorios'), statusCode: response.statusCode);
    }

    final body = _parseJson(response.body);
    final data = body is List<dynamic> ? body : body is Map<String, dynamic> ? body['data'] : null;
    if (data is! List<dynamic>) {
      throw ReminderException('Expected data array from backend');
    }

    return data.map((item) => Reminder.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Crea un nuevo recordatorio.
  Future<Reminder> createReminder({
    required String tipo,
    required String titulo,
    String? descripcion,
    required DateTime fechaRecordatorio,
    String? hora,
  }) async {
    final payload = {
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_programada': _combineDateAndTime(fechaRecordatorio, hora).toUtc().toIso8601String(),
    };

    final response = await _client
        .post(
          Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/reminders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _parseJson(response.body);
      throw ReminderException(_errorMessage(body, 'Error al crear recordatorio'), statusCode: response.statusCode);
    }

    final body = _parseJson(response.body);
    final data = body is Map<String, dynamic> && body['data'] is Map<String, dynamic> ? body['data'] : body;
    if (data is! Map<String, dynamic>) {
      throw ReminderException('Expected reminder object in response');
    }

    return Reminder.fromJson(data);
  }

  /// Actualiza el estado de un recordatorio.
  Future<Reminder> updateReminderStatus({
    required String reminderId,
    required String estado, // PENDIENTE, COMPLETADO, ARCHIVADO
  }) async {
    final payload = {'estado': estado};

    final response = await _client
        .patch(
          Uri.parse(
            '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/reminders/$reminderId',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _parseJson(response.body);
      throw ReminderException(_errorMessage(body, 'Error al actualizar recordatorio'), statusCode: response.statusCode);
    }

    final body = _parseJson(response.body);
    final data = body is Map<String, dynamic> && body['data'] is Map<String, dynamic> ? body['data'] : body;
    if (data is! Map<String, dynamic>) {
      throw ReminderException('Expected reminder object in response');
    }

    return Reminder.fromJson(data);
  }

  /// Parse JSON safely.
  static dynamic _parseJson(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _errorMessage(dynamic body, String fallback) {
    if (body is! Map<String, dynamic>) return fallback;
    final error = body['error'] ?? body['message'] ?? body['detail'];
    return error is String && error.isNotEmpty ? error : fallback;
  }

  static String? formatHour(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    if (date == null) return null;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static DateTime _combineDateAndTime(DateTime date, String? hour) {
    if (hour == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(hour)) return date;
    final parts = hour.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}
