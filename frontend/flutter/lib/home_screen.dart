// Pantalla de inicio (Home) de Biomark AI.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'survey_service.dart';
import 'health_history.dart';
import 'features/gis/presentation/gis_map_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/reminders/presentation/reminders_screen.dart';

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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dosisTomadas = 3;
  static const _dosisTotal = 5;

  // Placeholder mientras se conecta la base de datos.
  // Cuando tengas tu backend listo, _cargarNombreUsuario() lo reemplaza
  // con el nombre real (ver initState más abajo).
  final String _nombreUsuario = 'Familia';

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    // TODO: aquí va tu lógica real de base de datos (Firebase, API REST, etc.)
    // Ejemplo:
    // final usuario = await MiServicio.obtenerUsuarioActual();
    // if (mounted) setState(() => _nombreUsuario = usuario.nombre);
  }

  void _addDose() {
    if (_dosisTomadas < _dosisTotal) setState(() => _dosisTomadas++);
    _showMessage(
      _dosisTomadas == _dosisTotal
          ? 'Meta completada.'
          : 'Dosis registrada: $_dosisTomadas/$_dosisTotal',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '¡Hola, $_nombreUsuario!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: BiomarkColors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildMedicationGoal(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildFeatureButton(
                'Conversa con\nBiomark',
                Icons.health_and_safety_rounded,
                BiomarkColors.blue,
                () => SurveyService.abrirChat(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFeatureButton(
                'Mapa de\nSalud',
                Icons.map_outlined,
                BiomarkColors.green,
                () => Navigator.push(
                  context,
                  _FadeSlidePageRoute(builder: (_) => const GisMapScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildFeatureButton(
                'Mis\nAntecedentes',
                Icons.folder_shared_outlined,
                BiomarkColors.green,
                () => Navigator.push(
                  context,
                  _FadeSlidePageRoute(builder: (_) => const AntecedentesScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFeatureButton(
                'Mi\nProgreso',
                Icons.show_chart_rounded,
                BiomarkColors.blue,
                () => Navigator.push(
                  context,
                  _FadeSlidePageRoute(builder: (_) => const ProgressScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: BiomarkColors.blue,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Recordatorios Inteligentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: BiomarkColors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReminder(
          'Jornada de Vacunación',
          'Centro de Salud Villa Libertad',
          'Hoy',
          '9:00 AM',
          Icons.vaccines_rounded,
          BiomarkColors.green,
          () => Navigator.push(
            context,
            _FadeSlidePageRoute(builder: (_) => const RemindersScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildReminder(
          'Cita Médica',
          'Control mensual',
          'Mañana',
          '2:30 PM',
          Icons.medical_services_outlined,
          BiomarkColors.blue,
          () => Navigator.push(
            context,
            _FadeSlidePageRoute(builder: (_) => const RemindersScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationGoal() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BiomarkColors.blue.withValues(alpha: .10),
            BiomarkColors.blue.withValues(alpha: .04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meta de Salud de Hoy',
                style: TextStyle(
                  color: BiomarkColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _addDose,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Registrar dosis',
              ),
            ],
          ),
          const Text(
            'Toma de medicinas',
            style: TextStyle(color: BiomarkColors.black, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '$_dosisTomadas/$_dosisTotal Dosis',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _dosisTomadas / _dosisTotal,
              minHeight: 8,
              valueColor: const AlwaysStoppedAnimation(BiomarkColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: .15),
        highlightColor: color.withValues(alpha: .08),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: .72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: BiomarkColors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminder(
    String title,
    String subtitle,
    String day,
    String time,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => _showMessage('$title: $day · $time'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(time, style: const TextStyle(fontSize: 11.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}