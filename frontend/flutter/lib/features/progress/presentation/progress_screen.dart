import 'package:flutter/material.dart';

import '../data/progress_api.dart';
import '../domain/progress_snapshot.dart';
import '../../vitals/domain/vital_measurement.dart';
import '../../vitals/data/vitals_storage.dart';
import '../../vitals/presentation/scg_screen.dart';
import '../../../core/design/responsive_layout.dart';

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
  late Future<List<EvolutionRecord>> _evolutionFuture;
  final Map<String, bool> _milestoneOverrides = {};
  VitalMeasurement? _latestVital;

  @override
  void initState() {
    super.initState();
    _reload();
    widget.refreshSignal?.addListener(_reload);
  }

  void _reload() {
    _progressFuture = _progressApi.fetch();
    _goalsFuture = _progressApi.fetchGoals();
    _evolutionFuture = _progressApi.fetchEvolutionHistory();
    VitalsStorage.getLatest().then((v) {
      if (mounted) setState(() => _latestVital = v);
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _openScg() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScgScreen()),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProgressSnapshot>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? ProgressApi.defaultSnapshot();
        return Center(
          child: ResponsiveContainer(
            maxWidth: 950,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummary(data),
                  const SizedBox(height: 18),
                  _buildVitalsPulseSummary(),
                  const SizedBox(height: 20),
                  _buildEvolutionSection(),
                  const SizedBox(height: 20),
                  _buildGoalsSection(),
                  const SizedBox(height: 20),
                  _buildRecentMilestones(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Evolución de síntomas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddEvolutionModal,
              icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF1B8E44)),
              label: const Text(
                'Registrar',
                style: TextStyle(
                  color: Color(0xFF1B8E44),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<EvolutionRecord>>(
          future: _evolutionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator(color: Color(0xFF1B8E44));
            }
            final list = snapshot.data ?? const <EvolutionRecord>[];
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 36, color: Color(0xFF8CA593)),
                    const SizedBox(height: 8),
                    const Text(
                      'No hay evolución de síntomas registrada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A564D)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Registra si tu síntoma mejoró, sigue igual o empeoró para dar seguimiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF6E7E72)),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _showAddEvolutionModal,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B8E44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Registrar evolución'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: list.take(5).map(_buildEvolutionCard).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEvolutionCard(EvolutionRecord record) {
    Color badgeBg;
    Color badgeFg;
    IconData badgeIcon;
    String badgeLabel;

    switch (record.estado) {
      case 'MEJORO':
        badgeBg = const Color(0xFFE8F8EE);
        badgeFg = const Color(0xFF1B8E44);
        badgeIcon = Icons.trending_up_rounded;
        badgeLabel = 'Mejoró';
        break;
      case 'IGUAL':
        badgeBg = const Color(0xFFEAF2FD);
        badgeFg = const Color(0xFF1D64D8);
        badgeIcon = Icons.trending_flat_rounded;
        badgeLabel = 'Sigue igual';
        break;
      case 'EMPEORO':
        badgeBg = const Color(0xFFFDE8E8);
        badgeFg = const Color(0xFFD32F2F);
        badgeIcon = Icons.trending_down_rounded;
        badgeLabel = 'Empeoró';
        break;
      case 'NO_SEGURO':
      default:
        badgeBg = const Color(0xFFF3E8FF);
        badgeFg = const Color(0xFF7C3AED);
        badgeIcon = Icons.help_outline_rounded;
        badgeLabel = 'No seguro';
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatRecordDate(record.fechaRegistro),
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  record.sintoma,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (record.intensidad != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Intensidad: ${record.intensidad}/10',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          if (record.notas != null && record.notas!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              record.notas!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddEvolutionModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => _AddEvolutionSheet(
        progressApi: _progressApi,
        onSaved: _reload,
      ),
    );
  }


  String _formatRecordDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes.clamp(1, 60)} min';
    } else if (diff.inHours < 24 && date.day == now.day) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 2) {
      return 'Ayer';
    }
    return '${date.day}/${date.month}/${date.year}';
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
            Text('Hitos recientes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
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
            Text(
              'Mis objetivos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Crea un objetivo para comenzar a medir tu mejoría.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildGoalCard(ProgressGoal goal) {
    final completed = goal.milestones.where(_completedValue).length;
    final total = goal.milestones.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF152A1C), Color(0xFF142436)]
              : const [Color(0xFFEBF9EE), Color(0xFFEAF3FF)],
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
              Text(
                'Tu Evolución',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E2D20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Esta semana',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2C7A32),
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
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF0E3B22),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E8E3E).withValues(alpha: 0.3)
                      : const Color(0xFFDAF6E0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '+${data.deltaPercent}%',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1E8E3E),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF4E5A4F),
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
                            ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF1B8E44))
                            : (isDark ? const Color(0xFF166534) : const Color(0xFF9AD9A6)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lun',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF5C665E)),
              ),
              Text(
                'Mar',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF5C665E)),
              ),
              Text(
                'Mié',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF5C665E)),
              ),
              Text(
                'Jue',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF5C665E)),
              ),
              Text(
                'Hoy',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF5C665E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsPulseSummary() {
    final vital = _latestVital;
    final isNormal = vital?.status == 'NORMAL';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFFEF4444).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frecuencia Cardíaca (SCG)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                if (vital != null) ...[
                  Row(
                    children: [
                      Text(
                        '${vital.bpm} BPM',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${vital.status}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isNormal ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Sin mediciones hoy · Medir en el pecho',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _openScg,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              vital != null ? 'Medir' : 'Chequear',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = milestone.completed
        ? milestone.color
        : (isDark ? Colors.white54 : const Color(0xFF7A7F7A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: milestone.completed
            ? Theme.of(context).cardColor
            : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F6F4)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E7E4)),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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

class _AddEvolutionSheet extends StatefulWidget {
  final ProgressApi progressApi;
  final VoidCallback onSaved;

  const _AddEvolutionSheet({
    required this.progressApi,
    required this.onSaved,
  });

  @override
  State<_AddEvolutionSheet> createState() => _AddEvolutionSheetState();
}

class _AddEvolutionSheetState extends State<_AddEvolutionSheet> {
  late final TextEditingController _symptomController;
  late final TextEditingController _notesController;
  String _selectedStatus = 'MEJORO';
  double _selectedIntensity = 5.0;

  @override
  void initState() {
    super.initState();
    _symptomController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required bool selected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : const Color(0xFF6B756E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : const Color(0xFF2E332F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Registrar Evolución de Síntoma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Indica cómo ha progresado tu salud para actualizar tus estadísticas.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    labelText: 'Síntoma',
                    hintText: 'Ej: Dolor de cabeza, fiebre, tos...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cómo ha evolucionado?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(
                      label: 'Mejoró',
                      value: 'MEJORO',
                      selected: _selectedStatus == 'MEJORO',
                      color: const Color(0xFF1B8E44),
                      icon: Icons.trending_up_rounded,
                      onTap: () => setState(() => _selectedStatus = 'MEJORO'),
                    ),
                    _buildStatusChip(
                      label: 'Sigue igual',
                      value: 'IGUAL',
                      selected: _selectedStatus == 'IGUAL',
                      color: const Color(0xFF1D64D8),
                      icon: Icons.trending_flat_rounded,
                      onTap: () => setState(() => _selectedStatus = 'IGUAL'),
                    ),
                    _buildStatusChip(
                      label: 'Empeoró',
                      value: 'EMPEORO',
                      selected: _selectedStatus == 'EMPEORO',
                      color: const Color(0xFFD32F2F),
                      icon: Icons.trending_down_rounded,
                      onTap: () => setState(() => _selectedStatus = 'EMPEORO'),
                    ),
                    _buildStatusChip(
                      label: 'No seguro',
                      value: 'NO_SEGURO',
                      selected: _selectedStatus == 'NO_SEGURO',
                      color: const Color(0xFF7C3AED),
                      icon: Icons.help_outline_rounded,
                      onTap: () => setState(() => _selectedStatus = 'NO_SEGURO'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nivel de intensidad:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_selectedIntensity.round()}/10',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B8E44)),
                    ),
                  ],
                ),
                Slider(
                  value: _selectedIntensity,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: const Color(0xFF1B8E44),
                  onChanged: (val) => setState(() => _selectedIntensity = val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas adicionales (opcional)',
                    hintText: 'Ej: Bajó la fiebre después de descansar...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8E44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final symptom = _symptomController.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      if (symptom.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Por favor escribe el nombre del síntoma.')),
                        );
                        return;
                      }
                      try {
                        await widget.progressApi.createProgress(
                          symptom: symptom,
                          status: _selectedStatus,
                          intensity: _selectedIntensity.round(),
                          notes: _notesController.text.trim(),
                        );
                        navigator.pop();
                        widget.onSaved();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Evolución guardada correctamente.'),
                            backgroundColor: Color(0xFF1B8E44),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Guardar evolución', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

