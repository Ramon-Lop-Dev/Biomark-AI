// Representa un mensaje de conversación y los metadatos clínicos de la respuesta.
import '../data/chat_api.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;
  final List<String> sources;
  final String? actionType;
  final String? imagePath;
  final HealthCenterRecommendation? recommendedCenter;

  const ChatMessage(
    this.text,
    this.isUser, {
    this.riskLevel,
    this.sources = const [],
    this.actionType,
    this.imagePath,
    this.recommendedCenter,
  });
}
