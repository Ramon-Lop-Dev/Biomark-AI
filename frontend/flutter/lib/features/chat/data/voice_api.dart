// Envía grabaciones al endpoint de voz del backend y adapta su respuesta clínica.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_api.dart';

class VoiceReply {
  final String sessionId;
  final String transcription;
  final String reply;
  final String riskLevel;
  final List<String> sources;
  final List<int> audioBytes;

  const VoiceReply({
    required this.sessionId,
    required this.transcription,
    required this.reply,
    required this.riskLevel,
    required this.sources,
    required this.audioBytes,
  });

  factory VoiceReply.fromJson(Map<String, dynamic> json) {
    return VoiceReply(
      sessionId: json['session_id'] as String? ?? '',
      transcription: json['transcription'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'LOW',
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
        audioBytes: json['audio_base64'] is String
          ? base64Decode(json['audio_base64'] as String)
          : const [],
    );
  }
}

class VoiceApi {
  VoiceApi({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String accessToken;
  final http.Client _client;

  Future<VoiceReply> sendRecording({
    required String path,
    String? sessionId,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/voice'),
          )
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..files.add(await http.MultipartFile.fromPath('archivo', path));

    if (sessionId != null) request.fields['session_id'] = sessionId;

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 90));
    final bodyText = await response.stream.bytesToString();
    Map<String, dynamic> body = const {};
    if (bodyText.isNotEmpty) {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) body = decoded;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] ?? body['message'] ?? body['detail'];
      throw ChatApiException(
        error is String ? error : 'No se pudo procesar el audio.',
        statusCode: response.statusCode,
      );
    }

    return VoiceReply.fromJson(body);
  }

  void dispose() => _client.close();
}
