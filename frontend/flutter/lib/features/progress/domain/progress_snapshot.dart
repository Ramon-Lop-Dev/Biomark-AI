import 'package:flutter/material.dart';

class ProgressMilestone {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool completed;

  const ProgressMilestone({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.completed,
  });
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
