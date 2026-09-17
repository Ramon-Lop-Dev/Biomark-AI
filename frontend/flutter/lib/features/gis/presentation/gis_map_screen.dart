import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../../../biomark_brand.dart';
import '../../../core/config/app_config.dart';
import '../data/gis_api.dart';
import '../domain/health_center.dart';

class GisMapScreen extends StatefulWidget {
  const GisMapScreen({super.key, this.initialCenter});

  final HealthCenter? initialCenter;

  @override
  State<GisMapScreen> createState() => _GisMapScreenState();
}

class _GisMapScreenState extends State<GisMapScreen>
    with SingleTickerProviderStateMixin {
  static const _managua = LatLng(12.1364, -86.2514);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _gisApi = GisApi();
  final _sheetController = DraggableScrollableController();
  Timer? _viewportTimer;
  late final AnimationController _pulseController;

  List<HealthCenter> _centers = const [];
  LatLng _mapCenter = _managua;
  double _zoom = 12;
  bool _loading = true;
  bool _locating = false;
  String? _error;
  HealthCenter? _selected;
  List<RiskZone> _riskZones = const [];
  List<CommunityEvent> _events = const [];
  List<CommunityReportPoint> _reports = const [];
  LatLng? _userLocation;
  bool _showEvents = true;
  bool _showRisk = false;
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

    if (widget.initialCenter != null) {
      _mapCenter = LatLng(
        widget.initialCenter!.latitude,
        widget.initialCenter!.longitude,
      );
      _zoom = 15;
      _loadViewport();
      _loadLayersOnce();
    } else {
      // Localizar primero para no duplicar peticiones de Managua + ubicación real
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
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
      if (!mounted) return;
      setState(() {
        final centersMap = <String, HealthCenter>{
          for (final c in _centers) c.id: c,
          for (final c in data.centers) c.id: c,
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
    final zoomChanged = (newZoom - _zoom).abs() > 0.8;

    _mapCenter = newCenter;
    _zoom = newZoom;

    // Si el movimiento es leve (< 800m) y el zoom no cambió sustancialmente, no disparar petición
    if (distanceMoved < 800 && !zoomChanged) {
      return;
    }

    _viewportTimer?.cancel();
    _viewportTimer = Timer(const Duration(milliseconds: 700), () {
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
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userLocation = location;
          _mapCenter = location;
          _zoom = 14;
        });
      }
      _mapController.move(location, 14);
      unawaited(_loadViewport(_boundsAround(location, 14)));
      unawaited(_loadLayersOnce());
    } catch (_) {
      _mapController.move(_managua, 12);
      if (mounted) {
        setState(() {
          _mapCenter = _managua;
          _zoom = 12;
        });
      }
      unawaited(_loadViewport(_boundsAround(_managua, 12)));
      unawaited(_loadLayersOnce());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<HealthCenter> get _visibleCenters {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _centers;
    return _centers
        .where((center) => center.name.toLowerCase().contains(query))
        .toList();
  }

  void _selectCenter(HealthCenter center) {
    setState(() => _selected = center);
    _mapController.move(LatLng(center.latitude, center.longitude), 15);
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        .38,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
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
    final draft = await showDialog<_ReportDraft>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (draft == null || draft.description.trim().isEmpty) return;
    try {
      await _gisApi.createCommunityReport(
        latitude: _mapCenter.latitude,
        longitude: _mapCenter.longitude,
        description: draft.description.trim(),
        caseCount: draft.caseCount,
      );
      if (mounted) setState(() => _error = 'Reporte enviado para validación.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo enviar el reporte. Inicia sesión e inténtalo de nuevo.',
        );
      }
    }
  }

  Future<void> _openDetails(HealthCenter center) async {
    try {
      final details = await _gisApi.fetchCenterDetails(center.id);
      if (mounted) setState(() => _selected = details);
    } catch (_) {
      if (mounted) setState(() => _selected = center);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centers = _visibleCenters;
    final markers = centers
        .map(
          (center) => Marker(
            point: LatLng(center.latitude, center.longitude),
            width: 52,
            height: 52,
            child: Semantics(
              label: center.name,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _selectCenter(center);
                  _openDetails(center);
                },
                child: Center(
                  child: _HealthCenterMarker(
                    center: center,
                    selected: _selected?.id == center.id,
                  ),
                ),
              ),
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
              onTap: () {
                final visual = _getEventVisual(event);
                setState(() => _error = '[${visual.category}] ${event.title} · ${event.location}');
              },
              child: _CommunityEventMarker(event: event),
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
              onTap: () => setState(
                () => _error =
                    '${report.caseCount} ${report.caseCount == 1 ? 'caso' : 'casos'} reportados: ${report.description.isNotEmpty ? report.description : "Zona con reporte comunitario"}',
              ),
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
              if (_showReports && _reports.isNotEmpty)
                CircleLayer(
                  circles: _reports
                      .map(
                        (report) => CircleMarker(
                          point: LatLng(report.latitude, report.longitude),
                          radius: 350,
                          useRadiusInMeter: true,
                          color: const Color(0x33FF1744),
                          borderColor: const Color(0xCCFF1744),
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
                          radius: zone.radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: Colors.red.withValues(alpha: .15),
                          borderColor: Colors.red.withValues(alpha: .5),
                          borderStrokeWidth: 2,
                        ),
                      )
                      .toList(),
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: markers,
                  maxClusterRadius: 55,
                  size: const Size(42, 42),
                  builder: (context, markers) =>
                      _ClusterDot(count: markers.length),
                ),
              ),
              MarkerLayer(markers: layerMarkers),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  if (AppConfig.cartoApiKey.isNotEmpty)
                    TextSourceAttribution('CARTO'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: .94),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Buscar centro',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RoundControl(
                    icon: _locating
                        ? Icons.sync_rounded
                        : Icons.my_location_rounded,
                    tooltip: 'Mi ubicación',
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
          _CenterSheet(
            centers: centers,
            selected: _selected,
            onSelected: _selectCenter,
            onClose: () => setState(() => _selected = null),
            onDirections: _openDirections,
            controller: _sheetController,
          ),
          Positioned(
            right: 16,
            bottom: 112,
            child: _RoundControl(
              icon: Icons.add_location_alt_outlined,
              tooltip: 'Agregar reporte',
              onTap: _createReport,
            ),
          ),
        ],
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
    _sheetController.dispose();
    _gisApi.dispose();
    super.dispose();
  }
}

class _CenterSheet extends StatelessWidget {
  const _CenterSheet({
    required this.centers,
    required this.selected,
    required this.onSelected,
    required this.onClose,
    required this.onDirections,
    required this.controller,
  });
  final List<HealthCenter> centers;
  final HealthCenter? selected;
  final ValueChanged<HealthCenter> onSelected;
  final VoidCallback onClose;
  final ValueChanged<HealthCenter> onDirections;
  final DraggableScrollableController controller;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: selected == null ? .085 : .38,
      minChildSize: .085,
      maxChildSize: .86,
      snap: true,
      snapSizes: const [.085, .38, .86],
      builder: (context, controller) => Material(
        color: Theme.of(context).cardColor,
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (selected != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selected!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
              Text(
                '${_levelLabel(selected!.level)} · ${selected!.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: BiomarkColors.blue),
              ),
              if (selected!.specialties.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Especializado en: ${selected!.specialties.take(3).join(', ')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                selected!.address,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (selected!.approximateLocation)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Ubicación aproximada. Confirma la dirección antes de ir.',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => onDirections(selected!),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Cómo llegar'),
              ),
              const SizedBox(height: 18),
              const Divider(),
            ],
            Text(
              '${centers.length} centros en esta zona',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...centers
                .take(8)
                .map(
                  (center) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _CenterDot(center: center),
                    title: Text(
                      center.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_levelLabel(center.level)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelected(center),
                  ),
                ),
          ],
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

class _CenterDot extends StatelessWidget {
  const _CenterDot({required this.center});
  final HealthCenter center;

  @override
  Widget build(BuildContext context) {
    final isHospital =
        center.level == 3 || center.type.toUpperCase().contains('HOSPITAL');
    final color = isHospital ? const Color(0xFFC62828) : BiomarkColors.green;
    final icon = isHospital
        ? Icons.local_hospital_rounded
        : Icons.health_and_safety_rounded;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(icon, color: color, size: 18),
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

class _ClusterDot extends StatelessWidget {
  const _ClusterDot({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xffe8e8e8),
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
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

class _ReportDraft {
  const _ReportDraft({required this.description, required this.caseCount});
  final String description;
  final int caseCount;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _descriptionController = TextEditingController();
  int _caseCount = 1;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Agregar reporte comunitario'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: '¿Qué está ocurriendo?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _caseCount,
          decoration: const InputDecoration(
            labelText: 'Casos aproximados',
            border: OutlineInputBorder(),
          ),
          items: List.generate(
            10,
            (index) =>
                DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
          ),
          onChanged: (value) => setState(() => _caseCount = value ?? 1),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _ReportDraft(
            description: _descriptionController.text,
            caseCount: _caseCount,
          ),
        ),
        child: const Text('Enviar'),
      ),
    ],
  );
}
