import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../biomark_brand.dart';
import '../../gis/data/gis_api.dart';
import '../../gis/domain/health_center.dart';
import '../data/invitations_api.dart';
import '../promoter_screens.dart';
import '../recommendations_management_screen.dart';

/// Pantalla de mando institucional para la Dirección Departamental SILAIS Managua.
/// Permite monitoreo macroepidemiológico, acreditación formal de personal de salud,
/// supervisión de la red de promotores comunitarios y triaje de reportes CCM.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onOpenMap});

  final VoidCallback? onOpenMap;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _promoterApi = PromoterApi();
  final _invitationsApi = InvitationsApi();
  final _gisApi = GisApi();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const {};
  List<CommunityReportItem> _allReports = const [];
  List<HealthCenter> _healthCenters = const [];

  String _filter = 'TODOS'; // 'TODOS', 'ROJO', 'PENDIENTE', 'VALIDADO'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _promoterApi.dispose();
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
      final results = await Future.wait([
        _promoterApi.statistics(),
        _promoterApi.reports(),
        _gisApi.fetchAllCenters().catchError((_) => <HealthCenter>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _allReports = results[1] as List<CommunityReportItem>;
        _healthCenters = results[2] as List<HealthCenter>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  List<CommunityReportItem> get _filteredReports {
    if (_filter == 'ROJO') {
      return _allReports.where((r) => r.clasificacionCcm == 'ROJO').toList();
    } else if (_filter == 'PENDIENTE') {
      return _allReports.where((r) => r.status == 'PENDIENTE_VALIDACION').toList();
    } else if (_filter == 'VALIDADO') {
      return _allReports.where((r) => r.status == 'VALIDADO').toList();
    }
    return _allReports;
  }

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

  Future<void> _showAccreditationDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => _AccreditationDialog(
        initialCenters: _healthCenters,
        fallbackCenters: _fallbackCenters,
        invitationsApi: _invitationsApi,
        gisApi: _gisApi,
      ),
    );

    if (result != null) {
      _load();
      if (result is String && result.isNotEmpty) {
        _showGeneratedTokenDialog(result);
      }
    }
  }

  void _showGeneratedTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: BiomarkColors.green, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Código de Acreditación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comparte este código oficial con el profesional o brigadista para que active su rol institucional. Puedes enviárselo por WhatsApp, SMS desde tu celular o en persona:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: BiomarkColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: SelectableText(
                  token,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: BiomarkColors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                      'Listo para entrega directa. La persona se registra en la app e ingresa este código.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: BiomarkColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Vigencia: 7 días · Un solo uso', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
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

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    try {
      await _promoterApi.updateReport(reportId, newStatus);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'VALIDADO'
                  ? 'Reporte validado formalmente por SILAIS Managua.'
                  : 'Reporte descartado.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = (_stats['por_estado'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final redReports = _allReports.where((r) => r.clasificacionCcm == 'ROJO').toList();
    final filtered = _filteredReports;

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // 1. Cabecera Institucional SILAIS Managua
              _buildInstitutionalHeader(),
              const SizedBox(height: 16),

              // 2. Acciones de Administración y Supervisión
              _buildAdminActionsGrid(),
              const SizedBox(height: 18),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                      IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (_loading) const LinearProgressIndicator(),

              // 3. Tarjetas KPI Macroepidemiológicos
              _buildKpiGrid(breakdown, redReports.length),
              const SizedBox(height: 20),

              // 4. Banner Alerta Roja CCM si existen casos graves
              if (redReports.isNotEmpty) ...[
                _buildRedAlertBanner(redReports),
                const SizedBox(height: 20),
              ],

              // 5. Botón de acceso al mapa global
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.onOpenMap,
                icon: const Icon(Icons.map_rounded, color: BiomarkColors.blue),
                label: const Text(
                  'Abrir Mapa Epidemiológico Departamental',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 22),

              // 6. Sección de Reportes y Triaje Territorial
              _buildReportsSectionHeader(),
              const SizedBox(height: 10),

              // Filtros rápidos
              _buildFilterChips(),
              const SizedBox(height: 12),

              if (!_loading && filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text(
                        'No hay reportes que coincidan con el filtro seleccionado.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((report) => _buildAdminReportCard(report)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003875), Color(0xFF0253A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003875).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SILAIS MANAGUA · DIRECCIÓN GENERAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Centro de Comando Departamental',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Supervisión y vigilancia epidemiológica en tiempo real, acreditación de personal de salud y triaje comunitario.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsGrid() {
    return Column(
      children: [
        // Fila 1: Acreditación Institucional
        Card(
          elevation: 0,
          color: BiomarkColors.blue.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: BiomarkColors.blue.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BiomarkColors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acreditar Personal / Emitir Token',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Genera códigos para Trabajadores de Salud y Promotores adscritos a centros.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _showAccreditationDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: BiomarkColors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Acreditar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Fila 2: Supervisión de Promotores y Avisos MINSA
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPromotersScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.supervised_user_circle_rounded, color: BiomarkColors.green, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Red Territorial', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                              Text('Supervisar agentes', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecommendationsManagementScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.health_and_safety_rounded, color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Avisos MINSA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                              Text('Guías oficiales', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> breakdown, int redCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Casos observados',
                value: '${_stats['total_casos'] ?? 0}',
                color: BiomarkColors.blue,
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'Críticos (ROJO)',
                value: '$redCount',
                color: const Color(0xFFEF4444),
                icon: Icons.emergency_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Validados MINSA',
                value: '${breakdown['VALIDADO'] ?? 0}',
                color: BiomarkColors.green,
                icon: Icons.verified_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'Pendientes revisión',
                value: '${breakdown['PENDIENTE_VALIDACION'] ?? 0}',
                color: const Color(0xFFF59E0B),
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedAlertBanner(List<CommunityReportItem> redReports) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TRIAGE CCM CRÍTICO: ${redReports.length} ${redReports.length == 1 ? 'CASO ROJO' : 'CASOS ROJOS'}',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Se han detectado señales de peligro epidemiológico o dificultad respiratoria grave que requieren transferencia y atención médica prioritaria.',
            style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11.5, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.list_alt_rounded, color: BiomarkColors.blue, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Reportes Epidemiológicos y Comunitarios',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Total: ${_allReports.length}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Todos (${_allReports.length})', 'TODOS'),
          const SizedBox(width: 8),
          _filterChip(
            'Alto Riesgo ROJO (${_allReports.where((r) => r.clasificacionCcm == 'ROJO').length})',
            'ROJO',
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          _filterChip(
            'Pendientes (${_allReports.where((r) => r.status == 'PENDIENTE_VALIDACION').length})',
            'PENDIENTE',
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'Validados (${_allReports.where((r) => r.status == 'VALIDADO').length})',
            'VALIDADO',
            color: BiomarkColors.green,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, {Color? color}) {
    final selected = _filter == value;
    final activeColor = color ?? BiomarkColors.blue;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: activeColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: selected ? activeColor : Theme.of(context).colorScheme.outlineVariant,
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildAdminReportCard(CommunityReportItem report) {
    final isRed = report.clasificacionCcm == 'ROJO';
    final isYellow = report.clasificacionCcm == 'AMARILLO';
    final Color ccmColor = isRed
        ? const Color(0xFFEF4444)
        : (isYellow ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRed
            ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
            : BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Triaje CCM y Centro de Salud asignado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ccmColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ccmColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRed ? Icons.warning_amber_rounded : Icons.health_and_safety_rounded,
                        size: 13,
                        color: ccmColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CCM: ${report.clasificacionCcm}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: ccmColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (report.centroSaludNombre != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Fila 2: Enfermedad y Casos
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.tipoEnfermedad ?? 'Reporte de Salud',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${report.cases} ${report.cases == 1 ? 'caso' : 'casos'} · ${report.status}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: report.status == 'VALIDADO'
                          ? BiomarkColors.green
                          : (report.status == 'DESCARTADO' ? Colors.grey : Colors.orange),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Ubicación exacta si existe
            if (report.direccionExacta != null && report.direccionExacta!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_rounded, size: 14, color: BiomarkColors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.direccionExacta!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Descripción
            Text(report.description, style: const TextStyle(fontSize: 12.5, height: 1.3)),

            // Datos del informante si existen
            if (report.contactoReportante != null && report.contactoReportante!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Contacto: ${report.contactoReportante} ${report.reporterName != null ? "(${report.reporterName})" : ""}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Acciones de validación institucional
            if (report.status == 'PENDIENTE_VALIDACION') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateReportStatus(report.id, 'DESCARTADO'),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Descartar', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateReportStatus(report.id, 'VALIDADO'),
                      style: FilledButton.styleFrom(backgroundColor: BiomarkColors.green),
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('Validar MINSA', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Diálogo modal con gestión de ciclo de vida seguro y adaptabilidad para teclados virtuales.
class _AccreditationDialog extends StatefulWidget {
  const _AccreditationDialog({
    required this.initialCenters,
    required this.fallbackCenters,
    required this.invitationsApi,
    required this.gisApi,
  });

  final List<HealthCenter> initialCenters;
  final List<HealthCenter> fallbackCenters;
  final InvitationsApi invitationsApi;
  final GisApi gisApi;

  @override
  State<_AccreditationDialog> createState() => _AccreditationDialogState();
}

class _AccreditationDialogState extends State<_AccreditationDialog> {
  late final TextEditingController _searchCenterCtrl;
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'TRABAJADOR_SALUD';
  HealthCenter? _selectedCenter;
  String? _centerError;
  bool _generating = false;
  late List<HealthCenter> _centers;

  @override
  void initState() {
    super.initState();
    _searchCenterCtrl = TextEditingController();
    _centers = widget.initialCenters.isNotEmpty ? widget.initialCenters : widget.fallbackCenters;
    if (widget.initialCenters.isEmpty) {
      widget.gisApi.fetchAllCenters().then((loaded) {
        if (mounted && loaded.isNotEmpty) {
          setState(() => _centers = loaded);
        }
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _searchCenterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCenter == null) {
      setState(() => _centerError = 'Debes seleccionar un centro de salud de la lista.');
      return;
    }

    setState(() => _generating = true);

    try {
      final Map<String, dynamic> res;
      if (_selectedRole == 'TRABAJADOR_SALUD') {
        res = await widget.invitationsApi.createHealthWorkerInvitation(
          centroSaludId: _selectedCenter!.id,
        );
      } else {
        res = await widget.invitationsApi.createPromoterInvitation(
          centroSaludId: _selectedCenter!.id,
        );
      }

      if (!mounted) return;
      final invMap = res['invitacion'] is Map<String, dynamic> ? res['invitacion'] as Map<String, dynamic> : null;
      final token = (invMap?['token'] ?? res['token'] ?? '') as String;
      Navigator.pop(context, token.isNotEmpty ? token : true);
    } catch (err) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$err'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCenterCtrl.text.trim().toLowerCase();
    final matches = query.isEmpty
        ? _centers.take(20).toList()
        : _centers.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.address.toLowerCase().contains(query) ||
                c.type.toLowerCase().contains(query);
          }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BiomarkColors.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: BiomarkColors.blue, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Acreditar Personal SILAIS',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Genera un código oficial de activación para incorporar personal calificado a la red de salud.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 16),

                // 1. Selector de Rol
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol institucional a otorgar *',
                    prefixIcon: Icon(Icons.badge_rounded),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TRABAJADOR_SALUD',
                      child: Text('Personal de Salud (Médico / Enfermero)'),
                    ),
                    DropdownMenuItem(
                      value: 'PROMOTOR',
                      child: Text('Promotor de Salud Comunitario'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Selector de Centro de Salud
                if (_selectedCenter == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 16, color: BiomarkColors.blue),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Centro de Salud de Adscripción *',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_centers.length} en BD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchCenterCtrl,
                    decoration: InputDecoration(
                      hintText: 'Filtrar por nombre o barrio...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      suffixIcon: _searchCenterCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCenterCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() => _centerError = null),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _centerError != null
                            ? Colors.red
                            : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: matches.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_off_rounded, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No se encontró ningún centro coincidente.',
                                      style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              itemCount: matches.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 40),
                              itemBuilder: (context, idx) {
                                final center = matches[idx];
                                final isCS = center.type == 'CENTRO_SALUD';
                                final isHosp = center.type == 'HOSPITAL';
                                final color = isHosp
                                    ? const Color(0xFFDC2626)
                                    : (isCS ? BiomarkColors.blue : BiomarkColors.green);

                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    leading: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isHosp
                                            ? Icons.local_hospital_rounded
                                            : (isCS ? Icons.medical_services_rounded : Icons.health_and_safety_rounded),
                                        size: 15,
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      center.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      center.address.isNotEmpty ? center.address : 'Managua, Nicaragua',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 18,
                                      color: BiomarkColors.blue,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedCenter = center;
                                        _centerError = null;
                                        _searchCenterCtrl.clear();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  if (_centerError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _centerError!,
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ] else ...[
                  // Centro Seleccionado
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BiomarkColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BiomarkColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: BiomarkColors.green, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Centro Verificado:',
                                style: TextStyle(
                                  color: BiomarkColors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _selectedCenter!.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _selectedCenter!.address.isNotEmpty ? _selectedCenter!.address : 'Managua',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedCenter = null),
                          icon: const Icon(Icons.sync_rounded, size: 18, color: BiomarkColors.green),
                          tooltip: 'Cambiar centro',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _generating ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _generating ? null : _submit,
                      child: Text(_generating ? 'Generando...' : 'Acreditar y Emitir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
