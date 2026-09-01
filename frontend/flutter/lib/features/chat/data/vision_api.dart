// Envía imágenes al backend para que las procese y reenvíe al AI Service.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_api.dart';

class VisionReply {
  final String tipoAnalisis;
  final String condicionDetectada;
  final double confidencePercentage;
  final String reply;
  final String riskLevel;
  final List<String> sources;

  const VisionReply({
    required this.tipoAnalisis,
    required this.condicionDetectada,
    required this.confidencePercentage,
    required this.reply,
    required this.riskLevel,
    required this.sources,
  });

  factory VisionReply.fromJson(Map<String, dynamic> json) {
    return VisionReply(
      tipoAnalisis: json['tipo_analisis'] as String? ?? 'piel',
      condicionDetectada: json['condicion_detectada'] as String? ?? 'Sin resultado',
      confidencePercentage: (json['confidence_percentage'] as num?)?.toDouble() ?? 0,
      reply: json['reply'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'LOW',
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class VisionApi {
  VisionApi({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final http.Client _client;

  Future<VisionReply> sendImage({
    required String path,
    required String tipo,
    String? sessionId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/vision?tipo=$tipo'),
    )
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(await http.MultipartFile.fromPath('archivo', path));

    if (sessionId != null) request.fields['session_id'] = sessionId;

    final response = await _client.send(request).timeout(const Duration(seconds: 90));
    final bodyText = await response.stream.bytesToString();
    Map<String, dynamic> body = const {};
    if (bodyText.isNotEmpty) {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) body = decoded;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] ?? body['message'] ?? body['detail'];
      throw ChatApiException(
        error is String ? error : 'No se pudo procesar la imagen.',
        statusCode: response.statusCode,
      );
    }

    return VisionReply.fromJson(body);
  }

  void dispose() => _client.close();
}
