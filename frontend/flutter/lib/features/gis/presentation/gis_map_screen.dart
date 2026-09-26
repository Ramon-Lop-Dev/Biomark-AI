import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../biomark_brand.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/biomark_glass_surface.dart';
import '../data/gis_api.dart';
import '../domain/health_center.dart';
import 'community_report_screen.dart';

class GisMapScreen extends StatefulWidget {
  const GisMapScreen({
    super.key,
    this.initialCenter,
    this.initialLocation,
    this.focusRiskZones = false,
    this.focusEvents = false,
    this.highlightTitle,
  });

  final HealthCenter? initialCenter;
  final LatLng? initialLocation;
  final bool focusRiskZones;
  final bool focusEvents;
  final String? highlightTitle;

  @override
  State<GisMapScreen> createState() => _GisMapScreenState();
}

class _GisMapScreenState extends State<GisMapScreen>
    with SingleTickerProviderStateMixin {
  static const _managua = LatLng(12.1364, -86.2514);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _gisApi = GisApi();
  Timer? _viewportTimer;
  late final AnimationController _pulseController;

  List<HealthCenter> _centers = const [];
  LatLng _mapCenter = _managua;
  double _zoom = 15.5;
  bool _loading = true;
  bool _locating = false;
  String? _error;
  HealthCenter? _selected;
  List<RiskZone> _riskZones = const [];
  List<CommunityEvent> _events = const [];
  List<CommunityReportPoint> _reports = const [];
  LatLng? _userLocation;
  bool _showEvents = true;
  bool _showRisk = true; // Activo por defecto para que las geocercas rojas sean visibles
  bool _showReports = true;
  bool _layersLoaded = false;
  bool _layersLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    if (widget.initialLocation != null) {
      _mapCenter = widget.initialLocation!;
      _zoom = 16.0;
    } else if (widget.initialCenter != null) {
      _mapCenter = LatLng(
        widget.initialCenter!.latitude,
        widget.initialCenter!.longitude,
      );
      _zoom = 16.0;
    }

    if (widget.focusRiskZones) {
      _showRisk = true;
      _showReports = true;
    }
    if (widget.focusEvents) {
      _showEvents = true;
    }

    // Cargar inmediatamente los centros de Managua para que el mapa nunca aparezca desierto
    _loadViewport();
    _loadLayersOnce();

    if (widget.initialCenter == null && widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(_mapCenter, 16.5);
        if (widget.highlightTitle != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación: ${widget.highlightTitle!}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0284C7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadViewport([LatLngBounds? bounds, bool forceRefresh = false]) async {
    final visible = bounds ?? _boundsAround(_mapCenter, _zoom);
    if (mounted) setState(() => _loading = true);
    try {
      final data = await _gisApi.fetchViewport(
        minLon: visible.west,
        minLat: visible.south,
        maxLon: visible.east,
        maxLat: visible.north,
        zoom: _zoom,
        forceRefresh: forceRefresh,
      );
      List<HealthCenter> loaded = data.centers;
      if (loaded.isEmpty && _centers.isEmpty) {
        try {
          final nearby = await _gisApi.fetchNearby(
            latitude: _mapCenter.latitude,
            longitude: _mapCenter.longitude,
            radiusKm: 50,
          );
          loaded = nearby.centers;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        final centersMap = <String, HealthCenter>{
          for (final c in _centers) c.id: c,
          for (final c in loaded) c.id: c,
        };
        _centers = centersMap.values.toList();
        _loading = false;
      });
    } on GisApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.statusCode == 429
            ? 'Demasiadas peticiones. Espera un momento antes de volver a consultar.'
            : 'No se pudieron cargar los centros. Revisa tu conexión.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los centros. Revisa tu conexión.';
      });
    }
  }

  Future<void> _loadLayersOnce({bool forceRefresh = false}) async {
    if ((_layersLoaded && !forceRefresh) || _layersLoading) return;
    _layersLoading = true;
    try {
      final layers = await _gisApi.fetchLayers(
        latitude: _mapCenter.latitude,
        longitude: _mapCenter.longitude,
        forceRefresh: forceRefresh,
      );
      List<CommunityReportPoint> reports = const [];
      try {
        reports = await _gisApi.fetchValidatedReports(forceRefresh: forceRefresh);
      } on GisApiException catch (error) {
        if (mounted) {
          setState(
            () => _error = error.statusCode == 401 || error.statusCode == 403
                ? 'Inicia sesión para ver los reportes comunitarios.'
                : error.statusCode == 429
                ? 'Demasiadas peticiones. Espera un momento.'
                : 'No se pudieron cargar los reportes comunitarios.',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _riskZones = layers.riskZones;
        _events = layers.events;
        _reports = reports;
        _layersLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudieron cargar las capas comunitarias.',
        );
      }
    } finally {
      _layersLoading = false;
    }
  }

  LatLngBounds _boundsAround(LatLng center, double zoom) {
    final span = (18 / zoom).clamp(0.04, 2.0).toDouble();
    return LatLngBounds(
      LatLng(center.latitude - span, center.longitude - span),
      LatLng(center.latitude + span, center.longitude + span),
    );
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveEnd && event is! MapEventFlingAnimationEnd) {
      return;
    }
    final newCenter = event.camera.center;
    final newZoom = event.camera.zoom;

    final distanceMoved = const Distance().as(LengthUnit.Meter, _mapCenter, newCenter);
    final zoomChanged = (newZoom - _zoom).abs() > 0.4;

    _mapCenter = newCenter;
    _zoom = newZoom;

    // Si el movimiento es muy leve (< 120m) y el zoom no cambió sustancialmente, no disparar petición
    if (distanceMoved < 120 && !zoomChanged) {
      return;
    }

    _viewportTimer?.cancel();
    _viewportTimer = Timer(const Duration(milliseconds: 250), () {
      _loadViewport(event.camera.visibleBounds);
    });
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const PermissionDeniedException('Ubicación denegada');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final realGpsLocation = LatLng(position.latitude, position.longitude);
      final distToManaguaKm = const Distance().as(
        LengthUnit.Kilometer,
        realGpsLocation,
        _managua,
      );

      // Si el usuario está probando fuera de Managua (ej. Corinto a 115 km),
      // guardamos su GPS real para distancias y marcador, pero enfocamos la cámara
      // en Managua para que vea y navegue inmediatamente todos los centros hospitalarios.
      final cameraTarget = distToManaguaKm <= 35 ? realGpsLocation : _managua;

      if (mounted) {
        setState(() {
          _userLocation = realGpsLocation;
          _mapCenter = cameraTarget;
          _zoom = 14.5;
        });
      }
      _mapController.move(cameraTarget, 14.5);
      unawaited(_loadViewport(_boundsAround(cameraTarget, 14.5)));
      unawaited(_loadLayersOnce());
    } catch (_) {
      _mapController.move(_managua, 14.5);
      if (mounted) {
        setState(() {
          _mapCenter = _managua;
          _zoom = 14.5;
        });
      }
      unawaited(_loadViewport(_boundsAround(_managua, 14.5)));
      unawaited(_loadLayersOnce());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  int _filtroTipoIndex = 0; // 0: Todos, 1: Hospitales, 2: Centros de Salud, 3: Puestos Médicos

  double _distanciaMetros(HealthCenter c) {
    if (_userLocation == null) return c.distanceKm * 1000;
    return const Distance().as(
      LengthUnit.Meter,
      _userLocation!,
      LatLng(c.latitude, c.longitude),
    );
  }

  List<HealthCenter> get _visibleCenters {
    final query = _searchController.text.trim().toLowerCase();
    var list = _centers;

    if (query.isNotEmpty) {
      list = list
          .where((center) =>
              center.name.toLowerCase().contains(query) ||
              center.address.toLowerCase().contains(query))
          .toList();
    }

    if (_filtroTipoIndex == 1) {
      list = list.where((c) => c.level == 3 || c.name.toLowerCase().contains('hospital')).toList();
    } else if (_filtroTipoIndex == 2) {
      list = list.where((c) => c.level == 2 || c.name.toLowerCase().contains('centro')).toList();
    } else if (_filtroTipoIndex == 3) {
      list = list.where((c) => c.level == 1 || c.name.toLowerCase().contains('puesto')).toList();
    }

    if (_userLocation != null) {
      list = List.of(list)..sort((a, b) => _distanciaMetros(a).compareTo(_distanciaMetros(b)));
    }

    return list;
  }

  void _selectCenter(HealthCenter center) {
    setState(() => _selected = center);
    _mapController.move(LatLng(center.latitude, center.longitude), 16.0);
  }

  Future<void> _openDirections(HealthCenter center) async {
    final tieneDireccion =
        center.address.trim().isNotEmpty &&
        center.address != 'Dirección no disponible';
    final consulta = tieneDireccion
        ? '${center.name}, ${center.address}'
        : '${center.name}, Nicaragua';

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(consulta)}'
      '&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      setState(() => _error = 'No se pudo abrir la aplicación de mapas.');
    }
  }

  Future<void> _createReport() async {
    await showCommunityReportSheet(
      context,
      _gisApi,
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      onReportSent: () {
        _loadLayersOnce(forceRefresh: true);
      },
    );
  }

  Future<void> _openDetails(HealthCenter center) async {
    try {
      final details = await _gisApi.fetchCenterDetails(center.id);
      if (mounted) setState(() => _selected = details);
    } catch (_) {
      if (mounted) setState(() => _selected = center);
    }
  }

  void _showEventDetails(CommunityEvent event) {
    final visual = _getEventVisual(event);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(visual.icon, size: 16, color: visual.color),
                          const SizedBox(width: 6),
                          Text(
                            visual.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: visual.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Horario / Fecha: ${event.date.day}/${event.date.month}/${event.date.year} (Jornada oficial MINSA)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(ctx).dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'De qué se trata:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'Atención médica y preventiva gratuita organizada por brigadas del MINSA. Acuda con su cédula o tarjeta de salud.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (event.type.toLowerCase().contains('fumig') ||
                    event.type.toLowerCase().contains('abatiz') ||
                    event.title.toLowerCase().contains('fumig') ||
                    event.title.toLowerCase().contains('abatiz') ||
                    visual.category.toLowerCase().contains('fumig')) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: visual.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: visual.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home_work_rounded, color: visual.color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Atención casa a casa: Las brigadas del MINSA visitan las viviendas de este sector. Permita el ingreso para fumigación y aplicación de BTI.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _mapController.move(LatLng(event.latitude, event.longitude), 17.0);
                      },
                      icon: const Icon(Icons.filter_center_focus_rounded, size: 18),
                      label: const Text('Ver Sector en Mapa', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: visual.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _mapController.move(LatLng(event.latitude, event.longitude), 17.0);
                          },
                          icon: const Icon(Icons.filter_center_focus_rounded, size: 18),
                          label: const Text('Centrar'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${event.latitude},${event.longitude}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Cómo Llegar', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: visual.color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRiskZoneDetails(RiskZone zone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 16, color: Color(0xFFEF4444)),
                          SizedBox(width: 6),
                          Text(
                            'ZONA DE VIGILANCIA MINSA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Radio epidemiológico de cobertura: ${zone.radiusKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medidas Preventivas Oficiales (MINSA):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Elimine recipientes con agua estancada y lave pilas/barriles con cloro o cepillo.\n• Permita el ingreso de los brigadistas de salud para la aplicación de BTI o fumigación.\n• Si presenta fiebre repentina, dolor en el cuerpo o sarpullido, acuda de inmediato a su centro de salud.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController.move(LatLng(zone.latitude, zone.longitude), 15.5);
                    },
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                    label: const Text('Centrar en Zona de Vigilancia'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(CommunityReportPoint report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                          SizedBox(width: 6),
                          Text(
                            'ALERTA COMUNITARIA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${report.caseCount} ${report.caseCount == 1 ? 'Caso Sospechoso Reportado' : 'Casos Sospechosos Reportados'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  report.description.isNotEmpty
                      ? report.description
                      : 'Zona bajo vigilancia comunitaria por reporte de cuadros febriles o respiratorios en el vecindario.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendaciones del MINSA:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Elimine recipientes con agua estancada y mantenga depósitos bien tapados.\n• Si presenta síntomas de alarma acuda al centro de salud más cercano. No se automedique.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController.move(LatLng(report.latitude, report.longitude), 17.0);
                    },
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                    label: const Text('Centrar en el Punto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
    final centers = _visibleCenters;

    // FlutterMap optimiza el culling nativamente; no recortamos la lista para que
    // los centros aparezcan de forma fluida y progresiva conforme el usuario recorre el mapa.
    final markers = centers
        .map(
          (center) => Marker(
            point: LatLng(center.latitude, center.longitude),
            width: 52,
            height: 52,
            child: _AnimatedHealthCenterMarker(
              key: ValueKey('center_marker_${center.id}'),
              center: center,
              selected: _selected?.id == center.id,
              onTap: () {
                _selectCenter(center);
                _openDetails(center);
              },
            ),
          ),
        )
        .toList();
    final layerMarkers = <Marker>[
      if (_userLocation != null)
        Marker(
          point: _userLocation!,
          width: 140,
          height: 96,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: _UserLocationMarker(pulseAnimation: _pulseController),
          ),
        ),
      if (_showEvents)
        ..._events.map(
          (event) => Marker(
            point: LatLng(event.latitude, event.longitude),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showEventDetails(event),
              child: _CommunityEventMarker(event: event),
            ),
          ),
        ),
      if (_showRisk)
        ..._riskZones.map(
          (zone) => Marker(
            point: LatLng(zone.latitude, zone.longitude),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showRiskZoneDetails(zone),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      if (_showReports)
        ..._reports.map(
          (report) => Marker(
            point: LatLng(report.latitude, report.longitude),
            width: 180,
            height: 56,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _showReportDetails(report),
              child: _CommunityReportMarker(
                report: report,
                pulseAnimation: _pulseController,
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _zoom,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.cartoApiKey.isNotEmpty
                    ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${AppConfig.cartoApiKey}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: AppConfig.cartoApiKey.isNotEmpty
                    ? const ['a', 'b', 'c', 'd']
                    : const [],
                userAgentPackageName: 'com.biomark.ai',
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),
              if (_showEvents && _events.isNotEmpty)
                CircleLayer(
                  circles: _events
                      .map(
                        (event) => CircleMarker(
                          point: LatLng(event.latitude, event.longitude),
                          radius: 260,
                          useRadiusInMeter: true,
                          color: const Color(0x220284C7),
                          borderColor: const Color(0x880284C7),
                          borderStrokeWidth: 1.5,
                        ),
                      )
                      .toList(),
                ),
              if (_showReports && _reports.isNotEmpty)
                CircleLayer(
                  circles: _reports
                      .map(
                        (report) => CircleMarker(
                          point: LatLng(report.latitude, report.longitude),
                          radius: 350,
                          useRadiusInMeter: true,
                          color: const Color(0x33EF4444),
                          borderColor: const Color(0xFFEF4444),
                          borderStrokeWidth: 2,
                        ),
                      )
                      .toList(),
                ),
              if (_showRisk)
                CircleLayer(
                  circles: _riskZones
                      .map(
                        (zone) => CircleMarker(
                          point: LatLng(zone.latitude, zone.longitude),
                          radius: (zone.radiusKm * 1000).clamp(400, 3000),
                          useRadiusInMeter: true,
                          color: const Color(0x33EF4444),
                          borderColor: const Color(0xFFEF4444),
                          borderStrokeWidth: 2.2,
                        ),
                      )
                      .toList(),
                ),
              MarkerLayer(markers: markers),
              MarkerLayer(markers: layerMarkers),
              SimpleAttributionWidget(
                source: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                alignment: Alignment.bottomLeft,
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BiomarkGlassSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Buscar hospital o centro...',
                              prefixIcon: Icon(Icons.search_rounded),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        icon: Icons.location_city_rounded,
                        tooltip: 'Centrar en Managua',
                        onTap: () {
                          _mapController.move(_managua, 14.5);
                          setState(() {
                            _mapCenter = _managua;
                            _zoom = 14.5;
                          });
                          _loadViewport(_boundsAround(_managua, 14.5), true);
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        icon: _locating
                            ? Icons.sync_rounded
                            : Icons.my_location_rounded,
                        tooltip: 'Mi ubicación GPS',
                        onTap: _locate,
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        icon: Icons.layers_outlined,
                        tooltip: 'Capas y reportes',
                        onTap: _showLayerMenu,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', 0),
                        const SizedBox(width: 6),
                        _buildFilterChip('Hospitales', 1),
                        const SizedBox(width: 6),
                        _buildFilterChip('Centros de Salud', 2),
                        const SizedBox(width: 6),
                        _buildFilterChip('Puestos Médicos', 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.white.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_error!, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Positioned(
            right: 16,
            bottom: _selected != null ? 310 : 24,
            child: _RoundControl(
              icon: Icons.add_location_alt_outlined,
              tooltip: 'Agregar reporte',
              onTap: _createReport,
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                offset: Offset.zero,
                child: _SelectedCenterCard(
                  center: _selected!,
                  userLocation: _userLocation,
                  onClose: () => setState(() => _selected = null),
                  onDirections: _openDirections,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _filtroTipoIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _filtroTipoIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? BiomarkColors.blue
              : (isDark ? Colors.black45 : Colors.white.withValues(alpha: 0.88)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? BiomarkColors.blue
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  void _showLayerMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Capas del mapa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              SwitchListTile(
                title: const Text('Jornadas comunitarias'),
                value: _showEvents,
                onChanged: (value) {
                  setState(() => _showEvents = value);
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Zonas de riesgo'),
                value: _showRisk,
                onChanged: (value) {
                  setState(() => _showRisk = value);
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Reportes comunitarios'),
                value: _showReports,
                onChanged: (value) {
                  setState(() => _showReports = value);
                  setSheetState(() {});
                },
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _createReport();
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Agregar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _viewportTimer?.cancel();
    _searchController.dispose();
    _gisApi.dispose();
    super.dispose();
  }
}

class _AnimatedHealthCenterMarker extends StatelessWidget {
  final HealthCenter center;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedHealthCenterMarker({
    super.key,
    required this.center,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('marker_anim_${center.id}'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.6 + (value * 0.4),
            child: child,
          ),
        );
      },
      child: Semantics(
        label: center.name,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: _HealthCenterMarker(
              center: center,
              selected: selected,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCenterCard extends StatelessWidget {
  const _SelectedCenterCard({
    required this.center,
    this.userLocation,
    required this.onClose,
    required this.onDirections,
  });

  final HealthCenter center;
  final LatLng? userLocation;
  final VoidCallback onClose;
  final ValueChanged<HealthCenter> onDirections;

  String _formatDist() {
    if (userLocation != null) {
      final meters = const Distance().as(
        LengthUnit.Meter,
        userLocation!,
        LatLng(center.latitude, center.longitude),
      );
      if (meters < 1000) {
        return '${meters.round()} m';
      } else {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
    }
    if (center.distanceKm > 0) {
      return center.distanceKm < 1
          ? '${(center.distanceKm * 1000).round()} m'
          : '${center.distanceKm.toStringAsFixed(1)} km';
    }
    return '';
  }

  List<String> _getSpecialties() {
    if (center.specialties.isNotEmpty) {
      return center.specialties;
    }
    if (center.level == 3 || center.type.toUpperCase().contains('HOSPITAL')) {
      return const [
        'Emergencias 24h',
        'Medicina Interna',
        'Cirugía General',
        'Pediatría',
        'Ginecología y Obstetricia',
        'Laboratorio Clínico',
      ];
    }
    if (center.level == 2 || center.type.toUpperCase().contains('CENTRO')) {
      return const [
        'Consulta Externa',
        'Medicina General',
        'Vacunación',
        'Control Prenatal',
        'Odontología',
        'Urgencias Menores',
      ];
    }
    return const [
      'Atención Primaria',
      'Vacunación',
      'Curaciones',
      'Monitoreo de Presión y Glucosa',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHospital =
        center.level == 3 || center.type.toUpperCase().contains('HOSPITAL');
    final iconColor = isHospital ? const Color(0xFFC62828) : BiomarkColors.green;
    final distStr = _formatDist();
    final specialties = _getSpecialties();

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Ícono, Nombre, Nivel/Distancia y botón de Cerrar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: iconColor, width: 1.6),
                    ),
                    child: Icon(
                      isHospital
                          ? Icons.local_hospital_rounded
                          : Icons.health_and_safety_rounded,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _levelLabel(center.level),
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (distStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.near_me_rounded,
                                size: 13,
                                color: BiomarkColors.blue,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                distStr,
                                style: const TextStyle(
                                  color: BiomarkColors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dirección
              if (center.address.isNotEmpty && center.address != 'Dirección no disponible')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          center.address,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Sección "Qué atiende:"
              Text(
                'Qué atiende:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: specialties.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (center.approximateLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Colors.deepOrange),
                      const SizedBox(width: 4),
                      Text(
                        'Ubicación aproximada. Confirma antes de ir.',
                        style: TextStyle(color: Colors.deepOrange.shade700, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Botón de acción: Cómo llegar
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () => onDirections(center),
                  style: FilledButton.styleFrom(
                    backgroundColor: BiomarkColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Cómo llegar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthCenterMarker extends StatelessWidget {
  const _HealthCenterMarker({required this.center, this.selected = false});
  final HealthCenter center;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isHospital =
        center.level == 3 || center.type.toUpperCase().contains('HOSPITAL');
    final color = isHospital ? const Color(0xFFC62828) : BiomarkColors.green;
    final icon = isHospital
        ? Icons.local_hospital_rounded
        : Icons.health_and_safety_rounded;
    final size = isHospital ? 38.0 : 32.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: selected ? size * 1.25 : size,
      height: selected ? size * 1.25 : size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: selected ? 3.0 : 2.0),
        boxShadow: [
          BoxShadow(
            color: selected ? color.withValues(alpha: 0.5) : Colors.black26,
            blurRadius: selected ? 8 : 4,
            spreadRadius: selected ? 3 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: isHospital ? (selected ? 22 : 18) : (selected ? 18 : 15),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker({required this.pulseAnimation});
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final t = pulseAnimation.value;
        final t2 = (t + 0.5) % 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BiomarkColors.blue.withValues(alpha: .35),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    size: 13,
                    color: BiomarkColors.blue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tu ubicación',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(8, 4),
              painter: const _BalloonPointerPainter(color: Colors.white),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 20 + (t * 24),
                    height: 20 + (t * 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BiomarkColors.blue.withValues(
                        alpha: (1.0 - t) * 0.4,
                      ),
                      border: Border.all(
                        color: BiomarkColors.blue.withValues(
                          alpha: (1.0 - t) * 0.6,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 20 + (t2 * 20),
                    height: 20 + (t2 * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BiomarkColors.blue.withValues(
                        alpha: (1.0 - t2) * 0.3,
                      ),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: BiomarkColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalloonPointerPainter extends CustomPainter {
  final Color color;
  const _BalloonPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommunityEventMarker extends StatelessWidget {
  const _CommunityEventMarker({required this.event});
  final CommunityEvent event;

  @override
  Widget build(BuildContext context) {
    final visual = _getEventVisual(event);
    return Tooltip(
      message: '${event.title} (${visual.category})',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: visual.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          visual.icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _EventVisualData {
  final IconData icon;
  final Color color;
  final String category;
  const _EventVisualData(this.icon, this.color, this.category);
}

_EventVisualData _getEventVisual(CommunityEvent event) {
  final text = '${event.title} ${event.description}'.toLowerCase();
  if (text.contains('vacun') ||
      text.contains('inmuniz') ||
      text.contains('dosis')) {
    return const _EventVisualData(
      Icons.vaccines_rounded,
      Color(0xFF00897B),
      'Vacunación',
    );
  }
  if (text.contains('fumig') ||
      text.contains('plaga') ||
      text.contains('dengue') ||
      text.contains('limpieza') ||
      text.contains('vector') ||
      text.contains('abatiz')) {
    return const _EventVisualData(
      Icons.pest_control_rounded,
      Color(0xFFE65100),
      'Fumigación / Limpieza',
    );
  }
  if (text.contains('sangre') || text.contains('donac')) {
    return const _EventVisualData(
      Icons.bloodtype_rounded,
      Color(0xFFC2185B),
      'Donación de sangre',
    );
  }
  if (text.contains('dient') ||
      text.contains('dental') ||
      text.contains('odonto')) {
    return const _EventVisualData(
      Icons.medical_information_rounded,
      Color(0xFF0288D1),
      'Salud dental',
    );
  }
  if (text.contains('consult') ||
      text.contains('feria') ||
      text.contains('atenci') ||
      text.contains('medic') ||
      text.contains('chequeo')) {
    return const _EventVisualData(
      Icons.medical_services_rounded,
      Color(0xFF5E35B1),
      'Consulta médica',
    );
  }
  return const _EventVisualData(
    Icons.event_available_rounded,
    Color(0xFF283593),
    'Jornada comunitaria',
  );
}

class _CommunityReportMarker extends StatelessWidget {
  const _CommunityReportMarker({
    required this.report,
    required this.pulseAnimation,
  });
  final CommunityReportPoint report;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final hasDesc = report.description.trim().isNotEmpty;
    final descText = hasDesc
        ? (report.description.trim().length > 16
            ? '${report.description.trim().substring(0, 16)}…'
            : report.description.trim())
        : '${report.caseCount} ${report.caseCount == 1 ? 'caso' : 'casos'}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            final t = pulseAnimation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28 + (t * 10),
                  height: 28 + (t * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFFF1744,
                    ).withValues(alpha: (1.0 - t) * 0.45),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD50000),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.report_problem_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF1744), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1744),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    descText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.white.withValues(alpha: .96),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: BiomarkColors.blue),
        ),
      ),
    ),
  );
}

String _levelLabel(int level) => switch (level) {
  3 => 'Hospital / referencia',
  2 => 'Centro de salud',
  _ => 'Puesto de salud',
};

// [OBSOLETO - Reemplazado por showCommunityReportSheet en community_report_screen.dart con campos oficiales MINSA]
// Se conserva comentado con fines de trazabilidad histórica.
// class _ReportDraft { ... }
// class _ReportDialog extends StatefulWidget { ... }
