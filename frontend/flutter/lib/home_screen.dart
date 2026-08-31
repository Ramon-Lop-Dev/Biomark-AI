// Shell de Inicio y navegación principal de Biomark AI.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/gis/presentation/gis_map_screen.dart';
import 'features/progress/presentation/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  int _dosisTomadas = 3;
  static const _dosisTotal = 5;

  final _navLabels = const ['Inicio', 'Mejoría', 'Mapa', 'Avisos', 'Perfil'];
  final _navIcons = const [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.location_on_rounded,
    Icons.notifications_rounded,
    Icons.person_outline_rounded,
  ];

  void _handleNavTap(int index) {
    if (index == 4) {
      _showMessage('Perfil estará disponible en la siguiente sección.');
      return;
    }
    setState(() => _navIndex = index);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeBody(),
      const ProgressScreen(),
      const GisMapScreen(),
      const _PlaceholderBody(
        title: 'Avisos',
        icon: Icons.notifications_rounded,
      ),
      const _PlaceholderBody(
        title: 'Perfil',
        icon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: _buildAppBar(),
      body: SafeArea(child: pages[_navIndex]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9FC),
      elevation: 0,
      titleSpacing: 16,
      title: Image.asset(
        'assets/branding/Logo_Horizontal.png',
        width: 140,
        height: 40,
        fit: BoxFit.contain,
        semanticLabel: 'Biomark AI',
      ),
      actions: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: BiomarkColors.black,
          ),
          onPressed: () => _showMessage('No tienes notificaciones nuevas.'),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildHomeBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          '¡Hola, Familia!',
          style: TextStyle(
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
                _openChat,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFeatureButton(
                'Mapa de\nSalud',
                Icons.map_outlined,
                BiomarkColors.green,
                () => _selectTab(2),
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
                () => _showMessage('Antecedentes estará disponible pronto.'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFeatureButton(
                'Mi\nProgreso',
                Icons.show_chart_rounded,
                BiomarkColors.blue,
                () => _selectTab(1),
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
        ),
        const SizedBox(height: 12),
        _buildReminder(
          'Cita Médica',
          'Control mensual',
          'Mañana',
          '2:30 PM',
          Icons.medical_services_outlined,
          BiomarkColors.blue,
        ),
      ],
    );
  }

  void _selectTab(int index) => setState(() => _navIndex = index);

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

  void _addDose() {
    if (_dosisTomadas < _dosisTotal) setState(() => _dosisTomadas++);
    _showMessage(
      _dosisTomadas == _dosisTotal
          ? 'Meta completada.'
          : 'Dosis registrada: $_dosisTomadas/$_dosisTotal',
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
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
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMessage('$title: $day · $time'),
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

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 18,
              right: 18,
              top: 28,
              bottom: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 12,
                      offset: const Offset(4, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _navItem(0)),
                    Expanded(child: _navItem(1)),
                    const SizedBox(width: 62),
                    Expanded(child: _navItem(2)),
                    Expanded(child: _navItem(3)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: _openChat,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF46AB39), Color(0xFF006E03)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFF9F9FC),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BiomarkColors.green.withValues(alpha: .45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final selected = _navIndex == index;
    return GestureDetector(
      onTap: () => _handleNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _navIcons[index],
              color: selected ? BiomarkColors.green : const Color(0xFF3F4A3B),
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              _navLabels[index],
              style: TextStyle(
                color: selected ? BiomarkColors.green : const Color(0xFF3F4A3B),
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderBody({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 54, color: BiomarkColors.black),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
