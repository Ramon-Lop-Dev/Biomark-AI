import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/notifications/push_notifications_service.dart';
import 'notifications_inbox_screen.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _todasActivas = true;
  bool _modoSilencioso = false;
  TimeOfDay _inicioSilencio = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _finSilencio = const TimeOfDay(hour: 7, minute: 0);
  bool _guardando = false;

  static const _pushEnabledKey = PushNotificationsService.pushEnabledKey;
  static const _silentModeKey = 'notifications_silent_mode';
  static const _silentStartKey = 'notifications_silent_start';
  static const _silentEndKey = 'notifications_silent_end';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _todasActivas = preferences.getBool(_pushEnabledKey) ?? true;
      _modoSilencioso = preferences.getBool(_silentModeKey) ?? false;
      _inicioSilencio = _timeFromMinutes(
        preferences.getInt(_silentStartKey) ?? 22 * 60,
      );
      _finSilencio = _timeFromMinutes(
        preferences.getInt(_silentEndKey) ?? 7 * 60,
      );
    });
  }

  Future<void> _alternarTodas(bool valor) async {
    if (_guardando) return;
    final previous = _todasActivas;
    setState(() {
      _todasActivas = valor;
      _guardando = true;
    });
    try {
      if (valor) {
        final enabled = await PushNotificationsService.instance
            .enableForCurrentUser();
        if (!enabled) {
          throw Exception('No se concedió el permiso de notificaciones.');
        }
      } else {
        await PushNotificationsService.instance.disableForCurrentUser();
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_pushEnabledKey, valor);
    } catch (error) {
      if (!mounted) return;
      setState(() => _todasActivas = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar el permiso: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegirHora({required bool esInicio}) async {
    final horaActual = esInicio ? _inicioSilencio : _finSilencio;
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: horaActual,
    );
    if (seleccionada == null) return;
    setState(() {
      if (esInicio) {
        _inicioSilencio = seleccionada;
      } else {
        _finSilencio = seleccionada;
      }
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      esInicio ? _silentStartKey : _silentEndKey,
      seleccionada.hour * 60 + seleccionada.minute,
    );
  }

  TimeOfDay _timeFromMinutes(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  Future<void> _alternarModoSilencioso(bool valor) async {
    setState(() => _modoSilencioso = valor);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_silentModeKey, valor);
  }

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final m = hora.minute.toString().padLeft(2, '0');
    final periodo = hora.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $periodo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Notificaciones',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ver avisos',
            icon: const Icon(Icons.mark_email_unread_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildTarjeta(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: BiomarkColors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inbox_rounded, color: BiomarkColors.blue),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bandeja de Avisos y Alertas',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ver alertas MINSA, recordatorios y notificaciones',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTarjeta(
                  child: _buildFilaSwitch(
                    icono: Icons.notifications_active_rounded,
                    titulo: 'Recibir todas las notificaciones',
                    subtitulo: 'Activa o desactiva todo de una vez',
                    valor: _todasActivas,
                    onChanged: _alternarTodas,
                    destacado: true,
                  ),
                ),
                const SizedBox(height: 22),
                _buildSeccionTitulo('Horario'),
                const SizedBox(height: 10),
                _buildTarjeta(
                  child: Column(
                    children: [
                      _buildFilaSwitch(
                        icono: Icons.bedtime_outlined,
                        titulo: 'Modo silencioso',
                        subtitulo: 'No recibir notificaciones en un rango de horas',
                        valor: _modoSilencioso,
                        onChanged: _todasActivas ? _alternarModoSilencioso : null,
                      ),
                      if (_modoSilencioso) ...[
                        Divider(height: 24, color: dividerColor),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBotonHora(
                                etiqueta: 'Desde',
                                hora: _inicioSilencio,
                                onTap: () => _elegirHora(esInicio: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBotonHora(
                                etiqueta: 'Hasta',
                                hora: _finSilencio,
                                onTap: () => _elegirHora(esInicio: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilaSwitch({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool>? onChanged,
    bool destacado = false,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final habilitado = destacado || _todasActivas;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (habilitado ? BiomarkColors.blue : theme.dividerColor)
                .withValues(alpha: .12),
          ),
          child: Icon(
            icono,
            size: 17,
            color: habilitado ? BiomarkColors.blue : onSurface.withValues(alpha: .4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: habilitado
                      ? onSurface
                      : onSurface.withValues(alpha: .4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: .5),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          onChanged: habilitado ? onChanged : null,
          activeThumbColor: BiomarkColors.green,
        ),
      ],
    );
  }

  Widget _buildBotonHora({
    required String etiqueta,
    required TimeOfDay hora,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 11,
                color: onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatearHora(hora),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
      ),
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .25 : .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
