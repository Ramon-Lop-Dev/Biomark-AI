import 'package:flutter/material.dart';

enum RecommendationCategory {
  dengue,
  heatWave,
  cardiovascular,
  treatment,
  minsaNotice,
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
  });
}
