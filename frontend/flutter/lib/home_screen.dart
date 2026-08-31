import 'package:flutter/material.dart';

// ============================================================
// PALETA DE COLORES
// ============================================================
class AppColors {
  static const bg = Color(0xFFF2F2F5);
  static const cardBg = Colors.white;
  static const blue = Color(0xFF2D6CDF);
  static const blueDark = Color(0xFF1E4FA3);
  static const green = Color(0xFF34A853);
  static const greenLight = Color(0xFFE8F6EC);
  static const brown = Color(0xFF8B5E34);
  static const brownLight = Color(0xFFF3E9DE);
  static const purple = Color(0xFF3A3D66);
  static const purpleLight = Color(0xFFE9E9F5);
  static const pink = Color(0xFFE85D75);
  static const textDark = Color(0xFF1E1E2D);
  static const textGrey = Color(0xFF8A8A9A);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<String> _navLabels = ['Inicio', 'Explorar', 'Historial', 'Perfil'];
  final List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.explore_outlined,
    Icons.history_rounded,
    Icons.person_outline_rounded,
  ];

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
      const _PlaceholderBody(titulo: 'Explorar', icon: Icons.explore_outlined),
      const _PlaceholderBody(titulo: 'Historial', icon: Icons.history_rounded),
      const _PlaceholderBody(
        titulo: 'Perfil',
        icon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _navIndex == 0 ? _buildAppBar() : null,
      body: SafeArea(top: _navIndex != 0, child: pages[_navIndex]),
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Asistente de Salud Nica',
            style: TextStyle(
              color: AppColors.blueDark,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
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
                icon: Icons.smart_toy_outlined,
                color: AppColors.blue,
                onTap: () => _openFeature(
                  'Conversa con Biomark',
                  Icons.smart_toy_outlined,
                  AppColors.blue,
                ),
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
            AppColors.blue.withOpacity(0.10),
            AppColors.blue.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withOpacity(0.15)),
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
                color: Colors.black.withOpacity(0.04),
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
                color: Colors.black.withOpacity(0.04),
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
                  color: iconColor.withOpacity(0.12),
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

  // ------------------------------------------------------------
  // BOTTOM NAV
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navLabels.length, (i) {
              final selected = _navIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _navIcons[i],
                      color: selected ? AppColors.green : AppColors.textGrey,
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _navLabels[i],
                      style: TextStyle(
                        color: selected ? AppColors.green : AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
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
              color: color.withOpacity(0.12),
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
