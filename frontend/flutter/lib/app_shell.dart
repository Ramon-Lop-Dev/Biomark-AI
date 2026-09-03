// Shell de navegación principal de Biomark AI.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/gis/presentation/gis_map_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/reminders/presentation/reminders_screen.dart';

/// Transición personalizada para navegación entre pantallas
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _navIndex = 0;

  final _navLabels = const [
    'Inicio',
    'Mejoría',
    'Mapa',
    'Recordatorio',
    'Perfil',
  ];
  final _navIcons = const [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.location_on_rounded,
    Icons.notifications_rounded,
    Icons.person_outline_rounded,
  ];

  void _handleNavTap(int index) {
    if (index == 4) {
      _openProfile();
      return;
    }
    setState(() => _navIndex = index);
  }

  void _openChat() {
    Navigator.push(
      context,
      _FadeSlidePageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      _FadeSlidePageRoute(builder: (_) => const ProfileScreen()),
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
      const HomeScreen(),
      const ProgressScreen(),
      const GisMapScreen(),
      const RemindersScreen(),
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
      floatingActionButton: _navIndex == 3 ? _buildAddReminderFAB() : null,
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
          tooltip: 'Mi perfil',
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BiomarkColors.blue.withValues(alpha: .12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: BiomarkColors.blue,
              size: 20,
            ),
          ),
          onPressed: _openProfile,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildAddReminderFAB() {
    return FloatingActionButton(
      backgroundColor: BiomarkColors.green,
      elevation: 6,
      onPressed: () => _showAddReminderModal(context),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  void _showAddReminderModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddReminderModal(),
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

class _AddReminderModal extends StatefulWidget {
  const _AddReminderModal();

  @override
  State<_AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<_AddReminderModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourController;
  String _selectedType = 'MEDICAMENTO';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _hourController = TextEditingController(text: '08:00');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _hourController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _createReminder() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un título'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Descomentar para conectar al backend
    // final reminder = Reminder(
    //   id: DateTime.now().millisecondsSinceEpoch.toString(),
    //   usuarioId: 'user123',
    //   tipo: _selectedType,
    //   titulo: _titleController.text,
    //   descripcion: _descriptionController.text,
    //   fechaRecordatorio: _selectedDate,
    //   hora: _hourController.text,
    //   estado: 'PENDIENTE',
    //   fechaCreacion: DateTime.now(),
    // );
    // await _remindersService.createReminder(reminder);

    // Visualización solo - Confirma la creación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recordatorio "${_titleController.text}" creado (visualización)',
        ),
        backgroundColor: BiomarkColors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nuevo Recordatorio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tipo de recordatorio
                const Text(
                  'Tipo de recordatorio',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeButton('MEDICAMENTO', Icons.medication_rounded),
                      const SizedBox(width: 10),
                      _buildTypeButton(
                        'CITA_MEDICA',
                        Icons.medical_services_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildTypeButton('VACUNA', Icons.vaccines_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Título
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Descripción
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Fecha
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _hourController,
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
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
                const SizedBox(height: 24),
                // Botón crear
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BiomarkColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _createReminder,
                    child: const Text(
                      'Crear Recordatorio',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedType == type;
    final typeLabel = type.replaceAll('_', ' ');
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BiomarkColors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? BiomarkColors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : BiomarkColors.black,
            ),
            const SizedBox(width: 6),
            Text(
              typeLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : BiomarkColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
