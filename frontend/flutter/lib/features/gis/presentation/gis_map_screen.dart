import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../biomark_brand.dart';
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
  Timer? _viewportTimer;

  List<HealthCenter> _centers = const [];
  LatLng _mapCenter = _managua;
  double _zoom = 12;
  bool _loading = true;
  bool _locating = false;
  String? _error;
  HealthCenter? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _mapCenter = LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude);
      _zoom = 15;
    }
    _loadViewport();
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
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los centros. Revisa tu conexión.';
      });
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
    if (event is! MapEventMoveEnd && event is! MapEventFlingAnimationEnd) return;
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
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw const PermissionDeniedException('Ubicación denegada');
      }
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 14);
    } catch (_) {
      _mapController.move(_managua, 12);
      if (mounted) setState(() => _error = 'Mostrando Managua. Puedes activar la ubicación cuando quieras.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<HealthCenter> get _visibleCenters {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _centers;
    return _centers.where((center) => center.name.toLowerCase().contains(query)).toList();
  }

  void _selectCenter(HealthCenter center) {
    setState(() => _selected = center);
    _mapController.move(LatLng(center.latitude, center.longitude), 15);
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
    final markers = centers.map((center) => Marker(
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
          child: Center(child: _CenterDot(center: center, selected: _selected?.id == center.id)),
        ),
      ),
    )).toList();

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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.biomark.ai',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: markers,
                  maxClusterRadius: 55,
                  size: const Size(42, 42),
                  builder: (context, markers) => _ClusterDot(count: markers.length),
                ),
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
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
                      color: Colors.white.withValues(alpha: .96),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Buscar centro',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RoundControl(
                    icon: _locating ? Icons.sync_rounded : Icons.my_location_rounded,
                    tooltip: 'Mi ubicación',
                    onTap: _locate,
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              top: 82,
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
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
          _CenterSheet(
            centers: centers,
            selected: _selected,
            onSelected: _selectCenter,
            onClose: () => setState(() => _selected = null),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewportTimer?.cancel();
    _searchController.dispose();
    _gisApi.dispose();
    super.dispose();
  }
}

class _CenterSheet extends StatelessWidget {
  const _CenterSheet({required this.centers, required this.selected, required this.onSelected, required this.onClose});
  final List<HealthCenter> centers;
  final HealthCenter? selected;
  final ValueChanged<HealthCenter> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: selected == null ? .12 : .42,
      minChildSize: .12,
      maxChildSize: .86,
      snap: true,
      snapSizes: const [.12, .42, .86],
      builder: (context, controller) => Material(
        color: Colors.white,
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 10),
            if (selected != null) ...[
              Row(
                children: [
                  Expanded(child: Text(selected!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
              Text('${_levelLabel(selected!.level)} · ${selected!.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: BiomarkColors.blue)),
              const SizedBox(height: 10),
              Text(selected!.address, style: const TextStyle(color: Colors.black54)),
              if (selected!.approximateLocation)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Ubicación aproximada. Confirma la dirección antes de ir.', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.directions_rounded), label: const Text('Cómo llegar')),
              const SizedBox(height: 18),
              const Divider(),
            ],
            Text('${centers.length} centros en esta zona', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...centers.take(8).map((center) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _CenterDot(center: center),
              title: Text(center.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_levelLabel(center.level)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelected(center),
            )),
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
    final size = center.level == 3 ? 16.0 : center.level == 2 ? 12.0 : 8.0;
    final filled = center.level != 1;
    final color = center.level == 3 ? BiomarkColors.blue : BiomarkColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? size * 1.3 : size,
      height: selected ? size * 1.3 : size,
      decoration: BoxDecoration(
        color: filled ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? Colors.white : color, width: center.level == 3 ? 2 : 1.5),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 0, spreadRadius: 5)] : null,
      ),
    );
  }
}

class _ClusterDot extends StatelessWidget {
  const _ClusterDot({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xffe8e8e8), shape: BoxShape.circle),
        child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.tooltip, required this.onTap});
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
            child: SizedBox(width: 48, height: 48, child: Icon(icon, color: BiomarkColors.blue)),
          ),
        ),
      );
}

String _levelLabel(int level) => switch (level) {
      3 => 'Hospital / referencia',
      2 => 'Centro de salud',
      _ => 'Puesto de salud',
    };
