import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:latlong2/latlong.dart';

import '../../../biomark_brand.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/profile/user_profile_api.dart';
import '../../vitals/domain/vital_measurement.dart';
import '../../vitals/data/vitals_storage.dart';
import '../../vitals/presentation/scg_screen.dart';
import '../../../core/design/biomark_glass_surface.dart';
import '../../../core/design/responsive_layout.dart';
import '../../profile/presentation/notifications_inbox_screen.dart';
import '../../../survey_service.dart';
import '../data/health_content_api.dart';
import '../domain/health_content_item.dart';
import '../../gis/data/gis_api.dart';
import '../../gis/domain/health_center.dart';

typedef GisMapNavigator = void Function({
  LatLng? location,
  bool focusRisk,
  bool focusEvents,
  String? highlightTitle,
});

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenMap,
    this.onNavigateToTab,
    this.onOpenMapWithOptions,
  });

  final VoidCallback? onOpenMap;
  final ValueChanged<int>? onNavigateToTab;
  final GisMapNavigator? onOpenMapWithOptions;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = 'usuario';
  VitalMeasurement? _latestVital;
  bool _loadingVitals = true;
  bool _mostrarBannerVoz = true;

  // Condiciones de salud del paciente (del SurveyService / historial médico)
  List<String> _userConditions = const [];

  // Contenido de Salud Oficial MINSA segmentado
  List<HealthContentItem> _healthArticles = const [];
  bool _loadingContent = true;
  String _selectedSegmentFilter = 'Todos';

  // Capas GIS dinámicas (Jornadas, Brotes y Reportes de vigilancia comunitaria)
  final _gisApi = GisApi();
  List<CommunityEvent> _communityEvents = const [];
  List<RiskZone> _riskZones = const [];
  List<CommunityReportPoint> _communityReports = const [];

  @override
  void initState() {
    super.initState();
    final cached = AuthSession.instance.userName;
    if (cached != null && cached.trim().isNotEmpty) {
      _nombreUsuario = cached.trim().split(' ').first;
    }
    _cargarCondicionesUsuario();
    _cargarNombreUsuario();
    _cargarUltimoSignoVital();
    _cargarPreferenciaBannerVoz();
    _cargarContenidoSalud();
    _cargarCapasGis();
  }

  @override
  void dispose() {
    _gisApi.dispose();
    super.dispose();
  }

  void _cargarCondicionesUsuario() {
    final list = SurveyService.respuestas['enfermedadesCronicas'];
    if (list is List) {
      _userConditions = list.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
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

  Future<void> _cargarContenidoSalud() async {
    if (!mounted) return;
    setState(() => _loadingContent = true);
    try {
      String? condParam;
      if (_selectedSegmentFilter == 'Para mis condiciones' && _userConditions.isNotEmpty) {
        condParam = _userConditions.first;
      }
      final items = await HealthContentApi.fetchContent(condicion: condParam);
      if (!mounted) return;

      List<HealthContentItem> filtrados = items;
      if (_selectedSegmentFilter == 'Para mis condiciones' && _userConditions.isNotEmpty) {
        filtrados = items.where((item) {
          final target = item.condicionesObjetivo.map((c) => c.toLowerCase()).toList();
          return _userConditions.any((uc) =>
              target.any((t) => t.contains(uc.toLowerCase()) || uc.toLowerCase().contains(t)) ||
              item.titulo.toLowerCase().contains(uc.toLowerCase()) ||
              item.descripcion.toLowerCase().contains(uc.toLowerCase()));
        }).toList();
        if (filtrados.isEmpty) filtrados = items; // Respaldo seguro
      } else if (_selectedSegmentFilter == 'Normativas MINSA') {
        filtrados = items.where((item) => item.tipoAviso == 'NORMATIVA' || item.normativaCodigo != null).toList();
        if (filtrados.isEmpty) filtrados = items;
      } else if (_selectedSegmentFilter == 'Alertas Sanitarias') {
        filtrados = items.where((item) => item.tipoAviso == 'ALERTA_EPIDEMIOLOGICA').toList();
        if (filtrados.isEmpty) filtrados = items;
      }

      setState(() {
        _healthArticles = filtrados;
        _loadingContent = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Future<void> _cargarCapasGis() async {
    try {
      final layers = await _gisApi.fetchLayers(
        latitude: 12.1364,
        longitude: -86.2514,
      );
      List<CommunityReportPoint> reports = const [];
      try {
        reports = await _gisApi.fetchValidatedReports();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _communityEvents = layers.events;
        _riskZones = layers.riskZones;
        _communityReports = reports;
      });
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ResponsiveContainer(
        maxWidth: 960,
        child: RefreshIndicator(
          onRefresh: () async {
            _cargarCondicionesUsuario();
            await Future.wait([
              _cargarNombreUsuario(),
              _cargarUltimoSignoVital(),
              _cargarContenidoSalud(),
              _cargarCapasGis(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              // ==========================================
              // SECCIÓN 1: BIENVENIDA Y SIGNOS VITALES
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
              // SECCIÓN 2: AVISOS Y NORMATIVAS OFICIALES MINSA
              // ==========================================
              _buildOfficialAnnouncementsSection().animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 28),

              // ==========================================
              // SECCIÓN 3: JORNADAS DE SALUD EN BARRIOS CERCANOS
              // ==========================================
              _buildCommunityJornadasSection().animate().fadeIn(duration: 550.ms),

              const SizedBox(height: 28),

              // ==========================================
              // SECCIÓN 4: ALERTAS Y REPORTES COMUNITARIOS
              // ==========================================
              _buildNeighborhoodOutbreaksSection().animate().fadeIn(duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 1: CABECERA Y MONITOR DE LATIDOS / PULSO
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monitor de Ritmo Cardíaco',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sismocardiografía (SCG Pecho)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (vital != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNormal
                        ? const Color(0xFF10B981).withValues(alpha: 0.14)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNormal ? Icons.check_circle_rounded : Icons.warning_rounded,
                        size: 13,
                        color: isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vital.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (vital != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${vital.bpm}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Color(0xFFEF4444),
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
                const SizedBox(width: 8),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${vital.timestamp.day}/${vital.timestamp.month} · ${vital.timestamp.hour.toString().padLeft(2, '0')}:${vital.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  // SECCIÓN 2: AVISOS Y NORMATIVAS MINSA SEGMENTADAS POR PATOLOGÍA
  // =========================================================================

  Widget _buildOfficialAnnouncementsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterOptions = [
      'Todos',
      if (_userConditions.isNotEmpty) 'Para mis condiciones',
      'Normativas MINSA',
      'Alertas Sanitarias',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, size: 20, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Avisos y Normativas Oficiales MINSA',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _userConditions.isNotEmpty
              ? 'Segmentado según tu historial de salud: ${_userConditions.join(", ")}'
              : 'Protocolos de atención, normativas clínicas y vigilancia del SILAIS Managua',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Filtros rápidos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filterOptions.map((f) {
              final isSelected = _selectedSegmentFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedSegmentFilter = f);
                      _cargarContenidoSalud();
                    }
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
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
                    'No hay avisos específicos con este filtro por el momento.',
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
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _healthArticles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return _buildOfficialNoticeCard(_healthArticles[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOfficialNoticeCard(HealthContentItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAlert = item.tipoAviso == 'ALERTA_EPIDEMIOLOGICA';

    return Semantics(
      label: 'Aviso oficial: ${item.titulo}. Fuente: ${item.fuente}',
      button: true,
      child: InkWell(
        onTap: () => _openArticleModal(item),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 275,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                  .withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAlert ? Icons.warning_amber_rounded : Icons.verified_rounded,
                          size: 13,
                          color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.fuente,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (item.normativaCodigo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.normativaCodigo!.split(' - ').first,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
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
              const SizedBox(height: 5),
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
              const SizedBox(height: 6),
              if (item.condicionesObjetivo.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: item.condicionesObjetivo.take(2).map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$c',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Managua',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Leer pautas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
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

  // =========================================================================
  // SECCIÓN 3: JORNADAS DE SALUD EN BARRIOS CERCANOS (CON ENLACE AL MAPA)
  // =========================================================================

  Widget _buildCommunityJornadasSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final jornadas = _communityEvents.isNotEmpty
        ? _communityEvents
        : [
            CommunityEvent(
              id: 'ev-seed-01',
              title: 'Clínica Móvil y Atención Médica Integral',
              description: 'Consultas de medicina general, odontología, ultrasonidos y entrega gratuita de medicamentos esenciales.',
              date: DateTime.now().add(const Duration(days: 1)),
              location: 'Barrio San Judas (Cancha Comunal Central)',
              latitude: 12.1185,
              longitude: -86.2890,
              distanceKm: 1.5,
            ),
            CommunityEvent(
              id: 'ev-seed-02',
              title: 'Jornada Nacional de Vacunación Esquema 2026',
              description: 'Inmunización contra neumococo, influenza, sarampión y refuerzos para niños y adultos mayores.',
              date: DateTime.now().add(const Duration(days: 2)),
              location: 'Barrio Altagracia (Centro de Salud)',
              latitude: 12.1382,
              longitude: -86.2815,
              distanceKm: 0.8,
            ),
            CommunityEvent(
              id: 'ev-seed-03',
              title: 'Jornada de Abatización y Fumigación BTI',
              description: 'Brigadas epidemiológicas del SILAIS Managua para control de larvas y eliminación de criaderos del mosquito transmisor.',
              date: DateTime.now().add(const Duration(days: 3)),
              location: 'Barrio Batahola Sur (Sector Los Robles)',
              latitude: 12.1465,
              longitude: -86.2940,
              distanceKm: 2.1,
            ),
            CommunityEvent(
              id: 'ev-seed-04',
              title: 'Feria de Medicina Natural y Salud Integral',
              description: 'Atención con fitoterapia, terapias complementarias, toma de presión arterial y pruebas de glucosa.',
              date: DateTime.now().add(const Duration(days: 4)),
              location: 'Barrio Camilo Ortega (Parque Comunal)',
              latitude: 12.1090,
              longitude: -86.2990,
              distanceKm: 3.0,
            ),
          ];

    Color getEventColor(String title) {
      final t = title.toLowerCase();
      if (t.contains('vacun')) return const Color(0xFF10B981);
      if (t.contains('fumig') || t.contains('abatiz')) return const Color(0xFF0284C7);
      if (t.contains('natural') || t.contains('feria')) return const Color(0xFF8B5CF6);
      return const Color(0xFF0D9488);
    }

    IconData getEventIcon(String title) {
      final t = title.toLowerCase();
      if (t.contains('vacun')) return Icons.vaccines_rounded;
      if (t.contains('fumig') || t.contains('abatiz')) return Icons.sanitizer_rounded;
      if (t.contains('natural') || t.contains('feria')) return Icons.eco_rounded;
      return Icons.local_hospital_rounded;
    }

    String getEventCategory(String title) {
      final t = title.toLowerCase();
      if (t.contains('vacun')) return 'VACUNACIÓN';
      if (t.contains('fumig') || t.contains('abatiz')) return 'CONTROL VECTORIAL';
      if (t.contains('natural') || t.contains('feria')) return 'MEDICINA NATURAL';
      return 'CLÍNICA MÓVIL';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, size: 20, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jornadas en Barrios Cercanos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                if (widget.onOpenMapWithOptions != null) {
                  widget.onOpenMapWithOptions!(focusEvents: true);
                } else if (widget.onOpenMap != null) {
                  widget.onOpenMap!();
                }
              },
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('Ver Mapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Atención médica gratuita, ferias de salud y clínicas móviles del MINSA en Managua',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: jornadas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final j = jornadas[index];
              final color = getEventColor(j.title);
              final icon = getEventIcon(j.title);
              final category = getEventCategory(j.title);

              return Container(
                width: 285,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.22),
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
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      j.location,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${j.date.day}/${j.date.month}/${j.date.year} · Atención en jornada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        j.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.onOpenMapWithOptions != null) {
                            widget.onOpenMapWithOptions!(
                              location: LatLng(j.latitude, j.longitude),
                              focusEvents: true,
                              highlightTitle: j.title,
                            );
                          } else if (widget.onOpenMap != null) {
                            widget.onOpenMap!();
                          }
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 14),
                        label: const Text('Ubicar en Mapa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SECCIÓN 4: ALERTAS Y REPORTES COMUNITARIOS DE EPIDEMIAS EN MANAGUA
  // =========================================================================

  Widget _buildNeighborhoodOutbreaksSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final brotes = <_OutbreakItem>[];

    for (final z in _riskZones) {
      final isHigh = z.name.toLowerCase().contains('dengue') || z.name.toLowerCase().contains('alerta');
      brotes.add(
        _OutbreakItem(
          alerta: z.name.toUpperCase(),
          distrito: 'Distrito de Cobertura Sanitaria (Radio ${z.radiusKm.toStringAsFixed(1)} km)',
          nivel: isHigh ? 'Alerta Amarilla Barrial' : 'Vigilancia Preventiva',
          casos: 'Monitoreo activo de casos en el sector por brigadas SILAIS',
          recomendacion: 'Elimine recipientes con agua estancada. Acuda al centro de salud si presenta fiebre repentina.',
          color: isHigh ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          latitude: z.latitude,
          longitude: z.longitude,
          title: z.name,
        ),
      );
    }

    for (final r in _communityReports) {
      brotes.add(
        _OutbreakItem(
          alerta: 'REPORTE COMUNITARIO DE SALUD',
          distrito: 'Managua (Punto Georreferenciado)',
          nivel: '${r.caseCount} ${r.caseCount == 1 ? 'Caso Sospechoso' : 'Casos Sospechosos'}',
          casos: r.description.isNotEmpty ? r.description : 'Reporte validado de síntomas en la comunidad',
          recomendacion: 'Refuerce medidas higiénicas y consulte de inmediato ante signos de alarma.',
          color: const Color(0xFFEF4444),
          latitude: r.latitude,
          longitude: r.longitude,
          title: 'Reporte Comunitario',
        ),
      );
    }

    if (brotes.isEmpty) {
      brotes.addAll([
        const _OutbreakItem(
          alerta: 'VIGILANCIA DE DENGUE ACTIVA',
          distrito: 'Distrito III: San Judas, Altagracia y Camilo Ortega',
          nivel: 'Alerta Amarilla Barrial',
          casos: 'Incremento de casos sospechosos en la última semana',
          recomendacion: 'Elimine recipientes con agua estancada. Acuda al puesto de salud si presenta fiebre repentina.',
          color: Color(0xFFF59E0B),
          latitude: 12.1220,
          longitude: -86.2880,
          title: 'Vigilancia Activa de Dengue',
        ),
        const _OutbreakItem(
          alerta: 'VIGILANCIA RESPIRATORIA ESTACIONAL',
          distrito: 'Distrito II: Batahola Sur y Linda Vista',
          nivel: 'Vigilancia Preventiva',
          casos: 'Circulación de virus respiratorios en menores de 5 años',
          recomendacion: 'Vigile dificultad para respirar y tos persistente. Mantenga hidratación y lavado de manos.',
          color: Color(0xFF3B82F6),
          latitude: 12.1450,
          longitude: -86.2920,
          title: 'Vigilancia Respiratoria Estacional',
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety_rounded, size: 20, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alertas y Reportes Comunitarios',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                if (widget.onOpenMapWithOptions != null) {
                  widget.onOpenMapWithOptions!(focusRisk: true);
                } else if (widget.onOpenMap != null) {
                  widget.onOpenMap!();
                }
              },
              icon: const Icon(Icons.travel_explore_rounded, size: 16),
              label: const Text('Ver Brotes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Monitoreo epidemiológico territorial y reporte de casos en barrios de Managua',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        ...brotes.map((b) {
          final color = b.color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.22),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.alerta,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        b.nivel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  b.distrito,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  b.casos,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  b.recomendacion,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (widget.onOpenMapWithOptions != null) {
                          widget.onOpenMapWithOptions!(
                            location: LatLng(b.latitude, b.longitude),
                            focusRisk: true,
                            highlightTitle: b.title,
                          );
                        } else if (widget.onOpenMap != null) {
                          widget.onOpenMap!();
                        }
                      },
                      icon: const Icon(Icons.map_rounded, size: 14),
                      label: const Text('Ver Mapa de Vigilancia', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _openArticleModal(HealthContentItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAlert = item.tipoAviso == 'ALERTA_EPIDEMIOLOGICA';

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
                            color: (isAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAlert ? Icons.warning_amber_rounded : Icons.verified_rounded,
                                size: 15,
                                color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item.fuente,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
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
                    if (item.normativaCodigo != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.normativaCodigo!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
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
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 20, color: Color(0xFF10B981)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Información y protocolos oficiales avalados por el Ministerio de Salud (MINSA).',
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
                          backgroundColor: isAlert ? const Color(0xFFDC2626) : const Color(0xFF059669),
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

class _OutbreakItem {
  final String alerta;
  final String distrito;
  final String nivel;
  final String casos;
  final String recomendacion;
  final Color color;
  final double latitude;
  final double longitude;
  final String title;

  const _OutbreakItem({
    required this.alerta,
    required this.distrito,
    required this.nivel,
    required this.casos,
    required this.recomendacion,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.title,
  });
}
