import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName = 'Maverick'});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _SubjectItem {
  const _SubjectItem(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _LessonItem {
  const _LessonItem({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final double progress; // 0.0 - 1.0
  final IconData icon;
  final Color color;
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color(0xFF6B7280);
  static const Color brandBlue = Color.fromARGB(255, 50, 96, 169);
  static const Color bg = Color(0xFFF4F6FB);

  final List<_SubjectItem> _subjects = const [
    _SubjectItem(
      'Chatea con BioMark',
      Icons.calculate_rounded,
      Color(0xFF7C93D9),
    ),
    _SubjectItem('Ciencias', Icons.science_rounded, Color(0xFF7ABF8E)),
    _SubjectItem('Lectura', Icons.menu_book_rounded, Color(0xFFE3B85C)),
    _SubjectItem('Arte', Icons.palette_rounded, Color(0xFFE38CA0)),
    _SubjectItem('Música', Icons.music_note_rounded, Color(0xFF6FB1D9)),
    _SubjectItem('Puzzle', Icons.extension_rounded, Color(0xFFAE8CE3)),
  ];

  final List<_LessonItem> _lessons = const [
    _LessonItem(
      title: 'Sistema Solar',
      subtitle: 'Ciencias • Nivel 2',
      progress: 0.6,
      icon: Icons.public_rounded,
      color: Color(0xFF5B6FC7),
    ),
    _LessonItem(
      title: 'Suma Básica',
      subtitle: 'Matemáticas • Nivel 1',
      progress: 0.4,
      icon: Icons.functions_rounded,
      color: Color(0xFFE38CA0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildGoalCard(),
            const SizedBox(height: 28),
            _buildSectionHeader('Explora todas las opciones'),
            const SizedBox(height: 14),
            _buildSubjectsGrid(),
            const SizedBox(height: 28),
            _buildSectionHeader('Continuar aprendiendo'),
            const SizedBox(height: 14),
            ..._lessons.map(
              (lesson) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildLessonCard(lesson),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------------- BARRA SUPERIOR (avatar + saludo + campana) ----------------
  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: brandBlue.withOpacity(0.12),
            boxShadow: [
              BoxShadow(
                color: brandBlue.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.face_rounded, color: brandBlue, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${widget.userName}! 👋',
                style: const TextStyle(fontSize: 13, color: textGray),
              ),
              const SizedBox(height: 2),
              const Text(
                '¿Listo para aprender\nalgo nuevo?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        _buildNotificationBell(),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: textDark,
            size: 22,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- TARJETA "META DE HOY" ----------------
  Widget _buildGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B6FC7), brandBlue],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meta de hoy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '3/5 Lecciones',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF3C05B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ENCABEZADOS DE SECCIÓN ----------------
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Ver todo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: brandBlue.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- GRID DE MATERIAS ----------------
  Widget _buildSubjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  Widget _buildSubjectCard(_SubjectItem subject) {
    return Container(
      decoration: BoxDecoration(
        color: subject.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: subject.color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: subject.color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(subject.icon, color: subject.color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            subject.label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TARJETA DE LECCIÓN EN PROGRESO ----------------
  Widget _buildLessonCard(_LessonItem lesson) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: lesson.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(lesson.icon, color: lesson.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.subtitle,
                  style: const TextStyle(fontSize: 12, color: textGray),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: lesson.progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            lesson.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(lesson.progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BARRA INFERIOR ----------------
  Widget _buildBottomNav() {
    final items = [
      ('Inicio', Icons.home_rounded),
      ('Explorar', Icons.search_rounded),
      ('Progreso', Icons.bar_chart_rounded),
      ('Perfil', Icons.person_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = index == _currentNavIndex;
            final (label, icon) = items[index];
            return GestureDetector(
              onTap: () => setState(() => _currentNavIndex = index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: selected ? brandBlue : textGray, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? brandBlue : textGray,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
