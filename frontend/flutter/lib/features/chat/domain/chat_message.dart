// Representa un mensaje de conversación y los metadatos clínicos de la respuesta.
class ChatMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;
  final List<String> sources;
  final String? actionType;
  final String? imagePath;

  const ChatMessage(
    this.text,
    this.isUser, {
    this.riskLevel,
    this.sources = const [],
    this.actionType,
    this.imagePath,
  });
}
