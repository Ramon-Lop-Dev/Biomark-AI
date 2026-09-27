import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../biomark_brand.dart';
import '../../core/auth/auth_session.dart';
import '../../core/config/app_config.dart';
import '../gis/data/gis_api.dart';
import '../gis/domain/health_center.dart';
import 'data/invitations_api.dart';
import 'presentation/role_tutorial_dialog.dart';

class CommunityReportItem {
  final String id;
  final String description;
  final int cases;
  final String status;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final String? tipoEnfermedad;
  final String? direccionExacta;
  final DateTime? fechaInicioSintomas;
  final String? medidasTomadas;
  final String? contactoReportante;
  final String? reporterName;
  final String? reporterEmail;
  final String clasificacionCcm;
  final String? centroSaludId;
  final String? centroSaludNombre;

  const CommunityReportItem({
    required this.id,
    required this.description,
    required this.cases,
    required this.status,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    this.tipoEnfermedad,
    this.direccionExacta,
    this.fechaInicioSintomas,
    this.medidasTomadas,
    this.contactoReportante,
    this.reporterName,
    this.reporterEmail,
    this.clasificacionCcm = 'VERDE',
    this.centroSaludId,
    this.centroSaludNombre,
  });

  factory CommunityReportItem.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuarios'] is Map<String, dynamic> ? json['usuarios'] as Map<String, dynamic> : null;
    final perfil = usuario?['perfiles'] is Map<String, dynamic> ? usuario!['perfiles'] as Map<String, dynamic> : null;
    final centro = json['centros_salud'] is Map<String, dynamic> ? json['centros_salud'] as Map<String, dynamic> : null;

    return CommunityReportItem(
      id: '${json['id'] ?? ''}',
      description: '${json['descripcion'] ?? 'Sin descripción'}',
      cases: (json['cantidad_casos'] as num?)?.toInt() ?? 1,
      status: '${json['estado'] ?? 'PENDIENTE_VALIDACION'}',
      createdAt: DateTime.tryParse('${json['fecha_creacion'] ?? ''}') ?? DateTime.now(),
      latitude: (json['latitud'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitud'] as num?)?.toDouble() ?? 0,
      tipoEnfermedad: json['tipo_enfermedad'] as String?,
      direccionExacta: json['direccion_exacta'] as String?,
      fechaInicioSintomas: DateTime.tryParse('${json['fecha_inicio_sintomas'] ?? ''}'),
      medidasTomadas: json['medidas_tomadas'] as String?,
      contactoReportante: json['contacto_reportante'] as String?,
      reporterName: perfil?['nombre_completo'] as String?,
      reporterEmail: usuario?['correo'] as String?,
      clasificacionCcm: '${json['clasificacion_ccm'] ?? 'VERDE'}'.toUpperCase(),
      centroSaludId: json['centro_salud_id'] as String?,
      centroSaludNombre: centro?['nombre'] as String?,
    );
  }
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
              const SizedBox(height: 14),
              // Cabecera de jurisdicción territorial
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: BiomarkColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: BiomarkColors.blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthSession.instance.healthCenterName ?? 'Jurisdicción Piloto Managua',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: BiomarkColors.blue),
                          ),
                          Text(
                            AuthSession.instance.isHealthWorker
                                ? 'Personal de Salud MINSA · Cobertura asignada'
                                : 'Promotor de Salud Comunitario · Red Territorial',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (AuthSession.instance.canManagePromoters) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BiomarkColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people_alt_rounded, color: BiomarkColors.green, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Red de Promotores Comunitarios', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                'Supervisa y emite invitaciones para los promotores de tu centro.',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyPromotersScreen()),
                          ),
                          child: const Text('Gestionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
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
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [const Expanded(child: Text('Reportes comunitarios', maxLines: 2, softWrap: true, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))])),
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
  Widget build(BuildContext context) {
    final hasDisease = report.tipoEnfermedad != null && report.tipoEnfermedad!.isNotEmpty;
    final hasAddress = report.direccionExacta != null && report.direccionExacta!.isNotEmpty;

    final ccm = report.clasificacionCcm;
    final Color ccmColor;
    final IconData ccmIcon;
    final String ccmLabel;
    if (ccm == 'ROJO') {
      ccmColor = const Color(0xFFEF4444);
      ccmIcon = Icons.warning_amber_rounded;
      ccmLabel = 'CCM: ALTO RIESGO (ROJO)';
    } else if (ccm == 'AMARILLO') {
      ccmColor = const Color(0xFFF59E0B);
      ccmIcon = Icons.priority_high_rounded;
      ccmLabel = 'CCM: MODERADO (AMARILLO)';
    } else {
      ccmColor = const Color(0xFF10B981);
      ccmIcon = Icons.check_circle_outline_rounded;
      ccmLabel = 'CCM: LEVE (VERDE)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Triaje semafórico CCM y Centro de Salud asignado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ccmColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ccmColor.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ccmIcon, size: 13, color: ccmColor),
                      const SizedBox(width: 4),
                      Text(
                        ccmLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: ccmColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (report.centroSaludNombre != null) ...[
                  const Spacer(),
                  const Icon(Icons.local_hospital_rounded, size: 13, color: BiomarkColors.blue),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      report.centroSaludNombre!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BiomarkColors.blue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (hasDisease ? const Color(0xFFEF4444) : Colors.orange).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasDisease ? Icons.coronavirus_rounded : Icons.report_problem_outlined,
                          size: 15,
                          color: hasDisease ? const Color(0xFFEF4444) : Colors.orange,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            report.tipoEnfermedad ?? 'Reporte Epidemiológico',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: hasDisease ? const Color(0xFFEF4444) : Colors.orange,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${report.cases} ${report.cases == 1 ? 'caso' : 'casos'} · ${_statusLabel(report.status)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (hasAddress) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      report.direccionExacta!,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(report.description, style: const TextStyle(height: 1.35, fontSize: 13)),
            if (report.medidasTomadas != null && report.medidasTomadas!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Medidas: ${report.medidasTomadas}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
            if (report.contactoReportante != null && report.contactoReportante!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Contacto reportante: ${report.contactoReportante}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
              ),
            ],
            if (report.status == 'PENDIENTE_VALIDACION')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _update(context, 'DESCARTADO'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Descartar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _update(context, 'VALIDADO'),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Validar MINSA'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    try {
      await api.updateReport(report.id, status);
      onChanged();
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
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

class MyPromotersScreen extends StatefulWidget {
  const MyPromotersScreen({super.key});

  @override
  State<MyPromotersScreen> createState() => _MyPromotersScreenState();
}

class _MyPromotersScreenState extends State<MyPromotersScreen> {
  final _invitationsApi = InvitationsApi();
  final _gisApi = GisApi();
  List<PromoterItem> _promoters = const [];
  List<HealthCenter> _centers = const [];
  bool _loading = true;
  String? _error;

  static const _fallbackCenters = [
    HealthCenter(
      id: '76720771-9c30-4592-952d-42bf0a56e1b6',
      name: 'Centro de Salud Edgar Lang',
      type: 'CENTRO_SALUD',
      latitude: 12.1180,
      longitude: -86.2850,
      address: 'Bo San Judas Contiguo al Mercado, D3',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000001',
      name: 'Centro de Salud Sócrates Flores',
      type: 'CENTRO_SALUD',
      latitude: 12.1380,
      longitude: -86.2900,
      address: 'Santa Ana Sur, Portón Cementerio General 2c al Norte, D2',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000002',
      name: 'Centro de Salud Altagracia',
      type: 'CENTRO_SALUD',
      latitude: 12.1200,
      longitude: -86.2900,
      address: 'B Altagracia Frente a Costado Sur Policía Nacional, D3',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'f6a3910e-45c8-4c6f-8c74-a65f4ca907a0',
      name: 'Centro de Salud Silvia Ferrufino',
      type: 'CENTRO_SALUD',
      latitude: 12.1500,
      longitude: -86.2700,
      address: 'Carretera Norte Gasolinera Uno Waspan 1c al Norte, D6',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000003',
      name: 'Centro de Salud Villa Libertad',
      type: 'CENTRO_SALUD',
      latitude: 12.1400,
      longitude: -86.2550,
      address: 'Frente a los pozos de ENACAL Villa Libertad, D7',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000004',
      name: 'Centro de Salud Francisco Buitrago',
      type: 'CENTRO_SALUD',
      latitude: 12.1150,
      longitude: -86.2750,
      address: 'Bo San Luis Sur detrás del Catastro, D4',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000005',
      name: 'Centro de Salud Pedro Altamirano',
      type: 'CENTRO_SALUD',
      latitude: 12.1210,
      longitude: -86.2450,
      address: 'Detrás del Mercado Roberto Huembes, D5',
      phone: '',
      distanceKm: 0,
    ),
    HealthCenter(
      id: 'a1b2c3d4-0001-4000-8000-000000000006',
      name: 'Centro de Salud Francisco Morazán',
      type: 'CENTRO_SALUD',
      latitude: 12.1400,
      longitude: -86.2950,
      address: 'Colonia Francisco Morazán, D2',
      phone: '',
      distanceKm: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _invitationsApi.dispose();
    _gisApi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _invitationsApi.getMyPromoters();
      if (AuthSession.instance.isAdmin) {
        _gisApi.fetchAllCenters().then((loaded) {
          if (mounted && loaded.isNotEmpty) {
            setState(() => _centers = loaded);
          }
        }).catchError((_) {});
      }
      if (!mounted) return;
      setState(() {
        _promoters = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _openInviteModal() async {
    final isAdmin = AuthSession.instance.isAdmin;
    final centersList = _centers.isNotEmpty ? _centers : _fallbackCenters;
    HealthCenter? selectedCenter = isAdmin ? centersList.first : null;
    String? centerError;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool generating = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: BiomarkColors.green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: BiomarkColors.green, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Acreditar Promotor Comunitario',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isAdmin) ...[
                        const Text(
                          'Selecciona el Centro de Salud de Managua al que quedará adscrito el promotor:',
                          style: TextStyle(fontSize: 13, height: 1.35),
                          softWrap: true,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<HealthCenter>(
                          initialValue: selectedCenter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Centro de Salud *',
                            prefixIcon: Icon(Icons.local_hospital_rounded),
                          ),
                          items: centersList.map((c) {
                            return DropdownMenuItem<HealthCenter>(
                              value: c,
                              child: Text(c.name, softWrap: true, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedCenter = val;
                              centerError = null;
                            });
                          },
                        ),
                        if (centerError != null) ...[
                          const SizedBox(height: 4),
                          Text(centerError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BiomarkColors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, color: BiomarkColors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'El promotor quedará adscrito a tu centro: ${AuthSession.instance.healthCenterName ?? 'Centro asignado'}.',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: BiomarkColors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BiomarkColors.green.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.info_outline_rounded, color: BiomarkColors.green, size: 16),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'El código oficial es válido por 7 días. Podrás copiarlo al portapapeles y compartirlo por WhatsApp, SMS o entregarlo en persona.',
                                style: TextStyle(fontSize: 11.5, color: BiomarkColors.green, height: 1.35),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: generating ? null : () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: generating
                                ? null
                                : () async {
                                    if (isAdmin && selectedCenter == null) {
                                      setDialogState(() => centerError = 'Selecciona un centro');
                                      return;
                                    }
                                    setDialogState(() => generating = true);
                                    try {
                                      final res = await _invitationsApi.createPromoterInvitation(
                                        centroSaludId: isAdmin ? selectedCenter!.id : AuthSession.instance.healthCenterId,
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx, true);
                                      final invMap = res['invitacion'] is Map<String, dynamic>
                                          ? res['invitacion'] as Map<String, dynamic>
                                          : null;
                                      final token = (invMap?['token'] ?? res['token'] ?? '') as String;
                                      _showTokenDialog(token);
                                    } catch (err) {
                                      if (!ctx.mounted || !mounted) return;
                                      setDialogState(() => generating = false);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: BiomarkColors.green,
                            ),
                            child: Text(generating ? 'Generando...' : 'Generar código'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      _load();
    }
  }

  void _showTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: BiomarkColors.blue, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Código de Acreditación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                softWrap: true,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comparte este código oficial con el promotor comunitario para que active su cuenta institucional en la app:',
              style: TextStyle(fontSize: 13, height: 1.35),
              softWrap: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: BiomarkColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: SelectableText(
                  token,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: BiomarkColors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: BiomarkColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BiomarkColors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 18, color: BiomarkColors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Listo para entrega directa. Puedes copiarlo y enviarlo por WhatsApp o en persona.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: BiomarkColors.green,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Válido por 7 días · Un solo uso', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado al portapapeles. Listo para enviar por WhatsApp o mensaje.'),
                  backgroundColor: BiomarkColors.green,
                ),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar código'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(PromoterItem promoter) async {
    final nuevoEstado = promoter.isActivo ? 'SUSPENDIDO' : 'ACTIVO';
    final accion = promoter.isActivo ? 'suspender' : 'reactivar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${promoter.isActivo ? 'Suspender' : 'Reactivar'} Promotor'),
        content: Text('¿Seguro que deseas $accion la cuenta de "${promoter.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: promoter.isActivo ? FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(promoter.isActivo ? 'Suspender' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _invitationsApi.updatePromoterStatus(promoter.id, nuevoEstado);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cuenta de promotor actualizada a $nuevoEstado.')),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthSession.instance.isAdmin;
    final titleText = isAdmin
        ? 'Red Departamental de Promotores (SILAIS Managua)'
        : 'Red de Promotores · ${AuthSession.instance.healthCenterName ?? 'Centro de Salud'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, maxLines: 2, softWrap: true),
        actions: [
          IconButton(
            tooltip: 'Guía y Tutorial',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => RoleTutorialDialog.show(context, initialRole: AuthSession.instance.role),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInviteModal,
        backgroundColor: BiomarkColors.green,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Acreditar Promotor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center, softWrap: true),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _load, child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    )
                  : _promoters.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey),
                                const SizedBox(height: 14),
                                Text(
                                  isAdmin
                                      ? 'Aún no hay promotores registrados en la red territorial de Managua.'
                                      : 'Aún no hay promotores registrados en tu centro de salud.',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Toca "Acreditar Promotor" para generar un código oficial de acceso.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: _openInviteModal,
                                  icon: const Icon(Icons.person_add_rounded),
                                  label: const Text('Acreditar Promotor'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: _promoters.length,
                          itemBuilder: (ctx, index) {
                            final p = _promoters[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.isActivo
                                      ? BiomarkColors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: p.isActivo ? BiomarkColors.green : Colors.red,
                                  ),
                                ),
                                title: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.w700), softWrap: true),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(p.email, softWrap: true),
                                    if (p.centroSaludNombre != null && p.centroSaludNombre!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: BiomarkColors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.centroSaludNombre!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: BiomarkColors.blue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: p.isActivo
                                            ? BiomarkColors.green.withValues(alpha: 0.12)
                                            : Colors.red.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.estadoCuenta,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: p.isActivo ? BiomarkColors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: p.isActivo ? 'Suspender acceso' : 'Reactivar acceso',
                                      icon: Icon(
                                        p.isActivo ? Icons.block_rounded : Icons.check_circle_rounded,
                                        size: 20,
                                        color: p.isActivo ? Colors.red : BiomarkColors.green,
                                      ),
                                      onPressed: () => _toggleStatus(p),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

