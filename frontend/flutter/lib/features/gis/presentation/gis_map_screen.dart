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
  List<CommunityEvent> _events = const [];
  List<CommunityReportPoint> _reports = const [];
  LatLng _userLocation = _defaultLocation;
  bool _showRiskZones = false;
  bool _showEvents = true;
  bool _showReports = true;
  bool _showPlacesPanel = true;
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
      LatLng location;
      try {
        final position = await _findUserLocation();
        location = LatLng(position.latitude, position.longitude);
      } catch (_) {
        if (widget.initialCenter == null) rethrow;
        location = LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude);
      }
      final data = await _gisApi.fetchNearby(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      List<CommunityReportPoint> reports = const [];
      try {
        reports = await _gisApi.fetchValidatedReports();
      } catch (_) {
        // Un fallo del heatmap no debe ocultar centros ni jornadas.
      }
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _centers = widget.initialCenter == null
            ? data.centers
            : [widget.initialCenter!, ...data.centers.where((center) => center.id != widget.initialCenter!.id)];
        _riskZones = data.riskZones;
        _events = data.events;
        _reports = reports;
        _loading = false;
      });
      if (widget.initialCenter == null) {
        _mapController.move(location, 13.2);
      }
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

  Future<void> _refreshUserLocation() async {
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
      List<CommunityReportPoint> reports = const [];
      try {
        reports = await _gisApi.fetchValidatedReports();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _centers = data.centers;
        _riskZones = data.riskZones;
        _events = data.events;
        _reports = reports;
        _loading = false;
      });
      _mapController.move(location, 14.5);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'No se pudo actualizar tu ubicación. Revisa el GPS y los permisos.';
        });
      }
    }
  }

  Future<void> _showReportDialog() async {
    if (_userLocation == _defaultLocation) {
      _showStatus('Activa tu ubicación para registrar un reporte comunitario.');
      return;
    }
    final descriptionController = TextEditingController();
    var caseCount = 1;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar situación en mi sector'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ayúdanos a identificar zonas con posibles casos. Tu reporte será revisado antes de aparecer en el mapa.',
                  style: TextStyle(height: 1.35),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '¿Qué está ocurriendo?',
                  hintText: 'Ej. posibles casos de dengue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: caseCount,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de casos',
                  helperText: 'Indica cuántos casos aproximados observaste.',
                ),
                items: List.generate(10, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                onChanged: (value) => setDialogState(() => caseCount = value ?? 1),
              ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Enviar reporte')),
          ],
        ),
      ),
    );
    if (submitted != true || !mounted) {
      descriptionController.dispose();
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      descriptionController.dispose();
      _showStatus('Describe brevemente la situación antes de enviar.');
      return;
    }
    try {
      await _gisApi.createCommunityReport(
        latitude: _userLocation.latitude,
        longitude: _userLocation.longitude,
        description: descriptionController.text.trim(),
        caseCount: caseCount,
      );
      if (mounted) _showStatus('Reporte enviado. Quedará pendiente de validación.');
    } catch (_) {
      if (mounted) _showStatus('No se pudo enviar el reporte comunitario.');
    } finally {
      descriptionController.dispose();
    }
  }

  void _showStatus(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showReportDetails(CommunityReportPoint report) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zona con reportes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '${report.caseCount} ${report.caseCount == 1 ? 'caso reportado' : 'casos reportados'} en esta zona.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'La ubicación está aproximada para proteger la privacidad de la comunidad.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
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
        return matchesSearch;
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
      if (_showEvents)
        ..._events.map((event) => Marker(
              point: LatLng(event.latitude, event.longitude),
              width: 46,
              height: 46,
              child: GestureDetector(
                onTap: () => _showStatus('${event.title} · ${event.location}'),
                child: const _EventMarker(),
              ),
            )),
      if (_showReports)
        ..._reports.map((report) => Marker(
              point: LatLng(report.latitude, report.longitude),
              width: 52,
              height: 52,
              child: GestureDetector(
                onTap: () => _showReportDetails(report),
                child: _ReportMarker(caseCount: report.caseCount),
              ),
            )),
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
              if (_showReports)
                CircleLayer(
                  circles: _reports.map((report) => CircleMarker(
                    point: LatLng(report.latitude, report.longitude),
                    radius: 180 + report.caseCount * 35,
                    useRadiusInMeter: true,
                    color: Colors.red.withValues(alpha: .24),
                    borderColor: Colors.red.withValues(alpha: .75),
                    borderStrokeWidth: 2,
                  )).toList(),
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
          if (_errorMessage != null)
            Positioned(
              top: 66,
              left: 16,
              right: 16,
              child: _StatusBanner(message: _errorMessage!),
            ),
          Positioned(
            left: 16,
            bottom: _showPlacesPanel ? 178 : 86,
            child: Column(
              children: [
                _MapControl(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Mi ubicación',
                  label: 'Ubicación',
                  onTap: _refreshUserLocation,
                ),
                const SizedBox(height: 12),
                _MapControl(
                  icon: Icons.event_available_rounded,
                  tooltip: 'Jornadas comunitarias',
                  label: 'Jornadas',
                  active: _showEvents,
                  onTap: () => setState(() => _showEvents = !_showEvents),
                ),
                const SizedBox(height: 12),
                _MapControl(
                  icon: Icons.report_problem_outlined,
                  tooltip: 'Reportes comunitarios',
                  label: 'Reportes',
                  active: _showReports,
                  onTap: () => setState(() => _showReports = !_showReports),
                ),
                const SizedBox(height: 12),
                _MapControl(
                  icon: Icons.warning_amber_rounded,
                  tooltip: 'Capas de riesgo',
                  label: 'Riesgo',
                  active: _showRiskZones,
                  onTap: () => setState(() => _showRiskZones = !_showRiskZones),
                ),
                const SizedBox(height: 12),
                _MapControl(
                  icon: _showPlacesPanel ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                  tooltip: _showPlacesPanel ? 'Ocultar centros cercanos' : 'Mostrar centros cercanos',
                  label: 'Centros',
                  active: _showPlacesPanel,
                  onTap: () => setState(() => _showPlacesPanel = !_showPlacesPanel),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: _showPlacesPanel ? 352 : 150,
            child: _MapControl(
              icon: Icons.add_location_alt_rounded,
              tooltip: 'Reportar situación',
              label: 'Reportar',
              onTap: _showReportDialog,
            ),
          ),
          if (_showPlacesPanel)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CenterCarousel(
                centers: centers,
                onTap: _showCenterDetails,
                onFocus: _focusCenter,
                onClose: () => setState(() => _showPlacesPanel = false),
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
            child: SizedBox(
              height: 44,
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12),
                ],
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  hintText: 'Buscar centro de salud',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _MapControl(
          icon: loading ? Icons.sync_rounded : Icons.refresh_rounded,
          tooltip: 'Actualizar capas del mapa',
          onTap: onRefresh,
        ),
      ],
    );
  }
}

class _CenterCarousel extends StatelessWidget {
  final List<HealthCenter> centers;
  final ValueChanged<HealthCenter> onTap;
  final ValueChanged<HealthCenter> onFocus;
  final VoidCallback onClose;
  const _CenterCarousel({
    required this.centers,
    required this.onTap,
    required this.onFocus,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  'Centros cercanos (${centers.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Ocultar centros cercanos',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        scrollDirection: Axis.horizontal,
        itemCount: centers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final center = centers[index];
          return GestureDetector(
            onTap: () => onTap(center),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .72,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
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
                              fontSize: 14,
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
                    const SizedBox(height: 3),
                    Text(
                      '${_labelForType(center.type)} · Abierto 24h',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      center.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
          ),
        ],
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
  final String? label;
  final bool active;
  final VoidCallback onTap;
  const _MapControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : BiomarkColors.black;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? BiomarkColors.green : Colors.white.withValues(alpha: .92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(label == null ? 40 : 14)),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(label == null ? 40 : 14),
          child: SizedBox(
            width: label == null ? 48 : 68,
            height: label == null ? 48 : 52,
            child: label == null
                ? Icon(icon, color: foreground)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: foreground, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        label!,
                        style: TextStyle(color: foreground, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
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

class _EventMarker extends StatelessWidget {
  const _EventMarker();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: BiomarkColors.blue, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: const Icon(Icons.campaign_rounded, color: BiomarkColors.blue, size: 24),
      );
}

class _ReportMarker extends StatelessWidget {
  final int caseCount;

  const _ReportMarker({required this.caseCount});

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Text(
          '$caseCount',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
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
