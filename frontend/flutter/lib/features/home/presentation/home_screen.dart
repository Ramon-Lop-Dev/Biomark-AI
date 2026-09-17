import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../biomark_brand.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/profile/user_profile_api.dart';
import '../../../survey_service.dart';
import '../../gis/presentation/gis_map_screen.dart';
import '../../vitals/domain/vital_measurement.dart';
import '../../vitals/data/vitals_storage.dart';
import '../../vitals/presentation/ppg_screen.dart';
import '../../vitals/presentation/scg_screen.dart';
import '../domain/health_recommendation.dart';
import '../data/recommendations_service.dart';
import '../../../core/design/responsive_layout.dart';

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

  int _totalCases = 0;
  int _validatedReports = 0;
  List<_CommunitySignal> _signals = const [];
  List<_CommunityEvent> _events = const [];
  bool _loadingCommunity = true;
  String? _communityError;

  final List<HealthRecommendation> _recommendations = RecommendationsService.getRecommendations();

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _cargarUltimoSignoVital();
    _cargarPanoramaComunitario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final profile = await UserProfileApi.fetch();
      if (!mounted) return;
      if (profile != null) {
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

  Future<void> _cargarPanoramaComunitario() async {
    if (mounted) {
      setState(() {
        _loadingCommunity = true;
        _communityError = null;
      });
    }
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final responses = await Future.wait([
        http.get(Uri.parse('$base/api/community/statistics'), headers: headers),
        http.get(Uri.parse('$base/api/community/heatmap'), headers: headers),
        http.get(Uri.parse('$base/api/community/events')),
      ]);
      final statistics = responses[0].statusCode >= 200 && responses[0].statusCode < 300
          ? jsonDecode(responses[0].body) as Map<String, dynamic>
          : <String, dynamic>{};
      final heatmap = responses[1].statusCode >= 200 && responses[1].statusCode < 300
          ? jsonDecode(responses[1].body) as List<dynamic>
          : const <dynamic>[];
      final events = responses[2].statusCode >= 200 && responses[2].statusCode < 300
          ? jsonDecode(responses[2].body) as List<dynamic>
          : const <dynamic>[];
      final signals = heatmap.whereType<Map<String, dynamic>>().map(_CommunitySignal.fromJson).toList();
      final upcomingEvents = events
          .whereType<Map<String, dynamic>>()
          .map(_CommunityEvent.fromJson)
          .where((event) => event.date.isAfter(DateTime.now()))
          .take(4)
          .toList();
      if (!mounted) return;
      setState(() {
        _totalCases = (statistics['total_casos'] as num?)?.toInt() ?? signals.fold(0, (total, signal) => total + signal.cases);
        _validatedReports = signals.length;
        _signals = signals;
        _events = upcomingEvents;
        _loadingCommunity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCommunity = false;
        _communityError = 'No pudimos actualizar el panorama comunitario.';
      });
    }
  }

  void _openMap() {
    if (widget.onOpenMap != null) {
      widget.onOpenMap!();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GisMapScreen()));
  }

  Future<void> _openPpgScreen() async {
    final result = await Navigator.push<VitalMeasurement?>(
      context,
      MaterialPageRoute(builder: (_) => const PpgScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _latestVital = result;
      });
    } else {
      _cargarUltimoSignoVital();
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

  void _showMeasurementOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
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
              const SizedBox(height: 16),
              const Text(
                'Selecciona el método de medición',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige cómo prefieres registrar tu frecuencia cardíaca hoy:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: BiomarkColors.green.withValues(alpha: 0.4), width: 1.5),
                ),
                tileColor: BiomarkColors.green.withValues(alpha: 0.08),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BiomarkColors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sensors_rounded, color: BiomarkColors.green, size: 24),
                ),
                title: const Row(
                  children: [
                    Text(
                      'Sismocardiografía (SCG)',
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(width: 8),
                    Badge(
                      label: Text('Recomendado', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      backgroundColor: BiomarkColors.green,
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Coloca el celular en tu pecho (acostado o sentado). Sin quemar dedos ni depender de flash.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openScgScreen();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                tileColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.red, size: 24),
                ),
                title: const Text(
                  'Fotopletismografía (PPG)',
                  style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Sensor óptico usando la cámara trasera y el flash sobre la yema del dedo.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPpgScreen();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openRecommendationDetails(HealthRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: rec.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(rec.icon, color: rec.accentColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rec.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rec.tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rec.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  rec.details,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Puntos Clave y Recomendaciones:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...rec.keyPoints.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded, color: rec.accentColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (rec.minsaNormative != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 18, color: BiomarkColors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.minsaNormative!,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rec.accentColor,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveContainer(
        maxWidth: 1050,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildGreetingHeader(),
            const SizedBox(height: 16),
            _buildVitalPulseCard(),
            const SizedBox(height: 20),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildRecommendationsSection(),
            const SizedBox(height: 24),
            _buildCommunitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $_nombreUsuario!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                'Tu salud y prevención comunitaria al día',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () {
            _cargarNombreUsuario();
            _cargarUltimoSignoVital();
            _cargarPanoramaComunitario();
          },
          icon: Icon(_loadingCommunity ? Icons.sync_rounded : Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildVitalPulseCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingVitals) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final vital = _latestVital;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFF1F2), const Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vital?.method == 'PPG' ? 'Pulso Cardíaco (PPG Óptico)' : 'Pulso Cardíaco (SCG Pecho)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      vital != null ? 'Último chequeo: ${vital.method} (${vital.statusLabel})' : 'Medición en el pecho con acelerómetro o cámara',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (vital != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (vital.status == 'NORMAL' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vital.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: vital.status == 'NORMAL' ? const Color(0xFF059669) : const Color(0xFFD97706),
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
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(width: 6),
                const Text(
                  'BPM',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '${vital.timestamp.day}/${vital.timestamp.month} ${vital.timestamp.hour.toString().padLeft(2, '0')}:${vital.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              vital.statusLabel,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              'Coloca el celular sobre tu pecho (acostado o sentado) para medir tus pulsaciones mediante micro-vibraciones cardíacas.',
              style: TextStyle(fontSize: 12.5, height: 1.35, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showMeasurementOptionsModal,
              icon: const Icon(Icons.favorite_rounded, size: 20),
              label: Text(
                vital != null ? 'Medir Pulso de Nuevo' : 'Medir Pulso Cardíaco',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final isDesktop = MediaQuery.sizeOf(context).width > 750;

    final tileChat = _buildActionTile(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Consultar IA',
      subtitle: 'Orientación de salud',
      color: BiomarkColors.blue,
      onTap: () => SurveyService.abrirChat(context),
    );

    final tileMejoria = _buildActionTile(
      icon: Icons.trending_up_rounded,
      title: 'Mi Mejoría',
      subtitle: 'Evolución de síntomas',
      color: const Color(0xFF10B981),
      onTap: () {
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(1);
        }
      },
    );

    final tilePulso = _buildActionTile(
      icon: Icons.favorite_rounded,
      title: 'Medir Pulso',
      subtitle: 'SCG Pecho 18s',
      color: const Color(0xFFEF4444),
      onTap: _openScgScreen,
    );

    final tileMinsa = _buildActionTile(
      icon: Icons.local_hospital_outlined,
      title: 'Centros MINSA',
      subtitle: 'Puestos y hospitales',
      color: const Color(0xFF0284C7),
      onTap: _openMap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (isDesktop)
          Row(
            children: [
              Expanded(child: tileChat),
              const SizedBox(width: 12),
              Expanded(child: tileMejoria),
              const SizedBox(width: 12),
              Expanded(child: tilePulso),
              const SizedBox(width: 12),
              Expanded(child: tileMinsa),
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(child: tileChat),
              const SizedBox(width: 12),
              Expanded(child: tileMejoria),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: tilePulso),
              const SizedBox(width: 12),
              Expanded(child: tileMinsa),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.shield_outlined,
          'Recomendaciones de Salud',
          'Pautas de prevención según normativas del MINSA',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return _buildRecommendationCard(rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(HealthRecommendation rec) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openRecommendationDetails(rec),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: rec.accentColor.withValues(alpha: 0.25),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: rec.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(rec.icon, color: rec.accentColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rec.accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rec.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                rec.summary,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver pautas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rec.accentColor,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: rec.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommunitySummary(),
        const SizedBox(height: 20),
        _sectionTitle(
          Icons.campaign_rounded,
          'Señales de la comunidad',
          'Reportes validados y agrupados por zona aproximada',
        ),
        const SizedBox(height: 10),
        if (_communityError != null)
          _buildEmptyState(_communityError!, Icons.cloud_off_rounded)
        else if (_loadingCommunity)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_signals.isEmpty)
          _buildEmptyState('Todavía no hay reportes validados para mostrar.', Icons.verified_outlined)
        else
          ..._signals.take(5).map(_buildSignalCard),
        const SizedBox(height: 20),
        _sectionTitle(
          Icons.event_available_rounded,
          'Próximas jornadas',
          'Actividades comunitarias cercanas',
        ),
        const SizedBox(height: 10),
        if (_events.isEmpty)
          _buildEmptyState('No hay jornadas próximas publicadas.', Icons.event_busy_rounded)
        else
          ..._events.map(_buildEventCard),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Aportar un reporte desde el mapa'),
          style: OutlinedButton.styleFrom(
            foregroundColor: BiomarkColors.green,
            side: const BorderSide(color: BiomarkColors.green),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Las señales mostradas fueron validadas antes de aparecer en este panorama.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCommunitySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BiomarkColors.green.withValues(alpha: .14),
            BiomarkColors.blue.withValues(alpha: .06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BiomarkColors.green.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: BiomarkColors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividad comunitaria',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_validatedReports zonas con reportes validados · $_totalCases casos observados',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BiomarkColors.blue, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(_CommunitySignal signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.verified_rounded, color: BiomarkColors.green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${signal.cases} ${signal.cases == 1 ? 'caso' : 'casos'} reportados en un área comunitaria aproximada.',
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildEventCard(_CommunityEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE8EEF9),
            child: Icon(Icons.event_available_rounded, color: BiomarkColors.blue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.location} · ${_formatEventDate(event.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) =>
      '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _CommunitySignal {
  final int cases;

  const _CommunitySignal({required this.cases});

  factory _CommunitySignal.fromJson(Map<String, dynamic> json) => _CommunitySignal(
        cases: (json['cantidad_casos'] as num?)?.toInt() ?? 0,
      );
}

class _CommunityEvent {
  final String title;
  final String location;
  final DateTime date;

  const _CommunityEvent({required this.title, required this.location, required this.date});

  factory _CommunityEvent.fromJson(Map<String, dynamic> json) => _CommunityEvent(
        title: '${json['titulo'] ?? 'Jornada comunitaria'}',
        location: '${json['ubicacion'] ?? 'Ubicación por confirmar'}',
        date: DateTime.tryParse('${json['fecha_evento'] ?? ''}') ?? DateTime.now(),
      );
}
