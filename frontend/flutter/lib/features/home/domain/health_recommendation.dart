import 'package:flutter/material.dart';

enum RecommendationCategory {
  dengue,
  heatWave,
  cardiovascular,
  treatment,
  minsaNotice,
  diabetes,
  respiratory,
}

class HealthRecommendation {
  final String id;
  final RecommendationCategory category;
  final String title;
  final String summary;
  final String details;
  final IconData icon;
  final Color accentColor;
  final String? minsaNormative;
  final String tag;
  final List<String> keyPoints;
  final List<String> targetConditions;
  final List<String> targetDiseases;
  final List<String> targetMunicipalities;
  final int? minAge;
  final int? maxAge;
  final int relevanceScore;
  final String? dynamicBadge;

  const HealthRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.details,
    required this.icon,
    required this.accentColor,
    this.minsaNormative,
    required this.tag,
    this.keyPoints = const [],
    this.targetConditions = const [],
    this.targetDiseases = const [],
    this.targetMunicipalities = const [],
    this.minAge,
    this.maxAge,
    this.relevanceScore = 1,
    this.dynamicBadge,
  });

  static RecommendationCategory categoryFromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'dengue':
        return RecommendationCategory.dengue;
      case 'heatwave':
      case 'heat_wave':
      case 'golpe_calor':
      case 'calor':
        return RecommendationCategory.heatWave;
      case 'cardiovascular':
      case 'cardio':
        return RecommendationCategory.cardiovascular;
      case 'treatment':
      case 'adherencia':
      case 'tratamiento':
        return RecommendationCategory.treatment;
      case 'minsanotice':
      case 'minsa_notice':
      case 'aviso_minsa':
        return RecommendationCategory.minsaNotice;
      case 'diabetes':
      case 'metabolica':
        return RecommendationCategory.diabetes;
      case 'respiratory':
      case 'respiratoria':
      case 'asma':
        return RecommendationCategory.respiratory;
      default:
        return RecommendationCategory.minsaNotice;
    }
  }

  static String categoryToString(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return 'dengue';
      case RecommendationCategory.heatWave:
        return 'heatWave';
      case RecommendationCategory.cardiovascular:
        return 'cardiovascular';
      case RecommendationCategory.treatment:
        return 'treatment';
      case RecommendationCategory.minsaNotice:
        return 'minsaNotice';
      case RecommendationCategory.diabetes:
        return 'diabetes';
      case RecommendationCategory.respiratory:
        return 'respiratory';
    }
  }

  static String labelForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return 'Dengue y Arbovirosis';
      case RecommendationCategory.heatWave:
        return 'Golpe de Calor y Clima';
      case RecommendationCategory.cardiovascular:
        return 'Salud Cardiovascular';
      case RecommendationCategory.treatment:
        return 'Adherencia Farmacológica';
      case RecommendationCategory.minsaNotice:
        return 'Aviso Oficial MINSA';
      case RecommendationCategory.diabetes:
        return 'Diabetes y Metabolismo';
      case RecommendationCategory.respiratory:
        return 'Salud Respiratoria';
    }
  }

  static Color colorForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return const Color(0xFFEF4444); // Rojo Alerta
      case RecommendationCategory.heatWave:
        return const Color(0xFF0EA5E9); // Celeste Océano
      case RecommendationCategory.cardiovascular:
        return const Color(0xFFE11D48); // Carmesí Vital
      case RecommendationCategory.treatment:
        return const Color(0xFF10B981); // Verde Esmeralda
      case RecommendationCategory.minsaNotice:
        return const Color(0xFF6366F1); // Violeta Cobalto
      case RecommendationCategory.diabetes:
        return const Color(0xFFF59E0B); // Ámbar Nutrición
      case RecommendationCategory.respiratory:
        return const Color(0xFF06B6D4); // Turquesa Aire
    }
  }

  static IconData iconForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return Icons.shield_rounded;
      case RecommendationCategory.heatWave:
        return Icons.water_drop_rounded;
      case RecommendationCategory.cardiovascular:
        return Icons.favorite_rounded;
      case RecommendationCategory.treatment:
        return Icons.medication_rounded;
      case RecommendationCategory.minsaNotice:
        return Icons.campaign_rounded;
      case RecommendationCategory.diabetes:
        return Icons.restaurant_rounded;
      case RecommendationCategory.respiratory:
        return Icons.air_rounded;
    }
  }

  static String defaultTagForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return 'Salud Vectorial MINSA';
      case RecommendationCategory.heatWave:
        return 'Clima y Termorregulación';
      case RecommendationCategory.cardiovascular:
        return 'Cardiovascular';
      case RecommendationCategory.treatment:
        return 'Farmacovigilancia';
      case RecommendationCategory.minsaNotice:
        return 'Pauta Oficial MINSA';
      case RecommendationCategory.diabetes:
        return 'Metabólica y Nutrición';
      case RecommendationCategory.respiratory:
        return 'Salud Respiratoria';
    }
  }

  static String defaultNormativeForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.dengue:
        return 'Normativa 004 MINSA - Protocolo de Abordaje del Dengue';
      case RecommendationCategory.heatWave:
        return 'Guía Técnica MINSA para Emergencias Climáticas';
      case RecommendationCategory.cardiovascular:
        return 'Protocolo de Prevención de Enfermedades Crónicas MINSA';
      case RecommendationCategory.treatment:
        return 'Estrategia de Uso Racional de Medicamentos MINSA';
      case RecommendationCategory.minsaNotice:
        return 'Directriz Nacional de Salud Pública MINSA';
      case RecommendationCategory.diabetes:
        return 'Normativa 078 MINSA - Manejo de la Diabetes Mellitus';
      case RecommendationCategory.respiratory:
        return 'Normativa 028 MINSA - Abordaje de Infecciones Respiratorias Agudas';
    }
  }

  HealthRecommendation copyWith({
    String? id,
    RecommendationCategory? category,
    String? title,
    String? summary,
    String? details,
    IconData? icon,
    Color? accentColor,
    String? minsaNormative,
    String? tag,
    List<String>? keyPoints,
    List<String>? targetConditions,
    List<String>? targetDiseases,
    List<String>? targetMunicipalities,
    int? minAge,
    int? maxAge,
    int? relevanceScore,
    String? dynamicBadge,
  }) {
    return HealthRecommendation(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      details: details ?? this.details,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      minsaNormative: minsaNormative ?? this.minsaNormative,
      tag: tag ?? this.tag,
      keyPoints: keyPoints ?? this.keyPoints,
      targetConditions: targetConditions ?? this.targetConditions,
      targetDiseases: targetDiseases ?? this.targetDiseases,
      targetMunicipalities: targetMunicipalities ?? this.targetMunicipalities,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      dynamicBadge: dynamicBadge ?? this.dynamicBadge,
    );
  }

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    final cat = categoryFromString(json['categoria'] as String?);
    final colorHex = json['color_hex'] as String?;
    Color parsedColor = colorForCategory(cat);
    if (colorHex != null && colorHex.startsWith('#') && colorHex.length == 7) {
      final val = int.tryParse(colorHex.substring(1), radix: 16);
      if (val != null) parsedColor = Color(0xFF000000 | val);
    }

    final pointsRaw = json['puntos_clave'];
    final points = pointsRaw is List
        ? pointsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final condRaw = json['condiciones_diana'];
    final conditions = condRaw is List
        ? condRaw.map((e) => e.toString().toLowerCase()).toList()
        : <String>[];

    final alertsRaw = json['alertas_diana'];
    final diseases = alertsRaw is List
        ? alertsRaw.map((e) => e.toString().toLowerCase()).toList()
        : <String>[];

    final muniRaw = json['municipios_objetivo'];
    final municipalities = muniRaw is List
        ? muniRaw.map((e) => e.toString()).toList()
        : <String>[];

    return HealthRecommendation(
      id: json['id']?.toString() ?? '',
      category: cat,
      title: json['titulo']?.toString() ?? '',
      summary: json['resumen']?.toString() ?? '',
      details: json['detalle_clinico']?.toString() ?? '',
      icon: iconForCategory(cat),
      accentColor: parsedColor,
      minsaNormative: json['normativa_minsa']?.toString(),
      tag: json['etiqueta']?.toString() ?? defaultTagForCategory(cat),
      keyPoints: points,
      targetConditions: conditions,
      targetDiseases: diseases,
      targetMunicipalities: municipalities,
      minAge: json['edad_minima'] is int ? json['edad_minima'] as int : null,
      maxAge: json['edad_maxima'] is int ? json['edad_maxima'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria': categoryToString(category),
      'titulo': title,
      'resumen': summary,
      'detalle_clinico': details,
      'normativa_minsa': minsaNormative,
      'etiqueta': tag,
      'color_hex': '#${accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'puntos_clave': keyPoints,
      'condiciones_diana': targetConditions,
      'alertas_diana': targetDiseases,
      'municipios_objetivo': targetMunicipalities,
      'edad_minima': minAge,
      'edad_maxima': maxAge,
    };
  }
}
