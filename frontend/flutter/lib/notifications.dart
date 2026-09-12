// Pantalla "Notificaciones" — Biomark AI
//
// Interruptor maestro + categorías específicas. Las categorías se
// desactivan visualmente (pero conservan su valor) cuando el maestro
// está apagado, para que el usuario no pierda su configuración fina.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // TODO: cargar estos valores reales desde SharedPreferences o tu
  // backend en initState, y guardarlos cada vez que cambien.
  bool _todasActivas = true;

  bool _jornadas = true;
  bool _medicamentos = true;
  bool _recomendacionesIA = true;
  bool _actualizacionesAntecedentes = true;
  bool _soporte = true;

  bool _modoSilencioso = false;
  TimeOfDay _inicioSilencio = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _finSilencio = const TimeOfDay(hour: 7, minute: 0);

  void _alternarTodas(bool valor) {
    setState(() {
      _todasActivas = valor;
      // TODO: persistir. Nota: no forzamos las categorías individuales
      // a `valor` para no perder la configuración fina del usuario;
      // solo controlamos si el sistema puede enviar notificaciones.
    });
  }

  void _alternarCategoria(void Function(bool) setter, bool valorActual) {
    if (!_todasActivas) return; // bloqueado hasta activar el maestro
    setState(() => setter(!valorActual));
    // TODO: persistir el cambio.
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
    // TODO: persistir el cambio.
  }

  String _formatearHora(TimeOfDay hora) {
    final h = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final m = hora.minute.toString().padLeft(2, '0');
    final periodo = hora.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $periodo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BiomarkColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: BiomarkColors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
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
            _buildSeccionTitulo('Tipos de notificación'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                children: [
                  _buildFilaSwitch(
                    icono: Icons.event_available_rounded,
                    titulo: 'Jornadas y citas médicas',
                    subtitulo: 'Recordatorios antes de una jornada agendada',
                    valor: _jornadas,
                    onChanged: (_) => _alternarCategoria(
                      (v) => _jornadas = v,
                      _jornadas,
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.medication_liquid_rounded,
                    titulo: 'Recordatorio de medicamentos',
                    subtitulo: 'Aviso a la hora de tomar tus dosis',
                    valor: _medicamentos,
                    onChanged: (_) => _alternarCategoria(
                      (v) => _medicamentos = v,
                      _medicamentos,
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.psychology_alt_rounded,
                    titulo: 'Recomendaciones de Biomark AI',
                    subtitulo: 'Consejos de salud según tus antecedentes',
                    valor: _recomendacionesIA,
                    onChanged: (_) => _alternarCategoria(
                      (v) => _recomendacionesIA = v,
                      _recomendacionesIA,
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.folder_shared_outlined,
                    titulo: 'Actualizaciones de antecedentes',
                    subtitulo: 'Cuando tú o un familiar edita información médica',
                    valor: _actualizacionesAntecedentes,
                    onChanged: (_) => _alternarCategoria(
                      (v) => _actualizacionesAntecedentes = v,
                      _actualizacionesAntecedentes,
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.support_agent_rounded,
                    titulo: 'Mensajes de soporte',
                    subtitulo: 'Respuestas del centro de ayuda',
                    valor: _soporte,
                    onChanged: (_) => _alternarCategoria(
                      (v) => _soporte = v,
                      _soporte,
                    ),
                  ),
                ],
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
                    onChanged: (v) {
                      if (!_todasActivas) return;
                      setState(() => _modoSilencioso = v);
                      // TODO: persistir.
                    },
                  ),
                  if (_modoSilencioso) ...[
                    const Divider(height: 24, color: Color(0xFFEFEFF3)),
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
    );
  }

  Widget _buildFilaSwitch({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
    bool destacado = false,
  }) {
    final habilitado = destacado || _todasActivas;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (habilitado ? BiomarkColors.blue : const Color(0xFF9C9CA6))
                .withValues(alpha: .12),
          ),
          child: Icon(
            icono,
            size: 17,
            color: habilitado ? BiomarkColors.blue : const Color(0xFF9C9CA6),
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
                  color: habilitado ? BiomarkColors.black : const Color(0xFF9C9CA6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9C9CA6)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9C9CA6)),
            ),
            const SizedBox(height: 2),
            Text(
              _formatearHora(hora),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BiomarkColors.black,
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
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7A7A85),
      ),
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}