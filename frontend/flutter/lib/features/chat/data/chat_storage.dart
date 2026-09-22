// Almacenamiento local persistente del historial de chat usando SharedPreferences.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chat_message.dart';

class ChatStorage {
  static const _keyMessages = 'biomark_chat_messages_cache';
  static const _keySessionId = 'biomark_chat_session_id';

  /// Guarda la lista de mensajes y opcionalmente el sessionId activo.
  static Future<void> saveMessages(
    List<ChatMessage> messages, {
    String? sessionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sessionId != null && sessionId.isNotEmpty) {
        await prefs.setString(_keySessionId, sessionId);
      }
      // Conservar un límite razonable de los últimos 100 mensajes
      final toSave = messages.length > 100
          ? messages.sublist(messages.length - 100)
          : messages;

      final serialized = toSave.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_keyMessages, serialized);
    } catch (_) {
      // Falla silenciosa para no interrumpir el flujo de usuario
    }
  }

  /// Recupera los mensajes guardados localmente y el sessionId.
  static Future<({String? sessionId, List<ChatMessage> messages})> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString(_keySessionId);
      final rawList = prefs.getStringList(_keyMessages) ?? [];

      final messages = <ChatMessage>[];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            messages.add(ChatMessage.fromJson(decoded));
          }
        } catch (_) {}
      }

      return (sessionId: sessionId, messages: messages);
    } catch (_) {
      return (sessionId: null, messages: <ChatMessage>[]);
    }
  }

  /// Borra el historial local del chat.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMessages);
      await prefs.remove(_keySessionId);
    } catch (_) {}
  }
}
