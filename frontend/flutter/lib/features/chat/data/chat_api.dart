// Envía mensajes al endpoint público de chat del backend y adapta sus respuestas.
import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  const ChatApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class HealthCenterRecommendation {
  final String? id;
  final String name;
  final double distanceKm;
  final String? address;
  final String? specialty;
  final double? latitude;
  final double? longitude;

  const HealthCenterRecommendation({
    this.id,
    required this.name,
    required this.distanceKm,
    this.address,
    this.specialty,
    this.latitude,
    this.longitude,
  });

  factory HealthCenterRecommendation.fromJson(Map<String, dynamic> json) {
    final distance = json['distancia_km'];
    final lat = json['latitud'];
    final lon = json['longitud'];
    return HealthCenterRecommendation(
      id: json['id'] as String?,
      name: json['nombre'] as String? ?? 'Centro de salud',
      distanceKm: distance is num ? distance.toDouble() : 0,
      address: json['direccion'] as String?,
      specialty: json['especialidad_coincidente'] as String?,
      latitude: lat is num ? lat.toDouble() : null,
      longitude: lon is num ? lon.toDouble() : null,
    );
  }
}

class ChatReply {
  final String sessionId;
  final String reply;
  final String riskLevel;
  final List<String> sources;
  final String? suggestedAction;
  final HealthCenterRecommendation? recommendedCenter;
  final bool locationRequired;

  const ChatReply({
    required this.sessionId,
    required this.reply,
    required this.riskLevel,
    required this.sources,
    this.suggestedAction,
    this.recommendedCenter,
    this.locationRequired = false,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    return ChatReply(
      sessionId: json['session_id'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'LOW',
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      suggestedAction: json['suggested_action'] as String?,
      locationRequired: json['ubicacion_requerida'] as bool? ?? false,
        recommendedCenter: json['centro_sugerido'] is Map<String, dynamic>
          ? HealthCenterRecommendation.fromJson(json['centro_sugerido'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatHistoryMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;

  const ChatHistoryMessage({
    required this.text,
    required this.isUser,
    this.riskLevel,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      text: json['mensaje'] as String? ?? '',
      isUser: json['emisor'] == 'USUARIO',
      riskLevel: json['nivel_riesgo'] as String?,
    );
  }
}

class ChatApi {
  ChatApi({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final http.Client _client;

  Future<ChatReply> sendMessage({
    required String message,
    String? sessionId,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (sessionId != null) payload['session_id'] = sessionId;
    if (latitude != null && longitude != null) {
      payload['latitude'] = latitude;
      payload['longitude'] = longitude;
    }

    final response = await _client
        .post(
          Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 90));

    Map<String, dynamic> body = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] ?? body['message'] ?? body['detail'];
      throw ChatApiException(
        error is String
            ? error
            : 'No se pudo obtener una respuesta de Biomark AI.',
        statusCode: response.statusCode,
      );
    }

    return ChatReply.fromJson(body);
  }

  Future<({String? sessionId, List<ChatHistoryMessage> messages})> loadHistory() async {
    final response = await _client.get(
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/chat/history'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 30));
    final decoded = response.body.isEmpty ? const {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map<String, dynamic>) {
      throw const ChatApiException('No se pudo cargar el historial del chat.');
    }
    return (
      sessionId: decoded['session_id'] as String?,
      messages: (decoded['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatHistoryMessage.fromJson)
          .toList(),
    );
  }

  void dispose() => _client.close();
}
