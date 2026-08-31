// Compone el inicio de la app, su navegación y el acceso a las funciones principales.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'chat_api.dart';
import 'features/chat/presentation/chat_screen.dart';

// ============================================================
// PALETA DE COLORES
// ============================================================
class AppColors {
  static const bg = BiomarkColors.white;
  static const cardBg = BiomarkColors.white;
  static const blue = BiomarkColors.blue;
  static const blueDark = BiomarkColors.blue;
  static const green = BiomarkColors.green;
  static const greenLight = BiomarkColors.green;
  static const brown = BiomarkColors.green;
  static const brownLight = BiomarkColors.green;
  static const purple = BiomarkColors.blue;
  static const purpleLight = BiomarkColors.blue;
  static const pink = BiomarkColors.green;
  static const textDark = BiomarkColors.black;
  static const textGrey = BiomarkColors.black;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 1;

  final List<String> _navLabels = [
    'Inicio',
    'Mejoría',
    'Mapa',
    'Perfil',
  ];
  final List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.location_on_rounded,
    Icons.person_outline_rounded,
  ];

  void _handleNavTap(int index) {
    setState(() => _navIndex = index.clamp(0, _navLabels.length - 1));
  }

  void _openChatBiomark() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  // Progreso de dosis del día
  int _dosisTomadas = 3;
  final int _dosisTotal = 5;

  void _agregarDosis() {
    if (_dosisTomadas < _dosisTotal) {
      setState(() => _dosisTomadas++);
      if (_dosisTomadas == _dosisTotal) {
        _showSnack(
          '¡Meta completada! Todas las dosis de hoy fueron tomadas 🎉',
        );
      } else {
        _showSnack('Dosis registrada: $_dosisTomadas/$_dosisTotal');
      }
    } else {
      _showSnack('Ya completaste todas las dosis de hoy');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openFeature(String titulo, IconData icon, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FeatureDetailScreen(titulo: titulo, icon: icon, color: color),
      ),
    );
  }

  void _openReminderDetail({
    required String titulo,
    required String lugar,
    required String cuando,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSheet(
        titulo: titulo,
        lugar: lugar,
        cuando: cuando,
        color: color,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildInicioBody(),
      _buildProgressBody(),
      const _PlaceholderBody(titulo: 'Mapa', icon: Icons.location_on_rounded),
      const _PlaceholderBody(
        titulo: 'Perfil',
        icon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: _navIndex == 1 ? _buildEvolutionAppBar() : _buildAppBar(),
      body: SafeArea(
        top: _navIndex == 1,
        child: pages[_navIndex.clamp(0, pages.length - 1)],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ------------------------------------------------------------
  // APP BAR
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/branding/Logo_Horizontal.png',
            width: 140,
            height: 40,
            fit: BoxFit.contain,
            semanticLabel: 'Biomark AI',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => _showSnack('No tienes notificaciones nuevas'),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  PreferredSizeWidget _buildEvolutionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9FC),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/branding/Icono.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            'Evolucion',
            style: TextStyle(
              color: BiomarkColors.green,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/branding/Icono.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CUERPO PANTALLA INICIO
  // ------------------------------------------------------------
  Widget _buildInicioBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          '¡Hola, Familia!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetaCard(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildGridButton(
                titulo: 'Conversa con\nBiomark',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.blue,
                onTap: _openChatBiomark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGridButton(
                titulo: 'Mapa de\nSalud',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.green,
                onTap: () => _openFeature(
                  'Mapa de Salud',
                  Icons.add_circle_outline_rounded,
                  AppColors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildGridButton(
                titulo: 'Mis\nAntecedentes',
                icon: Icons.folder_shared_outlined,
                color: AppColors.brown,
                onTap: () => _openFeature(
                  'Mis Antecedentes',
                  Icons.folder_shared_outlined,
                  AppColors.brown,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGridButton(
                titulo: 'Mi\nProgreso',
                icon: Icons.show_chart_rounded,
                color: AppColors.purple,
                onTap: () => _openFeature(
                  'Mi Progreso',
                  Icons.show_chart_rounded,
                  AppColors.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Icon(
              Icons.notifications_active_outlined,
              color: AppColors.blueDark,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Recordatorios Inteligentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReminderCard(
          icon: Icons.vaccines_rounded,
          iconColor: AppColors.pink,
          titulo: 'Jornada de Vacunación',
          subtitulo: 'Centro de Salud Villa Libertad',
          etiqueta: 'Hoy',
          hora: '9:00 AM',
        ),
        const SizedBox(height: 12),
        _buildReminderCard(
          icon: Icons.medical_services_outlined,
          iconColor: AppColors.green,
          titulo: 'Cita Médica',
          subtitulo: 'Control mensual',
          etiqueta: 'Mañana',
          hora: '2:30 PM',
        ),
      ],
    );
  }

  Widget _buildMetaCard() {
    final progreso = _dosisTomadas / _dosisTotal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withValues(alpha: 0.10),
            AppColors.blue.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
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
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: _agregarDosis,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Toma de medicinas',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_dosisTomadas/$_dosisTotal Dosis',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton({
    required String titulo,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required Color iconColor,
    required String titulo,
    required String subtitulo,
    required String etiqueta,
    required String hora,
  }) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openReminderDetail(
          titulo: titulo,
          lugar: subtitulo,
          cuando: '$etiqueta · $hora',
          color: iconColor,
          icon: icon,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: iconColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    etiqueta,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hora,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBody() {
    const trendValues = [52, 58, 68, 64, 78, 82, 92];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEBF9EE), Color(0xFFEAF3FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tu mejora',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2D20),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Últimos 7 días',
                        style: TextStyle(
                          color: Color(0xFF2C7A32),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '78%',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E3B22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAF6E0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Color(0xFF1E8E3E),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '+14%',
                            style: TextStyle(
                              color: Color(0xFF1E8E3E),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 130,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      trendValues.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: (trendValues[index] / 100) * 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: index == trendValues.length - 1
                                    ? const [Color(0xFF1B8E44), Color(0xFF3CC66A)]
                                    : const [Color(0xFFB6E5BE), Color(0xFF9AD9A6)],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('L', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('M', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('M', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('J', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('V', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('S', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                    Text('D', style: TextStyle(fontSize: 11, color: Color(0xFF5C665E))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hitos de evolución',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1F1C),
            ),
          ),
          const SizedBox(height: 12),
          _buildMilestoneRow(
            title: 'Energía',
            value: 'Alta',
            subtitle: 'Semana actual',
            color: const Color(0xFF14A44D),
          ),
          const SizedBox(height: 10),
          _buildMilestoneRow(
            title: 'Síntomas',
            value: 'Bajo',
            subtitle: 'Reducidos en 3 días',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildMilestoneRow(
            title: 'Seguir',
            value: '7/7',
            subtitle: 'Rutina completada',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riesgo general',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1F1C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bajo. Mantén tu tratamiento y seguimiento.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F6D63),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1F1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C736F),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV — estilo del mockup con barra redondeada y botón central flotante
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
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
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 10,
                      offset: const Offset(-4, -4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(4, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                onTap: _openChatBiomark,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF46AB39), Color(0xFF006E03)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF46AB39).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF9F9FC), width: 4),
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

  Widget _navItem(int i) {
    final selected = _navIndex == i;
    return GestureDetector(
      onTap: () => _handleNavTap(i),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _navIcons[i],
              color: selected ? const Color(0xFF006E03) : const Color(0xFF3F4A3B),
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              _navLabels[i],
              style: TextStyle(
                color: selected ? const Color(0xFF006E03) : const Color(0xFF3F4A3B),
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

// ============================================================
// PANTALLA GENÉRICA DE DETALLE (para los 4 botones del grid)
// ============================================================
class _FeatureDetailScreen extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Color color;

  const _FeatureDetailScreen({
    required this.titulo,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí irá el contenido de esta sección.',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOJA INFERIOR PARA DETALLE DE RECORDATORIO
// ============================================================
class _ReminderSheet extends StatelessWidget {
  final String titulo;
  final String lugar;
  final String cuando;
  final Color color;
  final IconData icon;

  const _ReminderSheet({
    required this.titulo,
    required this.lugar,
    required this.cuando,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lugar,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            cuando,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recordatorio "$titulo" confirmado'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTENIDO PLACEHOLDER PARA LAS OTRAS PESTAÑAS DEL NAV
// ============================================================
class _PlaceholderBody extends StatelessWidget {
  final String titulo;
  final IconData icon;

  const _PlaceholderBody({required this.titulo, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PANTALLA DE CHAT — BIOMARK AI
// ============================================================
class _ChatMessage {
  final String text;
  final bool isUser;
  final String? riskLevel;
  final List<String> sources;

  const _ChatMessage(
    this.text,
    this.isUser, {
    this.riskLevel,
    this.sources = const [],
  });
}

class _BiomarkChatScreen extends StatefulWidget {
  const _BiomarkChatScreen();

  @override
  State<_BiomarkChatScreen> createState() => _BiomarkChatScreenState();
}

class _BiomarkChatScreenState extends State<_BiomarkChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatApi _chatApi;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      '¡Hola! Soy Biomark AI ¿En qué puedo ayudarte hoy con tu salud?',
      false,
    ),
  ];

  bool _escribiendo = false;
  String? _sessionId;
  String? _errorMessage;

  static const _apiUrl = String.fromEnvironment(
    'BIOMARK_API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const _accessToken = String.fromEnvironment('BIOMARK_ACCESS_TOKEN');

  @override
  void initState() {
    super.initState();
    _chatApi = ChatApi(baseUrl: _apiUrl, accessToken: _accessToken);
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _escribiendo) return;

    setState(() {
      _messages.add(_ChatMessage(texto, true));
      _escribiendo = true;
      _errorMessage = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _chatApi.sendMessage(
        message: texto,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = result.sessionId;
        _messages.add(
          _ChatMessage(
            result.reply,
            false,
            riskLevel: result.riskLevel,
            sources: result.sources,
          ),
        );
        _escribiendo = false;
      });
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _escribiendo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No se pudo conectar con Biomark AI. Inténtalo de nuevo.';
        _escribiendo = false;
      });
    }
    _scrollToBottom();
  }

  void _toggleVoice() {
    setState(() {
      _errorMessage =
          'La entrada por voz se conectará mediante el endpoint /api/voice.';
    });
  }

  void _retryMessage() {
    if (_messages.isEmpty) return;
    final lastUserMessage = _messages.lastWhere(
      (message) => message.isUser,
      orElse: () => const _ChatMessage('', true),
    );
    if (lastUserMessage.text.isEmpty) return;
    _controller.text = lastUserMessage.text;
    _enviarMensaje();
  }

  Color _riskColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return BiomarkColors.blue;
      case 'MODERATE':
        return BiomarkColors.green;
      default:
        return BiomarkColors.green;
    }
  }

  String _riskLabel(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'HIGH':
        return 'Riesgo alto';
      case 'CRITICAL':
        return 'Riesgo crítico';
      case 'MODERATE':
        return 'Riesgo moderado';
      default:
        return 'Riesgo bajo';
    }
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: BiomarkColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: BiomarkColors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Biomark AI orienta tu salud, pero no reemplaza el diagnóstico de un profesional. Consulta siempre a tu médico.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BiomarkColors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/branding/Icono.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          semanticLabel: 'Avatar de Biomark AI',
        ),
        const SizedBox(width: 8),
        Text(
          'Biomark AI',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: BiomarkColors.black.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskBadge(_ChatMessage message) {
    if (message.riskLevel == null) return const SizedBox.shrink();
    final color = _riskColor(message.riskLevel);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.health_and_safety_outlined, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            _riskLabel(message.riskLevel),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser ? BiomarkColors.blue : BiomarkColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isUser ? 18 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 18),
        ),
        border: message.isUser
            ? null
            : Border.all(color: BiomarkColors.blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: message.isUser ? BiomarkColors.white : BiomarkColors.black,
            ),
          ),
          if (!message.isUser) _buildRiskBadge(message),
          if (!message.isUser && message.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Fuentes: ${message.sources.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BiomarkColors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
        ],
      ),
    );

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAssistantHeader(),
          const SizedBox(height: 6),
          bubble,
        ],
      ),
    );
  }

  Widget _buildError() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BiomarkColors.white,
        border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: BiomarkColors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: _retryMessage, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_escribiendo,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: 'Describe cómo te sientes...',
                  prefixIcon: const Icon(Icons.photo_camera_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Entrada por voz',
                    onPressed: _escribiendo ? null : _toggleVoice,
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  filled: true,
                  fillColor: BiomarkColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Enviar mensaje',
              onPressed: _escribiendo ? null : _enviarMensaje,
              icon: _escribiendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/branding/Logo_Horizontal.png',
              width: 120,
              height: 36,
              fit: BoxFit.contain,
              semanticLabel: 'Biomark AI',
            ),
            const SizedBox(width: 8),
            Text('Chat', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInfoBar(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              children: [
                ..._messages.map(_buildMessage),
                if (_escribiendo) _buildTypingBubble(),
                _buildError(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: BiomarkColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Analizando...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatApi.dispose();
    super.dispose();
  }
}
