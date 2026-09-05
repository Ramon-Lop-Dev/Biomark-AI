import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';

import '../domain/progress_snapshot.dart';

class ProgressApi {
  static const _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      };

  String get _baseUrl => _apiUrl.replaceFirst(RegExp(r'/$'), '');

  Future<List<ProgressGoal>> fetchGoals() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/progress/goals'), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_backendError(response, 'No se pudieron cargar los objetivos.'));
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is List ? decoded : const [];
    return items.whereType<Map<String, dynamic>>().map(ProgressGoal.fromJson).toList();
  }

  Future<ProgressGoal> createGoal({
    required String titulo,
    String? descripcion,
    required String periodicidad,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/progress/goals'),
      headers: _headers,
      body: jsonEncode({
        'titulo': titulo.trim(),
        if (descripcion != null && descripcion.trim().isNotEmpty) 'descripcion': descripcion.trim(),
        'periodicidad': periodicidad,
        'fecha_inicio': _dateOnly(fechaInicio),
        'fecha_fin': _dateOnly(fechaFin),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_backendError(response, 'No se pudo crear el objetivo.'));
    }
    return ProgressGoal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateMilestone({
    required String goalId,
    required String milestoneId,
    required bool completed,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/progress/goals/$goalId/hitos/$milestoneId'),
      headers: _headers,
      body: jsonEncode({'completado': completed}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_backendError(response, 'No se pudo actualizar el hito.'));
    }
  }

  static String _dateOnly(DateTime date) => date.toIso8601String().substring(0, 10);

  static String _backendError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['error'] is String) {
        return body['error'] as String;
      }
    } catch (_) {
      // Conserva un mensaje utilizable aunque el servidor no devuelva JSON.
    }
    return '$fallback (HTTP ${response.statusCode})';
  }

  static ProgressSnapshot defaultSnapshot() {
    return const ProgressSnapshot(
      progressPercent: 85,
      deltaPercent: 14,
      dayIndex: 4,
      trendValues: [52, 58, 68, 64, 78, 82, 92],
      milestones: [
        ProgressMilestone(
          title: 'Fiebre controlada',
          value: 'Ayer',
          subtitle: 'Temperatura estable por debajo de 37.5°C.',
          color: Color(0xFF14A44D),
          icon: Icons.check_circle_rounded,
          completed: true,
        ),
        ProgressMilestone(
          title: 'Hidratación óptima',
          value: 'Hace 2 días',
          subtitle: 'Meta de 2.5 litros diarios lograda.',
          color: Color(0xFF3B82F6),
          icon: Icons.water_drop_rounded,
          completed: true,
        ),
        ProgressMilestone(
          title: 'Fin de la medicación',
          value: 'En 3 días',
          subtitle: 'Ciclo del tratamiento casi terminado.',
          color: Color(0xFF7C3AED),
          icon: Icons.medication_rounded,
          completed: false,
        ),
      ],
      nextMedication:
          'Paracetamol 500mg a las 20:00 hrs. Recuerda tomarlo con alimentos.',
    );
  }

  Future<void> createProgress({
    required String symptom,
    required String status,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/progress',
    );
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'sintoma': symptom,
        'estado': status,
        if (notes != null && notes.trim().isNotEmpty) 'notas': notes.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo registrar la evolución.');
    }
  }

  Future<ProgressSnapshot> fetch() async {
    try {
      final baseUrl = _apiUrl.replaceFirst(RegExp(r'/$'), '');
      final endpoints = [
        Uri.parse('$baseUrl/api/symptoms'),
        Uri.parse('$baseUrl/api/medical-history'),
        Uri.parse('$baseUrl/api/progress'),
      ];
      var symptomCount = 0;
      var medicationCount = 0;
      var progressCount = 0;
      var improvedCount = 0;

      for (final endpoint in endpoints) {
        final response = await http.get(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            if (_accessToken.isNotEmpty)
              'Authorization': 'Bearer $_accessToken',
          },
        );
        if (response.statusCode < 200 || response.statusCode >= 300) continue;

        final decoded = jsonDecode(response.body);
        final items = decoded is List
            ? decoded
            : decoded is Map
            ? decoded['data'] ?? decoded['result'] ?? const []
            : const [];
        if (endpoint.path.contains('/symptoms')) {
          symptomCount = items is List ? items.length : 0;
        } else if (endpoint.path.contains('/medical-history')) {
          medicationCount = items is List ? items.length : 0;
        } else {
          final progressItems = items is List ? items : const [];
          progressCount = progressItems.length;
          improvedCount = progressItems
              .where((item) => item is Map && item['estado'] == 'MEJORO')
              .length;
        }
      }

      final completedMilestones =
          (symptomCount > 0 ? 1 : 0) + (medicationCount > 0 ? 1 : 0);
      final dynamicProgress =
          (70 +
                  (completedMilestones * 5) +
                  (medicationCount > 0 ? 5 : 0) +
                  (improvedCount * 3))
              .clamp(72, 94);
      final delta = (dynamicProgress - 68).clamp(6, 18);

      return ProgressSnapshot(
        progressPercent: dynamicProgress,
        deltaPercent: delta,
        dayIndex: 4,
        trendValues: [52, 58, 68, 64, 78, 82, dynamicProgress],
        milestones: [
          ProgressMilestone(
            title: 'Fiebre controlada',
            value: symptomCount > 0 ? 'Activo' : 'Ayer',
            subtitle: symptomCount > 0
                ? progressCount > 0
                      ? 'Se registró evolución confirmada del estado de salud.'
                      : 'Se registró seguimiento de síntomas correctamente.'
                : 'Temperatura estable por debajo de 37.5°C.',
            color: const Color(0xFF14A44D),
            icon: Icons.check_circle_rounded,
            completed: true,
          ),
          ProgressMilestone(
            title: 'Hidratación óptima',
            value: medicationCount > 0 ? 'OK' : 'Hace 2 días',
            subtitle: medicationCount > 0
                ? 'Tu medicación y seguimiento están registrados.'
                : 'Meta de 2.5 litros diarios lograda.',
            color: const Color(0xFF3B82F6),
            icon: Icons.water_drop_rounded,
            completed: true,
          ),
          ProgressMilestone(
            title: 'Fin de la medicación',
            value: dynamicProgress >= 85 ? 'Cerca' : 'En 3 días',
            subtitle: 'Ciclo del tratamiento casi terminado.',
            color: const Color(0xFF7C3AED),
            icon: Icons.medication_rounded,
            completed: dynamicProgress >= 85,
          ),
        ],
        nextMedication: medicationCount > 0
            ? 'Tu siguiente control está sincronizado con tu historial médico.'
            : 'Paracetamol 500mg a las 20:00 hrs. Recuerda tomarlo con alimentos.',
      );
    } catch (_) {
      return defaultSnapshot();
    }
  }
}
