// Servicio simple de estado para la encuesta de salud obligatoria.
//
// Por ahora guarda todo en memoria (se resetea al cerrar la app).
// Cuando conectes tu backend, reemplaza `completado`/`respuestas` por una
// consulta real (o guarda también en SharedPreferences para que persista
// entre sesiones sin depender del backend).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'health_survey.dart';
import 'features/chat/presentation/chat_screen.dart';

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

  /// true una vez que el usuario completó la encuesta de salud.
  static bool completado = false;

  /// Respuestas de la encuesta — luego las envías a tu backend/IA.
  static Map<String, dynamic> respuestas = {};

  static Future<void> guardarRespuestas({
    required int edad,
    required String sexo,
    required List<String> enfermedadesCronicas,
    required List<String> antecedentesHereditarios,
    required List<String> alergias,
    required String medicamentosActuales,
    bool consentimientoMedico = true,
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

    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      return;
    }

    final apiUrl = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    try {
      final nacimiento = DateTime(
        DateTime.now().year - edad,
        DateTime.now().month,
        DateTime.now().day,
      );
      await http.put(
        Uri.parse('$apiUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fecha_nacimiento': nacimiento.toIso8601String().split('T').first,
          'sexo': sexo,
        }),
      );
      await http.put(
        Uri.parse('$apiUrl/api/users/consent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipo_consentimiento': 'CONTEXTO_MEDICO_IA',
          'otorgado': consentimientoMedico,
        }),
      );

      final condiciones = enfermedadesCronicas
          .where((item) => item.trim().isNotEmpty)
          .map((item) => item.trim())
          .toSet()
          .toList();
      for (final condicion in condiciones) {
        await http.post(
          Uri.parse('$apiUrl/api/medical-history'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'nombre_condicion': condicion,
            'fecha_diagnostico': DateTime.now().toIso8601String().split('T').first,
            'notas': 'Registrado desde la encuesta de salud inicial.',
          }),
        );
      }

      final antecedentes = antecedentesHereditarios
          .where((item) => item.trim().isNotEmpty)
          .map((item) => item.trim())
          .toSet()
          .toList();
      for (final antecedente in antecedentes) {
        await http.post(
          Uri.parse('$apiUrl/api/medical-history/family-history'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'parentesco': 'Familiar',
            'nombre_condicion': antecedente,
            'notas': 'Registrado desde la encuesta de salud inicial.',
          }),
        );
      }

      final alergiasRegistradas = alergias
          .where((item) => item.trim().isNotEmpty)
          .map((item) => item.trim())
          .toSet()
          .toList();
      for (final alergia in alergiasRegistradas) {
        await http.post(
          Uri.parse('$apiUrl/api/medical-history/allergies'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'alergeno': alergia,
            'severidad': 'LEVE',
            'notas': 'Registrado desde la encuesta de salud inicial.',
          }),
        );
      }

      final medicamentos = medicamentosActuales.trim();
      if (medicamentos.isNotEmpty) {
        await http.post(
          Uri.parse('$apiUrl/api/medical-history/medications'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'nombre_medicamento': medicamentos,
            'dosis': 'No especificada',
            'frecuencia': 'Segun indicación',
            'fecha_inicio': DateTime.now().toIso8601String().split('T').first,
          }),
        );
      }
    } catch (_) {
      // No bloqueamos la experiencia del usuario si la sincronización falla.
      // El estado local ya quedó completado y el chat puede seguir usando el flujo.
    }
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

    // TODO: persistir este cambio también en tu backend
  }

  static void eliminarItem(String categoria, String valor) {
    final actual = List<String>.from(respuestas[categoria] ?? const []);
    actual.remove(valor);
    respuestas[categoria] = actual;

    // TODO: persistir este cambio también en tu backend
  }

  static void actualizarMedicamentos(String texto) {
    respuestas['medicamentosActuales'] = texto.trim();

    // TODO: persistir este cambio también en tu backend
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