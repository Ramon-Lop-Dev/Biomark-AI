import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../biomark_brand.dart';
import '../../core/auth/auth_session.dart';
import '../../core/config/app_config.dart';

class CommunityReportItem {
  final String id;
  final String description;
  final int cases;
  final String status;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  const CommunityReportItem({required this.id, required this.description, required this.cases, required this.status, required this.createdAt, required this.latitude, required this.longitude});

  factory CommunityReportItem.fromJson(Map<String, dynamic> json) => CommunityReportItem(
        id: '${json['id'] ?? ''}',
        description: '${json['descripcion'] ?? 'Sin descripción'}',
        cases: (json['cantidad_casos'] as num?)?.toInt() ?? 1,
        status: '${json['estado'] ?? 'PENDIENTE_VALIDACION'}',
        createdAt: DateTime.tryParse('${json['fecha_creacion'] ?? ''}') ?? DateTime.now(),
        latitude: (json['latitud'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitud'] as num?)?.toDouble() ?? 0,
      );
}

class PromoterApi {
  PromoterApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String get _base => AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthSession.instance.accessToken ?? ''}',
      };

  Future<Map<String, dynamic>> _jsonRequest(Future<http.Response> request) async {
    final response = await request;
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['error'] ?? body['message'] : null;
      throw Exception(message ?? 'No se pudo completar la operación.');
    }
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  Future<List<CommunityReportItem>> reports({String? status}) async {
    final uri = Uri.parse('$_base/api/community/reports/operational').replace(
      queryParameters: status == null ? null : {'estado': status},
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('No se pudieron cargar los reportes.');
    final data = jsonDecode(response.body);
    return data is List ? data.whereType<Map<String, dynamic>>().map(CommunityReportItem.fromJson).toList() : const [];
  }

  Future<Map<String, dynamic>> statistics() async {
    return _jsonRequest(_client.get(Uri.parse('$_base/api/community/statistics'), headers: _headers));
  }

  Future<List<Map<String, dynamic>>> events() async {
    final response = await _client.get(Uri.parse('$_base/api/community/events'));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('No se pudieron cargar las jornadas.');
    final data = jsonDecode(response.body);
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : const [];
  }

  Future<void> updateReport(String id, String status) async {
    await _jsonRequest(_client.patch(
      Uri.parse('$_base/api/community/reports/$id/estado'),
      headers: _headers,
      body: jsonEncode({'estado': status}),
    ));
  }

  Future<void> createEvent({required String title, required String description, required String date, required String location, required String type, double? latitude, double? longitude}) async {
    await _jsonRequest(_client.post(
      Uri.parse('$_base/api/community/events'),
      headers: _headers,
      body: jsonEncode({'titulo': title, 'descripcion': description, 'fecha_evento': date, 'ubicacion': location, 'tipo': type, if (latitude != null && longitude != null) 'latitud': latitude, if (latitude != null && longitude != null) 'longitud': longitude}),
    ));
  }

  void dispose() => _client.close();
}

class PromoterDashboardScreen extends StatefulWidget {
  const PromoterDashboardScreen({super.key, this.onOpenMap});
  final VoidCallback? onOpenMap;
  @override
  State<PromoterDashboardScreen> createState() => _PromoterDashboardScreenState();
}

class _PromoterDashboardScreenState extends State<PromoterDashboardScreen> {
  final _api = PromoterApi();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const {};
  List<CommunityReportItem> _pending = const [];
  List<CommunityReportItem> _allReports = const [];
  List<Map<String, dynamic>> _events = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.statistics(), _api.reports(), _api.events()]);
      if (!mounted) return;
      final reports = results[1] as List<CommunityReportItem>;
      setState(() { _stats = results[0] as Map<String, dynamic>; _allReports = reports; _pending = reports.where((report) => report.status == 'PENDIENTE_VALIDACION').toList(); _events = results[2] as List<Map<String, dynamic>>; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = '$error'; });
    }
  }

  @override
  void dispose() { _api.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final breakdown = (_stats['por_estado'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const Text('Panel comunitario', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Coordina jornadas y revisa las señales de salud del territorio.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (_error != null) _PanelMessage(message: _error!, icon: Icons.cloud_off_rounded),
              if (_loading) const LinearProgressIndicator(),
          Row(children: [
            Expanded(child: _MetricCard(label: 'Pendientes', value: '${breakdown['PENDIENTE_VALIDACION'] ?? _pending.length}', color: Colors.orange, icon: Icons.pending_actions_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(label: 'Validados', value: '${breakdown['VALIDADO'] ?? 0}', color: BiomarkColors.green, icon: Icons.verified_rounded)),
          ]),
          const SizedBox(height: 10),
          _MetricCard(label: 'Casos observados', value: '${_stats['total_casos'] ?? 0}', color: BiomarkColors.blue, icon: Icons.analytics_rounded),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Casos por sector aproximado', icon: Icons.location_on_rounded),
          const SizedBox(height: 10),
          ..._sectorSummary(),
          OutlinedButton.icon(onPressed: widget.onOpenMap, icon: const Icon(Icons.map_outlined), label: const Text('Abrir mapa comunitario')),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Reportes que requieren revisión', icon: Icons.fact_check_rounded),
          const SizedBox(height: 10),
          if (!_loading && _pending.isEmpty) const _PanelMessage(message: 'No hay reportes pendientes.', icon: Icons.check_circle_outline_rounded),
          ..._pending.take(4).map((report) => _ReportTile(report: report, api: _api, onChanged: _load)),
          const SizedBox(height: 24),
          _SectionHeading(title: 'Próximas jornadas', icon: Icons.event_available_rounded),
          const SizedBox(height: 10),
          if (!_loading && _events.isEmpty) const _PanelMessage(message: 'Todavía no hay jornadas publicadas.', icon: Icons.event_busy_rounded),
          ..._events.take(4).map((event) => _EventTile(event: event)),
        ],
      ),
    ),
  ),
);
  }

  List<Widget> _sectorSummary() {
    final sectors = <String, int>{};
    for (final report in _allReports.where((report) => report.status == 'VALIDADO')) {
      final key = '${report.latitude.toStringAsFixed(2)}, ${report.longitude.toStringAsFixed(2)}';
      sectors[key] = (sectors[key] ?? 0) + report.cases;
    }
    if (sectors.isEmpty) return [const _PanelMessage(message: 'Aún no hay suficientes datos por sector.', icon: Icons.insights_outlined)];
    return sectors.entries.take(4).map((entry) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined, color: BiomarkColors.green), title: Text('Sector aproximado ${entry.key}'), trailing: Text('${entry.value} casos', style: const TextStyle(fontWeight: FontWeight.w800)))).toList();
  }
}

class PromoterEventsScreen extends StatefulWidget {
  const PromoterEventsScreen({super.key});
  @override
  State<PromoterEventsScreen> createState() => _PromoterEventsScreenState();
}

class _PromoterEventsScreenState extends State<PromoterEventsScreen> {
  final _api = PromoterApi();
  List<Map<String, dynamic>> _events = const [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final events = await _api.events(); if (mounted) setState(() { _events = events; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  @override
  void dispose() { _api.dispose(); super.dispose(); }
  Future<void> _create() async { final created = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => _CreateEventSheet(api: _api)); if (created == true) _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Jornadas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: _create, tooltip: 'Crear jornada', icon: const Icon(Icons.add_circle_rounded, color: BiomarkColors.green)),
                  ],
                ),
                Text(
                  'Organiza actividades de salud para tu comunidad.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                if (_loading) const LinearProgressIndicator(),
                ..._events.map((event) => _EventTile(event: event)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PromoterReportsScreen extends StatefulWidget {
  const PromoterReportsScreen({super.key});
  @override
  State<PromoterReportsScreen> createState() => _PromoterReportsScreenState();
}

class AdminRoleRequestsScreen extends StatefulWidget {
  const AdminRoleRequestsScreen({super.key});
  @override
  State<AdminRoleRequestsScreen> createState() => _AdminRoleRequestsScreenState();
}

class _AdminRoleRequestsScreenState extends State<AdminRoleRequestsScreen> {
  List<Map<String, dynamic>> _requests = const [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    try {
      final response = await http.get(Uri.parse('$base/api/auth/promotor/solicitudes'), headers: {'Authorization': 'Bearer ${AuthSession.instance.accessToken ?? ''}'});
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (!mounted) return;
      setState(() { _requests = response.statusCode >= 200 && response.statusCode < 300 && body is List ? body.whereType<Map<String, dynamic>>().toList() : const []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _review(String id, String status) async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    try {
      await http.patch(Uri.parse('$base/api/auth/promotor/solicitudes/$id'), headers: {'Authorization': 'Bearer ${AuthSession.instance.accessToken ?? ''}', 'Content-Type': 'application/json'}, body: jsonEncode({'estado': status}));
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_requests.isEmpty) {
      content = const _PanelMessage(message: 'No hay solicitudes pendientes.', icon: Icons.inbox_rounded);
    } else {
      content = ListView(
        padding: const EdgeInsets.all(16),
        children: _requests.map((request) {
          final user = request['usuarios'] is Map<String, dynamic> ? request['usuarios'] as Map<String, dynamic> : const <String, dynamic>{};
          final profiles = user['perfiles'] is Map<String, dynamic> ? user['perfiles'] as Map<String, dynamic> : const <String, dynamic>{};
          return Card(
            child: ListTile(
              title: Text('${profiles['nombre_completo'] ?? user['correo'] ?? 'Usuario'}'),
              subtitle: Text('${user['correo'] ?? ''}\nSolicitud pendiente'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _review('${request['id']}', value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'APROBADA', child: Text('Aprobar')),
                  PopupMenuItem(value: 'RECHAZADA', child: Text('Rechazar')),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Solicitudes de promotor')), body: content);
  }
}

class _PromoterReportsScreenState extends State<PromoterReportsScreen> {
  final _api = PromoterApi();
  String _status = 'PENDIENTE_VALIDACION';
  List<CommunityReportItem> _reports = const [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() => _loading = true); try { final reports = await _api.reports(status: _status); if (mounted) setState(() { _reports = reports; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  @override
  void dispose() { _api.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [const Expanded(child: Text('Reportes comunitarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))])),
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: ['PENDIENTE_VALIDACION', 'VALIDADO', 'DESCARTADO'].map((status) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(_statusLabel(status)), selected: _status == status, onSelected: (_) { setState(() => _status = status); _load(); })) ).toList())),
        const SizedBox(height: 8),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _reports.isEmpty ? const _PanelMessage(message: 'No hay reportes en este estado.', icon: Icons.inbox_rounded) : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: _reports.map((report) => _ReportTile(report: report, api: _api, onChanged: _load)).toList())),
      ]);
}

String _statusLabel(String status) => {'PENDIENTE_VALIDACION': 'Pendientes', 'VALIDADO': 'Validados', 'DESCARTADO': 'Descartados'}[status] ?? status;

class _ReportTile extends StatelessWidget {
  final CommunityReportItem report;
  final PromoterApi api;
  final VoidCallback onChanged;
  const _ReportTile({required this.report, required this.api, required this.onChanged});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.report_problem_outlined, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text('${report.cases} ${report.cases == 1 ? 'caso' : 'casos'} · ${_statusLabel(report.status)}', style: const TextStyle(fontWeight: FontWeight.w800))),]), const SizedBox(height: 8), Text(report.description, style: const TextStyle(height: 1.3)), if (report.status == 'PENDIENTE_VALIDACION') Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _update(context, 'DESCARTADO'), icon: const Icon(Icons.close_rounded), label: const Text('Descartar'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _update(context, 'VALIDADO'), icon: const Icon(Icons.check_rounded), label: const Text('Validar')))]))])));
  Future<void> _update(BuildContext context, String status) async { try { await api.updateReport(report.id, status); onChanged(); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } }
}

class _CreateEventSheet extends StatefulWidget {
  final PromoterApi api;
  const _CreateEventSheet({required this.api});
  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _type = 'SALUD_COMUNITARIA';
  bool _saving = false;
  LatLng? _selectedLocation;
  final _types = const {'VACUNACION': 'Vacunación', 'FUMIGACION': 'Fumigación', 'CONSULTA_MEDICA': 'Consulta médica', 'PREVENCION_DENGUE': 'Prevención de dengue', 'SALUD_COMUNITARIA': 'Salud comunitaria'};
  @override
  void dispose() { _title.dispose(); _description.dispose(); _location.dispose(); _latitude.dispose(); _longitude.dispose(); super.dispose(); }
  Future<void> _pickDateTime() async { final pickedDate = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if (pickedDate == null || !mounted) return; final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date)); if (pickedTime != null && mounted) setState(() => _date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute)); }
  Future<void> _pickLocation() async { final point = await showDialog<LatLng>(context: context, builder: (_) => const _EventLocationPicker()); if (point != null && mounted) { setState(() { _selectedLocation = point; _latitude.text = point.latitude.toStringAsFixed(6); _longitude.text = point.longitude.toStringAsFixed(6); }); } }
  Future<void> _save() async { if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa título y ubicación.'))); return; } if (_selectedLocation == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el lugar de la jornada en el mapa.'))); return; } final latitude = double.tryParse(_latitude.text.trim()); final longitude = double.tryParse(_longitude.text.trim()); setState(() => _saving = true); try { await widget.api.createEvent(title: _title.text.trim(), description: _description.text.trim(), date: _date.toUtc().toIso8601String(), location: _location.text.trim(), type: _type, latitude: latitude, longitude: longitude); if (mounted) Navigator.pop(context, true); } catch (error) { if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } } }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: DraggableScrollableSheet(initialChildSize: .82, maxChildSize: .95, builder: (_, controller) => Material(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: ListView(controller: controller, padding: const EdgeInsets.all(20), children: [Row(children: [const Expanded(child: Text('Crear jornada', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))]), TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título *')), const SizedBox(height: 12), TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción')), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: _type, isExpanded: true, decoration: const InputDecoration(labelText: 'Tipo de jornada'), items: _types.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(), onChanged: (value) => setState(() => _type = value ?? _type)), const SizedBox(height: 12), TextField(controller: _location, decoration: const InputDecoration(labelText: 'Ubicación textual *', hintText: 'Ej. Casa comunal del barrio')), const SizedBox(height: 12), OutlinedButton.icon(onPressed: _pickLocation, icon: const Icon(Icons.map_outlined), label: Text(_selectedLocation == null ? 'Seleccionar punto en el mapa' : 'Punto seleccionado')), if (_selectedLocation != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Ubicación lista para publicar: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))), const SizedBox(height: 12), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month_rounded), title: Text('Fecha y hora: ${_date.day}/${_date.month}/${_date.year} ${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}'), onTap: _pickDateTime), const SizedBox(height: 16), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.event_available_rounded), label: Text(_saving ? 'Guardando...' : 'Publicar jornada'))]))));
}

class _EventLocationPicker extends StatefulWidget {
  const _EventLocationPicker();

  @override
  State<_EventLocationPicker> createState() => _EventLocationPickerState();
}

class _EventLocationPickerState extends State<_EventLocationPicker> {
  static const _managua = LatLng(12.1364, -86.2514);
  LatLng? _selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Selecciona el lugar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft, child: Text('Toca el mapa donde se realizará la jornada.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FlutterMap(
                options: MapOptions(initialCenter: _managua, initialZoom: 13.5, onTap: (_, point) => setState(() => _selected = point)),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.biomark.ai'),
                  if (_selected != null) MarkerLayer(markers: [Marker(point: _selected!, width: 48, height: 48, child: const Icon(Icons.location_pin, color: Colors.red, size: 44))]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _selected == null ? null : () => Navigator.pop(context, _selected), icon: const Icon(Icons.check_rounded), label: const Text('Usar este punto'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label; final String value; final Color color; final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontSize: 12))), Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color))])));
}

class _SectionHeading extends StatelessWidget { final String title; final IconData icon; const _SectionHeading({required this.title, required this.icon}); @override Widget build(BuildContext context) => Row(children: [Icon(icon, color: BiomarkColors.blue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]); }
class _PanelMessage extends StatelessWidget { final String message; final IconData icon; const _PanelMessage({required this.message, required this.icon}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 10), Expanded(child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))])); }
class _EventTile extends StatelessWidget { final Map<String, dynamic> event; const _EventTile({required this.event}); @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.event_available_rounded)), title: Text('${event['titulo'] ?? 'Jornada comunitaria'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${event['ubicacion'] ?? 'Ubicación por confirmar'}\n${event['fecha_evento'] ?? ''}'))); }
