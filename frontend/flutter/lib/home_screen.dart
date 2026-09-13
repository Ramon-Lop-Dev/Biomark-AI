// Pantalla de inicio (Home) de Biomark AI.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'biomark_brand.dart';
import 'features/gis/presentation/gis_map_screen.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'core/profile/user_profile_api.dart';

/// Transición personalizada (duplicada para evitar circular imports)
class _FadeSlidePageRoute<T> extends MaterialPageRoute<T> {
  _FadeSlidePageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenMap});

  final VoidCallback? onOpenMap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = 'usuario';
  int _totalCases = 0;
  int _validatedReports = 0;
  List<_CommunitySignal> _signals = const [];
  List<_CommunityEvent> _events = const [];
  bool _loadingCommunity = true;
  String? _communityError;

  void _openMap() {
    if (widget.onOpenMap != null) {
      widget.onOpenMap!();
      return;
    }
    Navigator.push(context, _FadeSlidePageRoute(builder: (_) => const GisMapScreen()));
  }

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _cargarPanoramaComunitario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final profile = await UserProfileApi.fetch();
      if (!mounted) return;
      if (profile != null) {
        final firstName = profile.displayName.split(' ').first;
        setState(() => _nombreUsuario = firstName);
      }
    } catch (_) {}
  }

  Future<void> _cargarPanoramaComunitario() async {
    if (mounted) {
      setState(() {
        _loadingCommunity = true;
        _communityError = null;
      });
    }
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final responses = await Future.wait([
        http.get(Uri.parse('$base/api/community/statistics'), headers: headers),
        http.get(Uri.parse('$base/api/community/heatmap'), headers: headers),
        http.get(Uri.parse('$base/api/community/events')),
      ]);
      final statistics = responses[0].statusCode >= 200 && responses[0].statusCode < 300
          ? jsonDecode(responses[0].body) as Map<String, dynamic>
          : <String, dynamic>{};
      final heatmap = responses[1].statusCode >= 200 && responses[1].statusCode < 300
          ? jsonDecode(responses[1].body) as List<dynamic>
          : const <dynamic>[];
      final events = responses[2].statusCode >= 200 && responses[2].statusCode < 300
          ? jsonDecode(responses[2].body) as List<dynamic>
          : const <dynamic>[];
      final signals = heatmap.whereType<Map<String, dynamic>>().map(_CommunitySignal.fromJson).toList();
      final upcomingEvents = events
          .whereType<Map<String, dynamic>>()
          .map(_CommunityEvent.fromJson)
          .where((event) => event.date.isAfter(DateTime.now()))
          .take(4)
          .toList();
      if (!mounted) return;
      setState(() {
        _totalCases = (statistics['total_casos'] as num?)?.toInt() ?? signals.fold(0, (total, signal) => total + signal.cases);
        _validatedReports = signals.length;
        _signals = signals;
        _events = upcomingEvents;
        _loadingCommunity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCommunity = false;
        _communityError = 'No pudimos actualizar el panorama comunitario.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '¡Hola, $_nombreUsuario!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar panorama',
              onPressed: _loadingCommunity ? null : _cargarPanoramaComunitario,
              icon: Icon(_loadingCommunity ? Icons.sync_rounded : Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Panorama de salud comunitaria',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildCommunitySummary(),
        const SizedBox(height: 24),
        _sectionTitle(
          Icons.campaign_rounded,
          'Señales de la comunidad',
          'Reportes validados y agrupados por zona aproximada',
        ),
        const SizedBox(height: 10),
        if (_communityError != null)
          _buildEmptyState(_communityError!, Icons.cloud_off_rounded)
        else if (_loadingCommunity)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_signals.isEmpty)
          _buildEmptyState('Todavía no hay reportes validados para mostrar.', Icons.verified_outlined)
        else
          ..._signals.take(5).map(_buildSignalCard),
        const SizedBox(height: 24),
        _sectionTitle(
          Icons.event_available_rounded,
          'Próximas jornadas',
          'Actividades comunitarias cercanas',
        ),
        const SizedBox(height: 10),
        if (_events.isEmpty)
          _buildEmptyState('No hay jornadas próximas publicadas.', Icons.event_busy_rounded)
        else
          ..._events.map(_buildEventCard),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Aportar un reporte desde el mapa'),
          style: OutlinedButton.styleFrom(
            foregroundColor: BiomarkColors.green,
            side: const BorderSide(color: BiomarkColors.green),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Las señales mostradas fueron revisadas antes de aparecer en este panorama.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCommunitySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BiomarkColors.green.withValues(alpha: .14),
            BiomarkColors.blue.withValues(alpha: .06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: BiomarkColors.green.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: BiomarkColors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actividad comunitaria', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                Text(
                  '$_validatedReports zonas con reportes validados · $_totalCases casos observados',
                  style: TextStyle(fontSize: 12.5, height: 1.3, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BiomarkColors.blue, size: 21),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  Widget _buildSignalCard(_CommunitySignal signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.verified_rounded, color: BiomarkColors.green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${signal.cases} ${signal.cases == 1 ? 'caso' : 'casos'} reportados en un área comunitaria aproximada.',
              style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildEventCard(_CommunityEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE8EEF9),
            child: Icon(Icons.event_available_rounded, color: BiomarkColors.blue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                Text('${event.location} · ${_formatEventDate(event.date)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) => '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _CommunitySignal {
  final int cases;

  const _CommunitySignal({required this.cases});

  factory _CommunitySignal.fromJson(Map<String, dynamic> json) => _CommunitySignal(
        cases: (json['cantidad_casos'] as num?)?.toInt() ?? 0,
      );
}

class _CommunityEvent {
  final String title;
  final String location;
  final DateTime date;

  const _CommunityEvent({required this.title, required this.location, required this.date});

  factory _CommunityEvent.fromJson(Map<String, dynamic> json) => _CommunityEvent(
        title: '${json['titulo'] ?? 'Jornada comunitaria'}',
        location: '${json['ubicacion'] ?? 'Ubicación por confirmar'}',
        date: DateTime.tryParse('${json['fecha_evento'] ?? ''}') ?? DateTime.now(),
      );
}