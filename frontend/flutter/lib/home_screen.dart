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

  final List<String> _navLabels = ['Inicio', 'Jornadas', 'Historial', 'Perfil'];
  final List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.map_outlined,
    Icons.history_rounded,
    Icons.person_outline_rounded,
  ];

  void _openChatBiomark() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _BiomarkChatScreen()),
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
      const _PlaceholderBody(titulo: 'Jornadas', icon: Icons.map_outlined),
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
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'BIOMARK AI',
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
  // BOTTOM NAV — estilo claymorfismo con botón central flotante
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Barra curva de fondo
            Positioned(
              left: 18,
              right: 18,
              top: 26,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    // sombra clara (arriba-izquierda) + sombra oscura (abajo-derecha)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 10,
                      offset: const Offset(-4, -4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 14,
                      offset: const Offset(4, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _navItem(0)),
                    Expanded(child: _navItem(1)),
                    const SizedBox(width: 58), // espacio para el botón flotante
                    Expanded(child: _navItem(2)),
                    Expanded(child: _navItem(3)),
                  ],
                ),
              ),
            ),
            // Botón flotante central — chat con Biomark AI
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
                      colors: [AppColors.blue, AppColors.blueDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 6,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(color: AppColors.bg, width: 4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      Positioned(
                        right: 9,
                        bottom: 9,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            color: AppColors.blue,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
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
      onTap: () => setState(() => _navIndex = i),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _navIcons[i],
            color: selected ? AppColors.green : AppColors.textGrey,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            _navLabels[i],
            style: TextStyle(
              color: selected ? AppColors.green : AppColors.textGrey,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
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

// ============================================================
// PANTALLA DE CHAT — BIOMARK AI
// ============================================================
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}

class _BiomarkChatScreen extends StatefulWidget {
  const _BiomarkChatScreen();

  @override
  State<_BiomarkChatScreen> createState() => _BiomarkChatScreenState();
}

class _BiomarkChatScreenState extends State<_BiomarkChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      '¡Hola! Soy Biomark AI ¿En qué puedo ayudarte hoy con tu salud?',
      false,
    ),
  ];

  bool _escribiendo = false;

  void _enviarMensaje() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(texto, true));
      _escribiendo = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulación de respuesta del asistente
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            'Gracias por contarme. Estoy registrando eso en tu seguimiento. '
            '¿Quieres que te dé una recomendación o prefieres agendar una cita?',
            false,
          ),
        );
        _escribiendo = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Biomark AI',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_escribiendo ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return _buildBubble(
                    'Biomark está escribiendo...',
                    false,
                    escribiendo: true,
                  );
                }
                final m = _messages[index];
                return _buildBubble(m.text, m.isUser);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser, {bool escribiendo = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textDark,
            fontSize: 13.5,
            fontStyle: escribiendo ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarMensaje(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _enviarMensaje,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
