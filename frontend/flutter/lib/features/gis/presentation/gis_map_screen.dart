import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

class _GisMapScreenState extends State<GisMapScreen> {
  static const _managua = LatLng(12.1364, -86.2514);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _gisApi = GisApi();
  final _sheetController = DraggableScrollableController();
  Timer? _viewportTimer;

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
    if (widget.initialCenter != null) {
      _mapCenter = LatLng(
        widget.initialCenter!.latitude,
        widget.initialCenter!.longitude,
      );
      _zoom = 15;
    }
    _loadViewport();
    _loadLayersOnce();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  Future<void> _loadViewport([LatLngBounds? bounds]) async {
    final visible = bounds ?? _boundsAround(_mapCenter, _zoom);
    if (mounted) setState(() => _loading = true);
    try {
      final data = await _gisApi.fetchViewport(
        minLon: visible.west,
        minLat: visible.south,
        maxLon: visible.east,
        maxLat: visible.north,
        zoom: _zoom,
      );
      if (!mounted) return;
      setState(() {
        _centers = data.centers;
        _loading = false;
      });
    } on GisApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.statusCode == 429
            ? 'Demasiadas peticiones. Espera unos minutos y vuelve a intentar.'
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

  Future<void> _loadLayersOnce() async {
    if (_layersLoaded || _layersLoading) return;
    _layersLoading = true;
    try {
      final layers = await _gisApi.fetchLayers(
        latitude: _mapCenter.latitude,
        longitude: _mapCenter.longitude,
      );
      List<CommunityReportPoint> reports = const [];
      try {
        reports = await _gisApi.fetchValidatedReports();
      } on GisApiException catch (error) {
        if (mounted) {
          setState(
            () => _error = error.statusCode == 401 || error.statusCode == 403
                ? 'Inicia sesión para ver los reportes comunitarios.'
                : error.statusCode == 429
                ? 'Demasiadas peticiones. Espera unos minutos y vuelve a intentar.'
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
    if (event is! MapEventMoveEnd && event is! MapEventFlingAnimationEnd)
      return;
    _mapCenter = event.camera.center;
    _zoom = event.camera.zoom;
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
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const PermissionDeniedException('Ubicación denegada');
      }
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _userLocation = location);
      _mapController.move(location, 14);
    } catch (_) {
      _mapController.move(_managua, 12);
      if (mounted)
        setState(
          () => _error =
              'Mostrando Managua. Puedes activar la ubicación cuando quieras.',
        );
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
    final destination = '${center.latitude},${center.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
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
      if (mounted)
        setState(
          () => _error =
              'No se pudo enviar el reporte. Inicia sesión e inténtalo de nuevo.',
        );
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
            width: 48,
            height: 48,
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
                  child: _CenterDot(
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
          width: 52,
          height: 52,
          child: const IgnorePointer(child: _UserLocationMarker()),
        ),
      if (_showEvents)
        ..._events.map(
          (event) => Marker(
            point: LatLng(event.latitude, event.longitude),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _error = '${event.title} · ${event.location}'),
              child: const Icon(
                Icons.event_available_rounded,
                color: BiomarkColors.blue,
                size: 28,
              ),
            ),
          ),
        ),
      if (_showReports)
        ..._reports.map(
          (report) => Marker(
            point: LatLng(report.latitude, report.longitude),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => setState(
                () => _error =
                    '${report.caseCount} casos reportados en esta zona',
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                color: Colors.redAccent,
                size: 26,
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
                    ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png?api_key=${AppConfig.cartoApiKey}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: AppConfig.cartoApiKey.isNotEmpty
                    ? const ['a', 'b', 'c', 'd']
                    : const [],
                userAgentPackageName: 'com.biomark.ai',
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
        color: Colors.white,
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
                  color: Colors.black12,
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
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                selected!.address,
                style: const TextStyle(color: Colors.black54),
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

class _CenterDot extends StatelessWidget {
  const _CenterDot({required this.center, this.selected = false});
  final HealthCenter center;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = center.level == 3
        ? 16.0
        : center.level == 2
        ? 12.0
        : 8.0;
    final filled = center.level != 1;
    final color = center.level == 3 ? BiomarkColors.blue : BiomarkColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? size * 1.3 : size,
      height: selected ? size * 1.3 : size,
      decoration: BoxDecoration(
        color: filled ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? Colors.white : color,
          width: center.level == 3 ? 2 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .25),
                  blurRadius: 0,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: BiomarkColors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
    ),
  );
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
