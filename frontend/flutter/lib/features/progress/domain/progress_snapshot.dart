import 'package:flutter/material.dart';

class ProgressMilestone {
  final String? id;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool completed;

  const ProgressMilestone({
    this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.completed,
  });

  static ProgressMilestone fromJson(Map<String, dynamic> json) {
    final completed = json['completado'] as bool? ?? false;
    return ProgressMilestone(
      id: json['id'] as String?,
      title: json['titulo'] as String? ?? 'Hito',
      value: json['fecha_objetivo'] as String? ?? '',
      subtitle: completed ? 'Completado' : 'Pendiente',
      color: completed ? const Color(0xFF14A44D) : const Color(0xFF3B82F6),
      icon: completed ? Icons.check_circle_rounded : Icons.flag_outlined,
      completed: completed,
    );
  }
}

class ProgressSnapshot {
  final int progressPercent;
  final int deltaPercent;
  final int dayIndex;
  final List<int> trendValues;
  final List<ProgressMilestone> milestones;
  final String nextMedication;

  const ProgressSnapshot({
    required this.progressPercent,
    required this.deltaPercent,
    required this.dayIndex,
    required this.trendValues,
    required this.milestones,
    required this.nextMedication,
  });
}

class ProgressGoal {
  final String id;
  final String titulo;
  final String? descripcion;
  final String periodicidad;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final List<ProgressMilestone> milestones;

  const ProgressGoal({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.periodicidad,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.milestones,
  });

  factory ProgressGoal.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['hitos_mejoria'] as List<dynamic>? ?? const [];
    return ProgressGoal(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      periodicidad: json['periodicidad'] as String? ?? 'SEMANAL',
      fechaInicio: DateTime.tryParse(json['fecha_inicio'] as String? ?? '') ?? DateTime.now(),
      fechaFin: DateTime.tryParse(json['fecha_fin'] as String? ?? '') ?? DateTime.now(),
      estado: json['estado'] as String? ?? 'ACTIVO',
      milestones: rawMilestones
          .whereType<Map<String, dynamic>>()
          .map(ProgressMilestone.fromJson)
          .toList(),
    );
  }
}
