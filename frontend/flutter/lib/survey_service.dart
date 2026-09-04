// Servicio simple de estado para la encuesta de salud obligatoria.
//
// Por ahora guarda todo en memoria (se resetea al cerrar la app).
// Cuando conectes tu backend, reemplaza `completado`/`respuestas` por una
// consulta real (o guarda también en SharedPreferences para que persista
// entre sesiones sin depender del backend).
import 'package:flutter/material.dart';

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

  static void guardarRespuestas({
    required List<String> enfermedadesCronicas,
    required List<String> antecedentesHereditarios,
    required List<String> alergias,
    required String medicamentosActuales,
  }) {
    respuestas = {
      'enfermedadesCronicas': enfermedadesCronicas,
      'antecedentesHereditarios': antecedentesHereditarios,
      'alergias': alergias,
      'medicamentosActuales': medicamentosActuales,
    };
    completado = true;

    // TODO: aquí va tu lógica real para persistir esto:
    // - Enviarlo a tu backend/API asociado al usuario logueado
    // - O guardarlo local con SharedPreferences para que sobreviva
    //   a cerrar la app (hasta que tengas backend conectado)
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