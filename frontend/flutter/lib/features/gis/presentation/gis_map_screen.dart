import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  static const _defaultLocation = LatLng(12.1364, -86.2514);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _gisApi = GisApi();

  List<HealthCenter> _centers = const [];
  List<RiskZone> _riskZones = const [];
  LatLng _userLocation = _defaultLocation;
  String _selectedFilter = 'Todos';
  bool _showRiskZones = false;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      setState(() {
        _userLocation = LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude);
        _centers = [widget.initialCenter!];
        _loading = false;
      });
      _mapController.move(_userLocation, 15);
    }
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final position = await _findUserLocation();
      final location = LatLng(position.latitude, position.longitude);
      final data = await _gisApi.fetchNearby(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _centers = data.centers;
        _riskZones = data.riskZones;
        _loading = false;
      });
      _mapController.move(location, 13.2);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _centers = _fallbackCenters;
        _loading = false;
        _errorMessage =
            'Mostrando centros de referencia. Conecta tu sesión para ver datos reales.';
      });
    }
  }

  Future<Position> _findUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('Permiso de ubicación denegado.');
    }
    return Geolocator.getCurrentPosition();
  }

  List<HealthCenter> get _fallbackCenters => const [
    HealthCenter(
      id: 'demo-1',
      name: 'CS. Pedro Altamirano',
      type: 'VACUNACION',
      latitude: 12.145,
      longitude: -86.265,
      address: 'Managua, Nicaragua',
      phone: '',
      distanceKm: 0.8,
    ),
    HealthCenter(
      id: 'demo-2',
      name: 'Hospital Militar',
      type: 'HOSPITAL',
      latitude: 12.126,
      longitude: -86.24,
      address: 'Managua, Nicaragua',
      phone: '',
      distanceKm: 2.5,
    ),
    HealthCenter(
      id: 'demo-3',
      name: 'Clínica San Carlos',
      type: 'CLINICA',
      latitude: 12.115,
      longitude: -86.255,
      address: 'Managua, Nicaragua',
      phone: '',
      distanceKm: 3.1,
    ),
  ];

  List<HealthCenter> get _filteredCenters {
    final query = _searchController.text.trim().toLowerCase();
    return _centers.where((center) {
      final matchesSearch =
          query.isEmpty ||
          center.name.toLowerCase().contains(query) ||
          center.address.toLowerCase().contains(query);
      final matchesFilter =
          _selectedFilter == 'Todos' ||
          center.type.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
          (_selectedFilter == 'Hospitales' &&
              center.type.toLowerCase().contains('hospital')) ||
          (_selectedFilter == 'Clínicas' &&
              center.type.toLowerCase().contains('clinica'));
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _focusCenter(HealthCenter center) {
    _mapController.move(LatLng(center.latitude, center.longitude), 15);
  }

  void _showCenterDetails(HealthCenter center) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              center.name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${_labelForType(center.type)} · ${_formatDistance(center.distanceKm)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(center.address, style: const TextStyle(fontSize: 15)),
            if (center.phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(center.phone),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _focusCenter(center);
                },
                icon: const Icon(Icons.near_me_rounded),
                label: const Text('Ver en el mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('hospital')) return 'Hospital';
    if (normalized.contains('clinica')) return 'Clínica';
    if (normalized.contains('vacun')) return 'Vacunación';
    return 'Centro de salud';
  }

  String _formatDistance(double distance) =>
      distance == 0 ? 'Ubicación actual' : '${distance.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final centers = _filteredCenters;
    final markers = <Marker>[
      Marker(
        point: _userLocation,
        width: 46,
        height: 46,
        child: const _UserMarker(),
      ),
      ...centers.map(
        (center) => Marker(
          point: LatLng(center.latitude, center.longitude),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showCenterDetails(center),
            child: _CenterMarker(center: center),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 13.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.biomark.ai',
              ),
              if (_showRiskZones)
                CircleLayer(
                  circles: _riskZones
                      .map(
                        (zone) => CircleMarker(
                          point: LatLng(zone.latitude, zone.longitude),
                          radius: zone.radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: Colors.red.withValues(alpha: .18),
                          borderColor: Colors.red.withValues(alpha: .55),
                          borderStrokeWidth: 2,
                        ),
                      )
                      .toList(),
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _SearchHeader(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onRefresh: _loadMap,
              loading: _loading,
            ),
          ),
          Positioned(
            top: 76,
            left: 0,
            right: 0,
            child: _FilterRow(
              selected: _selectedFilter,
              onSelected: (filter) => setState(() => _selectedFilter = filter),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              top: 122,
              left: 16,
              right: 16,
              child: _StatusBanner(message: _errorMessage!),
            ),
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                _MapControl(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Mi ubicación',
                  onTap: () => _mapController.move(_userLocation, 14.5),
                ),
                const SizedBox(height: 12),
                _MapControl(
                  icon: Icons.warning_amber_rounded,
                  tooltip: 'Capas de riesgo',
                  active: _showRiskZones,
                  onTap: () => setState(() => _showRiskZones = !_showRiskZones),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CenterCarousel(
              centers: centers,
              onTap: _showCenterDetails,
              onFocus: _focusCenter,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gisApi.dispose();
    super.dispose();
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;
  final bool loading;

  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onRefresh,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar centros de salud...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MapControl(
          icon: loading ? Icons.sync_rounded : Icons.tune_rounded,
          tooltip: 'Actualizar mapa',
          onTap: onRefresh,
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = ['Todos', 'Hospitales', 'Clínicas', 'Vacunación'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected == filter,
                  onSelected: (_) => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CenterCarousel extends StatelessWidget {
  final List<HealthCenter> centers;
  final ValueChanged<HealthCenter> onTap;
  final ValueChanged<HealthCenter> onFocus;
  const _CenterCarousel({
    required this.centers,
    required this.onTap,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        scrollDirection: Axis.horizontal,
        itemCount: centers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final center = centers[index];
          return GestureDetector(
            onTap: () => onFocus(center),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .82,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            center.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _formatDistance(center.distanceKm),
                          style: const TextStyle(
                            color: BiomarkColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_labelForType(center.type)} · Abierto 24h',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      center.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => onTap(center),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Ver detalles'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _labelForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('hospital')) return 'Hospital';
    if (normalized.contains('clinica')) return 'Clínica';
    if (normalized.contains('vacun')) return 'Vacunación';
    return 'Centro de salud';
  }

  String _formatDistance(double distance) =>
      distance == 0 ? 'Aquí' : '${distance.toStringAsFixed(1)} km';
}

class _MapControl extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: active ? BiomarkColors.green : Colors.white.withValues(alpha: .9),
    shape: const CircleBorder(),
    elevation: 4,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: active ? Colors.white : BiomarkColors.black),
    ),
  );
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: BiomarkColors.blue,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
    ),
    child: const Icon(
      Icons.person_pin_circle_rounded,
      color: Colors.white,
      size: 24,
    ),
  );
}

class _CenterMarker extends StatelessWidget {
  final HealthCenter center;
  const _CenterMarker({required this.center});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: BiomarkColors.green, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
    ),
    child: Icon(
      center.type.toLowerCase().contains('hospital')
          ? Icons.local_hospital_rounded
          : Icons.medical_services_rounded,
      color: BiomarkColors.green,
      size: 24,
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  final String message;
  const _StatusBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      message,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
