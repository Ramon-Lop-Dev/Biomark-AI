import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../biomark_brand.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/profile/user_profile_api.dart';
import '../../vitals/domain/vital_measurement.dart';
import '../../vitals/data/vitals_storage.dart';
import '../../vitals/presentation/scg_screen.dart';
import '../../../core/design/biomark_glass_surface.dart';
import '../../../core/design/responsive_layout.dart';
import '../../profile/presentation/notifications_inbox_screen.dart';
import '../../progress/data/progress_api.dart';
import '../../progress/presentation/add_evolution_sheet.dart';
import '../../reminders/data/reminders_service.dart';
import '../data/health_content_api.dart';
import '../domain/health_content_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenMap,
    this.onNavigateToTab,
  });

  final VoidCallback? onOpenMap;
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = 'usuario';
  VitalMeasurement? _latestVital;
  bool _loadingVitals = true;
  bool _mostrarBannerVoz = true;

  // Evolución de Síntomas
  final ProgressApi _progressApi = ProgressApi();
  List<EvolutionRecord> _evolutionRecords = const [];
  bool _loadingEvolution = true;
  int _evolutionTimeframeDays = 7; // 7, 30, 90

  // Próximos Recordatorios
  List<Reminder> _reminders = const [];
  bool _loadingReminders = true;

  // Información Médica Confiable
  List<HealthContentItem> _healthArticles = const [];
  bool _loadingContent = true;
  String _selectedCategory = 'Todas';

  final List<String> _categories = const [
    'Todas',
    'Prevención',
    'Cardiovascular',
    'Nutrición',
    'Pediatría',
  ];

  @override
  void initState() {
    super.initState();
    final cached = AuthSession.instance.userName;
    if (cached != null && cached.trim().isNotEmpty) {
      _nombreUsuario = cached.trim().split(' ').first;
    }
    _cargarNombreUsuario();
    _cargarUltimoSignoVital();
    _cargarPreferenciaBannerVoz();
    _cargarEvolucionSintomas();
    _cargarRecordatorios();
    _cargarContenidoSalud();
  }

  Future<void> _cargarPreferenciaBannerVoz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _mostrarBannerVoz = prefs.getBool('mostrar_banner_asistente_voz') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final profile = await UserProfileApi.fetch();
      if (!mounted) return;
      if (profile != null) {
        await AuthSession.instance.updateProfile(
          name: profile.displayName,
          email: profile.email,
        );
        final firstName = profile.displayName.split(' ').first;
        setState(() => _nombreUsuario = firstName);
      }
    } catch (_) {}
  }

  Future<void> _cargarUltimoSignoVital() async {
    try {
      final vital = await VitalsStorage.getLatest();
      if (!mounted) return;
      setState(() {
        _latestVital = vital;
        _loadingVitals = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingVitals = false);
    }
  }

  Future<void> _cargarEvolucionSintomas() async {
    try {
      final list = await _progressApi.fetchEvolutionHistory();
      if (!mounted) return;
      setState(() {
        _evolutionRecords = list;
        _loadingEvolution = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEvolution = false);
    }
  }

  Future<void> _cargarRecordatorios() async {
    try {
      final service = RemindersService(
        baseUrl: AppConfig.apiUrl,
        accessToken: AuthSession.instance.accessToken ?? '',
      );
      final list = await service.getReminders();
      if (!mounted) return;
      setState(() {
        _reminders = list.where((r) => r.estado != 'CANCELADO' && r.estado != 'COMPLETADO').toList();
        _loadingReminders = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  Future<void> _cargarContenidoSalud() async {
    if (!mounted) return;
    setState(() => _loadingContent = true);
    try {
      final catParam = _selectedCategory == 'Todas' ? null : _selectedCategory.toUpperCase();
      final items = await HealthContentApi.fetchContent(categoria: catParam);
      if (!mounted) return;
      setState(() {
        _healthArticles = items;
        _loadingContent = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Future<void> _openScgScreen() async {
    final result = await Navigator.push<VitalMeasurement?>(
      context,
      MaterialPageRoute(builder: (_) => const ScgScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _latestVital = result;
      });
    } else {
      _cargarUltimoSignoVital();
    }
  }

  Future<void> _showAddEvolution() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEvolutionSheet(
        progressApi: _progressApi,
        onSaved: _cargarEvolucionSintomas,
      ),
    );
  }

  Future<void> _completeReminder(Reminder reminder) async {
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      await RemindersService(baseUrl: base, accessToken: token)
          .updateReminderStatus(reminderId: reminder.id, estado: 'COMPLETADO');
      _cargarRecordatorios();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio completado'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveContainer(
        maxWidth: 960,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _cargarNombreUsuario(),
              _cargarUltimoSignoVital(),
              _cargarEvolucionSintomas(),
              _cargarRecordatorios(),
              _cargarContenidoSalud(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              // ==========================================
              // SECCIÓN 1: RESUMEN DE SALUD
              // ==========================================
              _buildGreetingHeader().animate().fadeIn(duration: 350.ms),
              if (_mostrarBannerVoz) ...[
                const SizedBox(height: 14),
                _buildVoiceAccessibilityBanner().animate().fadeIn(duration: 400.ms),
              ],
              const SizedBox(height: 16),
              _buildVitalPulseCard().animate().fadeIn(duration: 450.ms),

              const SizedBox(height: 28),

              // ==========================================
              // SECCIÓN 2: EVOLUCIÓN DE SÍNTOMAS
              // ==========================================
              _buildSymptomEvolutionSection().animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 28),

              // ==========================================
              // SECCIÓN 3: PRÓXIMOS RECORDATORIOS
              // ==========================================
              _buildUpcomingRemindersSection().animate().fadeIn(duration: 550.ms),

              const SizedBox(height: 28),

              // ==========================================
              // SECCIÓN 4: INFORMACIÓN MÉDICA CONFIABLE
              // ==========================================
              _buildOfficialContentSection().animate().fadeIn(duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 1: RESUMEN DE SALUD WIDGETS
  // =========================================================================

  Widget _buildGreetingHeader() {
    final now = DateTime.now();
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final dateStr = '${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $_nombreUsuario!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notificaciones y Avisos',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BiomarkColors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, size: 20, color: BiomarkColors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceAccessibilityBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Asistente por Voz de Biomark AI. Toca para hablar directamente.',
      button: true,
      child: BiomarkGlassSurface(
        onTap: () => widget.onNavigateToTab?.call(1),
        borderColor: BiomarkColors.blue.withValues(alpha: isDark ? 0.3 : 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BiomarkColors.blue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BiomarkColors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BiomarkColors.blue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACCESIBILIDAD UNIVERSAL',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: BiomarkColors.blue,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Modo Asistido por Voz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Habla con tu asistente de salud sin leer ni escribir.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              tooltip: 'Ocultar sugerencia',
              onPressed: () async {
                setState(() => _mostrarBannerVoz = false);
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('mostrar_banner_asistente_voz', false);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalPulseCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingVitals) {
      return BiomarkGlassSurface(
        padding: const EdgeInsets.all(22),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final vital = _latestVital;
    final isNormal = vital?.status == 'NORMAL';

    return BiomarkGlassSurface(
      borderColor: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.4),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frecuencia Cardíaca (SCG Pecho)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                    ),
                    Text(
                      vital != null
                          ? 'Último chequeo: ${vital.statusLabel}'
                          : 'Monitoreo preventivo mediante sensores mecánicos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (vital != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vital.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isNormal ? const Color(0xFF059669) : const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (vital != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${vital.bpm}',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  '${vital.timestamp.day}/${vital.timestamp.month} · ${vital.timestamp.hour.toString().padLeft(2, '0')}:${vital.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Coloca tu teléfono sobre el pecho durante 18 segundos para registrar tu pulso mediante microvibraciones cardíacas.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openScgScreen,
              icon: const Icon(Icons.sensors_rounded, size: 18),
              label: Text(
                vital != null ? 'Volver a Medir Pulso SCG' : 'Medir Pulso Cardíaco (SCG)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 2: EVOLUCIÓN DE SÍNTOMAS WIDGETS
  // =========================================================================

  Widget _buildSymptomEvolutionSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrar según el período seleccionado (7, 30 o 90 días)
    final cutoff = DateTime.now().subtract(Duration(days: _evolutionTimeframeDays));
    final filtered = _evolutionRecords.where((r) => r.fechaRegistro.isAfter(cutoff)).toList();

    // Métricas clave
    final totalCount = filtered.length;
    final recordsWithIntensity = filtered.where((r) => r.intensidad != null).toList();
    final avgIntensity = recordsWithIntensity.isNotEmpty
        ? (recordsWithIntensity.map((r) => r.intensidad!).reduce((a, b) => a + b) / recordsWithIntensity.length)
        : null;

    // Mejoría
    final improvedCount = filtered.where((r) => r.estado == 'MEJORO').length;
    final improvementPct = totalCount > 0 ? ((improvedCount / totalCount) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón de registrar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 20, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Evolución de Síntomas',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Seguimiento clínico continuo y tendencias',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _showAddEvolution,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Registrar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Selector de período: 7 días, 30 días, 90 días
        Row(
          children: [7, 30, 90].map((days) {
            final isSelected = _evolutionTimeframeDays == days;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$days días'),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _evolutionTimeframeDays = days);
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // 3 Tarjetas de métricas
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Intensidad',
                value: avgIntensity != null ? '${avgIntensity.toStringAsFixed(1)} / 10' : '--',
                subtitle: avgIntensity != null
                    ? (avgIntensity <= 3 ? 'Leve' : avgIntensity <= 6 ? 'Moderada' : 'Severa')
                    : 'Sin datos',
                color: const Color(0xFF3B82F6),
                icon: Icons.speed_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Registros',
                value: '$totalCount',
                subtitle: 'En $_evolutionTimeframeDays días',
                color: const Color(0xFF8B5CF6),
                icon: Icons.history_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Mejoría',
                value: totalCount > 0 ? '↓ $improvementPct%' : '--',
                subtitle: totalCount > 0 ? '$improvedCount mejoraron' : 'Sin datos',
                color: const Color(0xFF10B981),
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Gráfico fl_chart interactivo
        _buildEvolutionChartCard(filtered),

        const SizedBox(height: 14),

        // Síntomas monitoreados chips / lista
        _buildMonitoredSymptomsList(filtered),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChartCard(List<EvolutionRecord> filtered) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingEvolution) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, size: 38, color: Colors.grey.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            const Text(
              'Aún no hay registros en este período',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Registra cómo te sientes hoy para visualizar tu evolución y patrones clínicos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showAddEvolution,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Registrar evolución', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    // Ordenar cronológicamente
    final sorted = List<EvolutionRecord>.from(filtered)
      ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

    // Generar FlSpots para la curva
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final intensity = sorted[i].intensidad?.toDouble() ?? 5.0;
      spots.add(FlSpot(i.toDouble(), intensity));
    }

    // Si solo hay un registro, agregamos un punto inicial para ver la línea
    if (spots.length == 1) {
      spots.insert(0, FlSpot(0, spots[0].y));
      spots[1] = FlSpot(1, spots[1].y);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
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
                'Intensidad del Síntoma (0-10)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tendencia en tiempo',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
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
                      interval: (spots.length / 4).ceilToDouble().clamp(1.0, 10.0),
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
                          const Color(0xFF10B981).withValues(alpha: 0.28),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final symptom = (idx >= 0 && idx < sorted.length)
                            ? sorted[idx].sintoma
                            : 'Síntoma';
                        return LineTooltipItem(
                          '$symptom\nIntensidad: ${spot.y.toInt()}/10',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoredSymptomsList(List<EvolutionRecord> filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Agrupar síntomas únicos con su estado más reciente
    final Map<String, EvolutionRecord> latestBySymptom = {};
    for (final rec in filtered) {
      final key = rec.sintoma.toLowerCase().trim();
      if (!latestBySymptom.containsKey(key) ||
          rec.fechaRegistro.isAfter(latestBySymptom[key]!.fechaRegistro)) {
        latestBySymptom[key] = rec;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Síntomas Monitoreados Recientemente',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: latestBySymptom.values.take(6).map((rec) {
            Color chipColor;
            IconData chipIcon;
            String statusText;

            switch (rec.estado) {
              case 'MEJORO':
                chipColor = const Color(0xFF10B981);
                chipIcon = Icons.trending_up_rounded;
                statusText = 'Mejoró';
                break;
              case 'IGUAL':
                chipColor = const Color(0xFF3B82F6);
                chipIcon = Icons.trending_flat_rounded;
                statusText = 'Estable';
                break;
              case 'EMPEORO':
                chipColor = const Color(0xFFEF4444);
                chipIcon = Icons.trending_down_rounded;
                statusText = 'Empeoró';
                break;
              default:
                chipColor = const Color(0xFF8B5CF6);
                chipIcon = Icons.help_outline_rounded;
                statusText = 'Observando';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: chipColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chipIcon, size: 14, color: chipColor),
                  const SizedBox(width: 5),
                  Text(
                    rec.sintoma,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '· $statusText',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =========================================================================
  // SECCIÓN 3: PRÓXIMOS RECORDATORIOS WIDGETS
  // =========================================================================

  Widget _buildUpcomingRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm_on_rounded, size: 20, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  'Próximos Recordatorios',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab?.call(3),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Tratamientos, medicamentos y citas de control',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingReminders)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_reminders.isEmpty)
          _buildEmptyRemindersCard()
        else
          ..._reminders.take(3).map(_buildReminderItemCard),
      ],
    );
  }

  Widget _buildEmptyRemindersCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0284C7), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Todo al día por hoy',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  'No tienes tratamientos ni citas pendientes en este momento.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => widget.onNavigateToTab?.call(3),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              side: const BorderSide(color: Color(0xFF0284C7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItemCard(Reminder reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData icon;

    switch (reminder.tipo.toUpperCase()) {
      case 'MEDICAMENTO':
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.medication_rounded;
        break;
      case 'VACUNA':
        iconColor = const Color(0xFF10B981);
        icon = Icons.vaccines_rounded;
        break;
      case 'CITA':
        iconColor = const Color(0xFF8B5CF6);
        icon = Icons.calendar_month_rounded;
        break;
      default:
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.monitor_heart_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.descripcion ?? 'Tratamiento programado',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      reminder.hora ?? 'Pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reminder.frecuencia.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Marcar como tomado',
            onPressed: () => _completeReminder(reminder),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 4: INFORMACIÓN MÉDICA CONFIABLE WIDGETS
  // =========================================================================

  Widget _buildOfficialContentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, size: 20, color: BiomarkColors.blue),
            const SizedBox(width: 8),
            Text(
              'Información Médica Confiable',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Pautas y normas oficiales verificadas de MINSA Nicaragua y OPS/OMS',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Filtro horizontal por categoría
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                      _cargarContenidoSalud();
                    }
                  },
                  selectedColor: BiomarkColors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        if (_loadingContent)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_healthArticles.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No hay artículos oficiales en esta categoría por el momento.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _healthArticles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return _buildOfficialContentCard(_healthArticles[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOfficialContentCard(HealthContentItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMinsa = item.fuente.contains('MINSA');

    return Semantics(
      label: 'Artículo de salud: ${item.titulo}. Fuente oficial: ${item.fuente}',
      button: true,
      child: InkWell(
        onTap: () => _openArticleModal(item),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isMinsa ? const Color(0xFF10B981) : BiomarkColors.blue).withValues(alpha: 0.3),
              width: 1.2,
            ),
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
              // Badge de fuente oficial verificada
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isMinsa ? const Color(0xFF10B981) : BiomarkColors.blue).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.fuente,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.categoria,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.titulo,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  item.descripcion,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 12, color: Colors.grey.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '3 min lectura',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Leer pautas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openArticleModal(HealthContentItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMinsa = item.fuente.contains('MINSA');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: SafeArea(
              top: false,
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
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isMinsa ? const Color(0xFF10B981) : BiomarkColors.blue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item.fuente,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.fechaPublicacion.day}/${item.fechaPublicacion.month}/${item.fechaPublicacion.year}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.titulo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.descripcion,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      item.contenido,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 20, color: BiomarkColors.blue),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Contenido alineado con normativas técnicas oficiales del Ministerio de Salud (MINSA).',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMinsa ? const Color(0xFF059669) : BiomarkColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
