// Representa un mensaje de conversación y los metadatos clínicos de la respuesta.
import '../data/chat_api.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;
  final List<String> sources;
  final String? actionType;
  final String? imagePath;
  final String? audioPath;
  final HealthCenterRecommendation? recommendedCenter;

  const ChatMessage(
    this.text,
    this.isUser, {
    this.riskLevel,
    this.sources = const [],
    this.actionType,
    this.imagePath,
    this.audioPath,
    this.recommendedCenter,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'is_user': isUser,
        if (riskLevel != null) 'risk_level': riskLevel,
        if (sources.isNotEmpty) 'sources': sources,
        if (actionType != null) 'action_type': actionType,
        if (imagePath != null) 'image_path': imagePath,
        if (audioPath != null) 'audio_path': audioPath,
        if (recommendedCenter != null) 'recommended_center': recommendedCenter!.toJson(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      json['text'] as String? ?? '',
      json['is_user'] as bool? ?? false,
      riskLevel: json['risk_level'] as String?,
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      actionType: json['action_type'] as String?,
      imagePath: json['image_path'] as String?,
      audioPath: json['audio_path'] as String?,
      recommendedCenter: json['recommended_center'] is Map<String, dynamic>
          ? HealthCenterRecommendation.fromJson(
              json['recommended_center'] as Map<String, dynamic>)
          : null,
    );
  }
}
