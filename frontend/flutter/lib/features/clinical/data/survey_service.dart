import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_biomark/core/auth/auth_session.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import 'package:flutter_biomark/health_survey.dart';
import 'package:flutter_biomark/features/chat/presentation/chat_screen.dart';
/// Misma transición fade+slide usada en el resto de la app
/// (duplicada aquí para evitar imports circulares, mismo patrón
/// que ya usan home_screen.dart y app_shell.dart).
class _FadeSlidePageRoute<T> extends MaterialPageRoute<T> {
  _FadeSlidePageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }
}

class SurveyService {
  SurveyService._();

  static const String prefKeyEntrevistaCompletada = 'biomark_entrevista_completada';

  /// true una vez que el usuario completó la encuesta de salud.
  static bool completado = false;

  /// Respuestas de la encuesta — luego las envías a tu backend/IA.
  static Map<String, dynamic> respuestas = {};

  static Future<void> cargarDesdeBackend() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final headers = {'Authorization': 'Bearer $token'};
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$base/api/users/profile'), headers: headers),
        http.get(Uri.parse('$base/api/medical-history'), headers: headers),
        http.get(Uri.parse('$base/api/medical-history/family-history'), headers: headers),
        http.get(Uri.parse('$base/api/medical-history/allergies'), headers: headers),
        http.get(Uri.parse('$base/api/medical-history/medications'), headers: headers),
        http.get(Uri.parse('$base/api/users/consent'), headers: headers),
      ]);
      final profile = responses[0].statusCode >= 200 && responses[0].statusCode < 300
          ? jsonDecode(responses[0].body) as Map<String, dynamic>
          : <String, dynamic>{};
      final nested = profile['perfiles'] as Map<String, dynamic>? ?? const {};
      final birth = DateTime.tryParse('${nested['fecha_nacimiento'] ?? ''}');
      final age = birth == null ? null : _calculateAge(birth);
      final history = _listFromResponse(responses[1]);
      final family = _listFromResponse(responses[2]);
      final allergies = _listFromResponse(responses[3]);
      final medications = _listFromResponse(responses[4]);
      final consentList = responses[5].statusCode >= 200 && responses[5].statusCode < 300
          ? jsonDecode(responses[5].body) as List<dynamic>
          : const [];
      final consent = consentList.whereType<Map<String, dynamic>>().cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['tipo_consentimiento'] == 'CONTEXTO_MEDICO_IA',
            orElse: () => null,
          );
      respuestas = {
        'edad': age,
        'sexo': nested['sexo'],
        'enfermedadesCronicas': history.map((item) => '${item['nombre_condicion'] ?? ''}').where((value) => value.isNotEmpty).toList(),
        'antecedentesHereditarios': family.map((item) => '${item['nombre_condicion'] ?? ''}').where((value) => value.isNotEmpty).toList(),
        'alergias': allergies.map((item) => '${item['alergeno'] ?? ''}').where((value) => value.isNotEmpty).toList(),
        'medicamentosActuales': medications.map((item) => '${item['nombre_medicamento'] ?? ''}').where((value) => value.isNotEmpty).join(', '),
        'consentimientoMedico': consent?['otorgado'] != false,
      };
      final prefs = await SharedPreferences.getInstance();
      final localCompletado = prefs.getBool(prefKeyEntrevistaCompletada) == true;
      final serverCompletado = nested['entrevista_completada'] == true;
      completado = localCompletado || serverCompletado || (age != null && nested['sexo'] != null);
      if (completado && !localCompletado) {
        await prefs.setBool(prefKeyEntrevistaCompletada, true);
      }
    } catch (_) {
      // La app conserva el estado local si el backend no está disponible.
    }
  }

  static List<Map<String, dynamic>> _listFromResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) return const [];
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded.whereType<Map<String, dynamic>>().toList() : const [];
  }

  static int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  static Future<void> guardarRespuestas({
    required int edad,
    required String sexo,
    required List<String> enfermedadesCronicas,
    required List<String> antecedentesHereditarios,
    required List<String> alergias,
    required String medicamentosActuales,
    bool consentimientoMedico = true,
  }) async {
    // Delega en reemplazarEncuesta (PUT /api/medical-history/survey) para garantizar
    // actualización atómica e idempotente y evitar duplicidad de registros en la base de datos.
    await reemplazarEncuesta(
      edad: edad,
      sexo: sexo,
      enfermedadesCronicas: enfermedadesCronicas,
      antecedentesHereditarios: antecedentesHereditarios,
      alergias: alergias,
      medicamentosActuales: medicamentosActuales,
      consentimientoMedico: consentimientoMedico,
    );
  }

  static Future<void> reemplazarEncuesta({
    required int edad,
    required String sexo,
    required List<String> enfermedadesCronicas,
    required List<String> antecedentesHereditarios,
    required List<String> alergias,
    required String medicamentosActuales,
    required bool consentimientoMedico,
  }) async {
    respuestas = {
      'edad': edad,
      'sexo': sexo,
      'enfermedadesCronicas': enfermedadesCronicas,
      'antecedentesHereditarios': antecedentesHereditarios,
      'alergias': alergias,
      'medicamentosActuales': medicamentosActuales,
      'consentimientoMedico': consentimientoMedico,
    };
    completado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyEntrevistaCompletada, true);
    } catch (_) {}
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final birthDate = DateTime(DateTime.now().year - edad, DateTime.now().month, DateTime.now().day).toIso8601String().split('T').first;
    await http.put(
      Uri.parse('$base/api/users/profile'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'fecha_nacimiento': birthDate, 'sexo': sexo, 'entrevista_completada': true}),
    );
    await http.put(
      Uri.parse('$base/api/users/consent'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'tipo_consentimiento': 'CONTEXTO_MEDICO_IA', 'otorgado': consentimientoMedico}),
    );
    await http.put(
      Uri.parse('$base/api/medical-history/survey'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'enfermedades_cronicas': enfermedadesCronicas,
        'antecedentes_hereditarios': antecedentesHereditarios,
        'alergias': alergias,
        'medicamentos': medicamentosActuales,
      }),
    );
  }

  /// Agrega un nuevo valor a una categoría de lista existente
  /// (ej. 'enfermedadesCronicas', 'antecedentesHereditarios', 'alergias').
  /// Se usa desde la pantalla de Antecedentes para agregar algo nuevo
  /// sin tener que repetir toda la encuesta.
  static void agregarItem(String categoria, String valor) {
    final normalizado = valor.trim();
    if (normalizado.isEmpty) return;

    final actual = List<String>.from(respuestas[categoria] ?? const []);
    actual.removeWhere((e) => e.toLowerCase().startsWith('ninguna'));
    if (!actual.contains(normalizado)) actual.add(normalizado);
    respuestas[categoria] = actual;

    cargarDesdeBackend();
  }

  static void eliminarItem(String categoria, String valor) {
    final actual = List<String>.from(respuestas[categoria] ?? const []);
    actual.remove(valor);
    respuestas[categoria] = actual;

    cargarDesdeBackend();
  }

  static void actualizarMedicamentos(String texto) {
    respuestas['medicamentosActuales'] = texto.trim();

    cargarDesdeBackend();
  }

  /// Punto único de entrada al chat: si el usuario ya completó la
  /// encuesta, va directo al chat. Si no, primero pasa por la encuesta
  /// y solo al terminarla llega al chat.
  static void abrirChat(BuildContext context) {
    if (completado) {
      Navigator.push(
        context,
        _FadeSlidePageRoute(builder: (_) => const ChatScreen()),
      );
    } else {
      Navigator.push(
        context,
        _FadeSlidePageRoute(builder: (_) => const HealthSurveyScreen()),
      );
    }
  }
}