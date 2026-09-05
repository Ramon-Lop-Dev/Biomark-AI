import 'package:flutter/material.dart';

import '../data/progress_api.dart';
import '../domain/progress_snapshot.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.refreshSignal});

  final ValueNotifier<int>? refreshSignal;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progressApi = ProgressApi();
  late Future<ProgressSnapshot> _progressFuture;
  late Future<List<ProgressGoal>> _goalsFuture;
  final Map<String, bool> _milestoneOverrides = {};

  @override
  void initState() {
    super.initState();
    _reload();
    widget.refreshSignal?.addListener(_reload);
  }

  void _reload() {
    _progressFuture = _progressApi.fetch();
    _goalsFuture = _progressApi.fetchGoals();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_reload);
    super.dispose();
  }

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
              _buildGoalsSection(),
              const SizedBox(height: 20),
              _buildRecentMilestones(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentMilestones() {
    return FutureBuilder<List<ProgressGoal>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        final recent = <ProgressMilestone>[];
        for (final goal in snapshot.data ?? const <ProgressGoal>[]) {
          for (final milestone in goal.milestones) {
            recent.add(ProgressMilestone(
              id: milestone.id,
              title: '${goal.titulo}: ${milestone.title}',
              value: milestone.value,
              subtitle: milestone.subtitle,
              color: milestone.color,
              icon: milestone.icon,
              completed: _completedValue(milestone),
            ));
          }
        }
        recent.sort((a, b) => a.value.compareTo(b.value));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hitos recientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1F1C))),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              _buildNoGoals()
            else
              ...recent.take(5).map((milestone) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MilestoneRow(milestone: milestone),
                  )),
          ],
        );
      },
    );
  }

  Widget _buildGoalsSection() {
    return FutureBuilder<List<ProgressGoal>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        final goals = snapshot.data ?? const <ProgressGoal>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis objetivos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B1F1C)),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(color: Color(0xFF1B8E44))
            else if (goals.isEmpty)
              _buildNoGoals()
            else
              ...goals.map(_buildGoalCard),
          ],
        );
      },
    );
  }

  Widget _buildNoGoals() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Text('Crea un objetivo para comenzar a medir tu mejoría.'),
    );
  }

  Widget _buildGoalCard(ProgressGoal goal) {
    final completed = goal.milestones.where(_completedValue).length;
    final total = goal.milestones.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              Text('$completed/$total', style: const TextStyle(color: Color(0xFF1B8E44), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${goal.periodicidad.toLowerCase()} · ${_formatDate(goal.fechaInicio)} - ${_formatDate(goal.fechaFin)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6D63))),
          if (goal.descripcion != null) ...[
            const SizedBox(height: 4),
            Text(goal.descripcion!, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6D63))),
          ],
          const SizedBox(height: 8),
          ...goal.milestones.map((milestone) => Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _completedValue(milestone),
                  title: Text(milestone.title),
                  subtitle: Text(milestone.value),
                  activeColor: const Color(0xFF1B8E44),
                  onChanged: milestone.id == null ? null : (value) => _toggleMilestone(goal, milestone, value ?? false),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _toggleMilestone(ProgressGoal goal, ProgressMilestone milestone, bool completed) async {
    final milestoneId = milestone.id;
    if (milestoneId == null) return;
    final previous = _completedValue(milestone);
    setState(() => _milestoneOverrides[milestoneId] = completed);
    try {
      await _progressApi.updateMilestone(goalId: goal.id, milestoneId: milestoneId, completed: completed);
      if (!mounted) return;
      final refreshedGoals = _progressApi.fetchGoals();
      setState(() {
        _goalsFuture = refreshedGoals;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _milestoneOverrides[milestoneId] = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'), backgroundColor: Colors.red));
    }
  }

  bool _completedValue(ProgressMilestone milestone) =>
      milestone.id != null && _milestoneOverrides.containsKey(milestone.id)
          ? _milestoneOverrides[milestone.id]!
          : milestone.completed;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

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
