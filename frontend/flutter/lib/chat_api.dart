// Mantiene el cliente HTTP de compatibilidad para el chat anterior.
import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  const ChatApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ChatReply {
  final String sessionId;
  final String reply;
  final String riskLevel;
  final List<String> sources;

  const ChatReply({
    required this.sessionId,
    required this.reply,
    required this.riskLevel,
    required this.sources,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    return ChatReply(
      sessionId: json['session_id'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'LOW',
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
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

  void dispose() => _client.close();
}
