import 'package:flutter/material.dart';

import '../data/progress_api.dart';
import '../domain/progress_snapshot.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final Future<ProgressSnapshot> _progressFuture = ProgressApi().fetch();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgressSnapshot>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? ProgressApi.defaultSnapshot();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(data),
              const SizedBox(height: 20),
              const Text(
                'Hitos Recientes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1F1C),
                ),
              ),
              const SizedBox(height: 12),
              ...data.milestones.map(
                (milestone) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MilestoneRow(milestone: milestone),
                ),
              ),
              _buildNextMedication(data.nextMedication),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(ProgressSnapshot data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEBF9EE), Color(0xFFEAF3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tu Evolución',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2D20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Esta semana',
                  style: TextStyle(
                    color: Color(0xFF2C7A32),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.progressPercent}%',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E3B22),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAF6E0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '+${data.deltaPercent}%',
                  style: const TextStyle(
                    color: Color(0xFF1E8E3E),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Día ${data.dayIndex} de 7',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5A4F),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                data.trendValues.length,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: data.trendValues[index] / 100 * 110,
                      decoration: BoxDecoration(
                        color: index == data.trendValues.length - 1
                            ? const Color(0xFF1B8E44)
                            : const Color(0xFF9AD9A6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lun',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C665E)),
              ),
              Text(
                'Mar',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C665E)),
              ),
              Text(
                'Mié',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C665E)),
              ),
              Text(
                'Jue',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C665E)),
              ),
              Text(
                'Hoy',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C665E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextMedication(String medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próxima toma',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1F1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medication,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F6D63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ProgressMilestone milestone;

  const _MilestoneRow({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final color = milestone.completed
        ? milestone.color
        : const Color(0xFF7A7F7A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: milestone.completed ? Colors.white : const Color(0xFFF4F6F4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: milestone.completed
                  ? milestone.color.withValues(alpha: 0.12)
                  : const Color(0xFFE4E7E4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              milestone.completed
                  ? milestone.icon
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1F1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C736F),
                  ),
                ),
              ],
            ),
          ),
          Text(
            milestone.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
