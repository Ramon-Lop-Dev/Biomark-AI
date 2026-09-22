// Motor de inferencia y triaje clínico offline — Biomark AI
// Permite responder consultas de salud preventiva cuando no hay conexión a internet.
import 'chat_api.dart';
import 'minsa_offline_knowledge.dart';

class OfflineChatEngine {
  OfflineChatEngine._();

  static const List<String> _redFlags = [
    'dolor de pecho opresivo',
    'opresion en el pecho',
    'dolor en el pecho',
    'infarto',
    'convulsion',
    'convulsiones',
    'no puede respirar',
    'se esta ahogando',
    'asfixia',
    'labios morados',
    'labios azules',
    'vomito con sangre',
    'sangre por la boca',
    'no despierta',
    'inconsciente',
    'desmayado no reacciona',
  ];

  static String _normalize(String input) {
    var text = input.toLowerCase().trim();
    const replacements = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u',
      'ñ': 'n', 'Ñ': 'n',
    };
    replacements.forEach((accent, plain) {
      text = text.replaceAll(accent, plain);
    });
    return text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }

  static ChatReply processOfflineQuery({
    required String query,
    String? sessionId,
  }) {
    final normalized = _normalize(query);
    final sid = sessionId ?? 'offline_session_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Detección de saludos sencillos
    final greetings = {'hola', 'buenas', 'buenos dias', 'buenas tardes', 'buenas noches', 'que tal', 'ayuda'};
    final tokens = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length == 1 && greetings.contains(tokens.first)) {
      return ChatReply(
        sessionId: sid,
        reply: 'Hola. Estás en el Modo Asistente Sin Conexión de Biomark AI.\n\n'
            'Aunque no tengas internet, puedo orientarte con las guías oficiales del MINSA sobre:\n'
            '• Dengue y fiebres (Normativa 004/073)\n'
            '• Atención de niños, vómito y diarrea (Normativa 153)\n'
            '• Golpe de calor y deshidratación\n'
            '• Salud del corazón y pulso\n'
            '• Gripe y tos (Normativa 028)\n'
            '• Diabetes y glucosa (Normativa 078)\n'
            '• Primeros auxilios básicos\n\n'
            '¿Qué síntoma o molestia estás sintiendo?',
        riskLevel: 'LOW',
        sources: const ['Guía Local MINSA (Sin Conexión)'],
      );
    }

    // 2. Detección de Banderas Rojas (Emergencias Críticas)
    for (final flag in _redFlags) {
      final normFlag = _normalize(flag);
      if (normalized.contains(normFlag)) {
        final emergency = MinsaOfflineKnowledge.emergenciaCriticaGenerica;
        return ChatReply(
          sessionId: sid,
          reply: emergency.formatResponse(),
          riskLevel: 'CRITICAL',
          sources: const [
            'Protocolo Nacional de Urgencias Médicas MINSA',
            'Alerta Crítica Offline',
          ],
          suggestedAction: 'SHOW_NEAREST_CENTER',
          locationRequired: true,
        );
      }
    }

    // 3. Búsqueda y clasificación en el catálogo MINSA
    MinsaOfflineEntry? bestEntry;
    int highestScore = 0;

    for (final entry in MinsaOfflineKnowledge.catalog) {
      int score = 0;
      for (final kw in entry.keywords) {
        final normKw = _normalize(kw);
        if (normKw.contains(' ')) {
          // Coincidencia de frase exacta
          if (normalized.contains(normKw)) {
            score += 5;
          }
        } else {
          // Coincidencia por palabra
          if (tokens.contains(normKw)) {
            score += 2;
          } else if (tokens.any((t) => t.contains(normKw) && normKw.length >= 4)) {
            score += 1;
          }
        }
      }

      if (score > highestScore) {
        highestScore = score;
        bestEntry = entry;
      }
    }

    final isEvolutionQuery = normalized.contains('mejor') ||
        normalized.contains('empeor') ||
        normalized.contains('igual') ||
        normalized.contains('progreso') ||
        normalized.contains('evolucion') ||
        normalized.contains('sigo con') ||
        normalized.contains('todavia') ||
        normalized.contains('como voy');

    // 4. Si encontramos una coincidencia relevante
    if (bestEntry != null && highestScore >= 2) {
      final isHigh = bestEntry.category == 'Cardiovascular' || bestEntry.category == 'Arbovirosis';
      return ChatReply(
        sessionId: sid,
        reply: bestEntry.formatResponse(),
        riskLevel: isHigh ? 'MODERATE' : 'LOW',
        sources: [
          'Guía Local MINSA (Sin Conexión)',
          bestEntry.normative,
        ],
        suggestedAction: isHigh
            ? 'SHOW_NEAREST_CENTER'
            : (isEvolutionQuery ? 'REGISTER_PROGRESS' : null),
      );
    }

    // 5. Si es una consulta de evolución de síntomas
    if (isEvolutionQuery) {
      return ChatReply(
        sessionId: sid,
        reply: '📈 **Seguimiento de Evolución de Síntomas (Modo Sin Conexión)**\n\n'
            'He registrado tu actualización de estado. Para mantener tu historial clínico al día '
            'y ayudar a tu centro de salud a evaluar tu progreso, puedes pulsar la opción que mejor '
            'describa cómo te sientes en los botones de abajo.\n\n'
            '• **Si mejoraste:** Mantén las pautas de reposo e hidratación.\n'
            '• **Si sigues igual o empeoraste:** Permanece atento a signos de alarma y acude a tu unidad de salud MINSA si los síntomas no ceden.',
        riskLevel: 'LOW',
        sources: const [
          'Protocolo de Seguimiento Clínico MINSA',
          'Modo Local Autónomo',
        ],
        suggestedAction: 'REGISTER_PROGRESS',
      );
    }

    // 6. Respuesta de orientación general cuando no hay coincidencia exacta
    return ChatReply(
      sessionId: sid,
      reply: '📋 **Orientación Preventiva General (Modo Sin Conexión)**\n\n'
          'Actualmente no tienes conexión a internet, pero he registrado tu consulta. '
          'No identifiqué un protocolo exacto para tus palabras, pero ten en cuenta las siguientes recomendaciones generales del MINSA:\n\n'
          '💧 **Pautas de autocuidado general:**\n'
          '• Mantén reposo y bebe abundantes líquidos limpios (agua hervida o suero oral).\n'
          '• No te automediques con antibióticos ni analgésicos fuertes sin prescripción médica.\n'
          '• Si tienes dolor de cabeza o fiebre, guarda reposo en un lugar fresco y ventilado.\n\n'
          '🚩 **Signos de alarma universales:**\n'
          '• Dificultad para respirar, dolor de pecho opresivo, vómitos incontrolables o somnolencia extrema.\n\n'
          '🏥 **Siguiente paso:** Acude al puesto de salud MINSA de tu comunidad para una valoración presencial. '
          'En cuanto recuperes la conexión a internet, podrás consultar al asistente inteligente completo.',
      riskLevel: 'LOW',
      sources: const [
        'Guía Local MINSA (Sin Conexión)',
        'Directriz General de Salud Comunitaria',
      ],
    );
  }
}
