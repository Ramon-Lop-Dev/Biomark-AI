import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/progress_api.dart';
import 'add_evolution_sheet.dart';
import '../../../core/design/responsive_layout.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.refreshSignal});

  final ValueNotifier<int>? refreshSignal;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progressApi = ProgressApi();
  late Future<List<EvolutionRecord>> _evolutionFuture;
  String _filterStatus = 'TODOS'; // TODOS, MEJORO, IGUAL, EMPEORO

  @override
  void initState() {
    super.initState();
    _reload();
    widget.refreshSignal?.addListener(_reload);
  }

  void _reload() {
    _evolutionFuture = _progressApi.fetchEvolutionHistory();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _showAddEvolutionModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEvolutionSheet(
        progressApi: _progressApi,
        onSaved: _reload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveContainer(
        maxWidth: 950,
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<EvolutionRecord>>(
            future: _evolutionFuture,
            builder: (context, snapshot) {
              final list = snapshot.data ?? const <EvolutionRecord>[];
              final loading = snapshot.connectionState == ConnectionState.waiting;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClinicalEvolutionHeader(list),
                    const SizedBox(height: 20),
                    if (list.isNotEmpty) ...[
                      _buildEvolutionTrendChart(list),
                      const SizedBox(height: 20),
                    ],
                    _buildSymptomListSection(list, loading),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalEvolutionHeader(List<EvolutionRecord> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = records.length;
    final improvedCount = records.where((r) => r.estado == 'MEJORO').length;
    final improvementPct = totalCount > 0 ? ((improvedCount / totalCount) * 100).round() : 0;

    final withIntensity = records.where((r) => r.intensidad != null).toList();
    final avgIntensity = withIntensity.isNotEmpty
        ? (withIntensity.map((r) => r.intensidad!).reduce((a, b) => a + b) / withIntensity.length)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F291E), Color(0xFF132238)]
              : const [Color(0xFFE8F8EE), Color(0xFFEBF3FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded, size: 22, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolución Clínica',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F291E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monitoreo y recuperación continua de síntomas',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF4A6153),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 420;
              if (isSmall) {
                return Column(
                  children: [
                    _buildMetricTile(
                      label: 'Tasa de Mejoría',
                      value: totalCount > 0 ? '$improvementPct%' : '--',
                      subtitle: '$improvedCount de $totalCount casos',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Intensidad Media',
                            value: avgIntensity != null ? avgIntensity.toStringAsFixed(1) : '--',
                            subtitle: avgIntensity != null ? 'Escala 0 a 10' : 'Sin datos',
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Total Registros',
                            value: '$totalCount',
                            subtitle: 'Seguimiento',
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Tasa de Mejoría',
                      value: totalCount > 0 ? '$improvementPct%' : '--',
                      subtitle: '$improvedCount de $totalCount casos',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Intensidad Media',
                      value: avgIntensity != null ? avgIntensity.toStringAsFixed(1) : '--',
                      subtitle: avgIntensity != null ? 'Escala de 0 a 10' : 'Sin datos',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Total Registros',
                      value: '$totalCount',
                      subtitle: 'Seguimiento activo',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF526356),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF6E7E72),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionTrendChart(List<EvolutionRecord> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sorted = List<EvolutionRecord>.from(records)
      ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), (sorted[i].intensidad ?? 5).toDouble()));
    }

    if (spots.length == 1) {
      spots.insert(0, FlSpot(0, spots[0].y));
      spots[1] = FlSpot(1, spots[1].y);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Curva Histórica de Intensidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '0 (Mínimo) - 10 (Máximo)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 5).ceilToDouble().clamp(1.0, 10.0),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                        final rec = sorted[idx];
                        return Text(
                          '${rec.fechaRegistro.day}/${rec.fechaRegistro.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 4,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF10B981),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.25),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomListSection(List<EvolutionRecord> records, bool loading) {
    final filtered = _filterStatus == 'TODOS'
        ? records
        : records.where((r) => r.estado == _filterStatus).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historial de Síntomas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${filtered.length} registrados',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filtros de estado: TODOS, MEJORO, IGUAL, EMPEORO
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Todos', 'TODOS'),
              _buildFilterChip('Mejoró', 'MEJORO'),
              _buildFilterChip('Sigue igual', 'IGUAL'),
              _buildFilterChip('Empeoró', 'EMPEORO'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
          )
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.sentiment_satisfied_alt_rounded, size: 40, color: Color(0xFF8CA593)),
                const SizedBox(height: 8),
                const Text(
                  'No hay registros con este filtro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra la evolución de tus síntomas para dar seguimiento continuo a tu salud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showAddEvolutionModal,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Toca aquí o el botón (+) para registrar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map(_buildEvolutionCard),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _filterStatus = value);
        },
        selectedColor: const Color(0xFF10B981),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
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
        badgeFg = const Color(0xFF10B981);
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
      default:
        badgeBg = const Color(0xFFF3E8FF);
        badgeFg = const Color(0xFF7C3AED);
        badgeIcon = Icons.help_outline_rounded;
        badgeLabel = 'Observando';
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
}
