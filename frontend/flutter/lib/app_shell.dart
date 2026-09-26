// Shell de navegación principal de Biomark AI.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'survey_service.dart';
import 'features/gis/presentation/gis_map_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/progress/presentation/add_evolution_sheet.dart';
import 'features/progress/data/progress_api.dart';
import 'features/reminders/presentation/reminders_screen.dart';
import 'features/reminders/data/reminders_service.dart';
import 'features/community/promoter_screens.dart';

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
  final ValueNotifier<int> _remindersRefresh = ValueNotifier(0);
  final ValueNotifier<int> _progressRefresh = ValueNotifier(0);

  final _userNavLabels = const [
    'Inicio',
    'Evolución',
    'Mapa',
    'Recordatorio',
    'Perfil',
  ];
  final _userNavIcons = const [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.location_on_rounded,
    Icons.notifications_rounded,
    Icons.person_outline_rounded,
  ];
  final _promoterNavLabels = const [
    'Panel',
    'Mapa',
    'Jornadas',
    'Reportes',
    'Perfil',
  ];
  final _promoterNavIcons = const [
    Icons.dashboard_rounded,
    Icons.location_on_rounded,
    Icons.event_available_rounded,
    Icons.fact_check_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  void dispose() {
    _remindersRefresh.dispose();
    _progressRefresh.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    if (index == 4) {
      _openProfile();
      return;
    }
    setState(() => _navIndex = index);
  }

  void _openChat() {
    SurveyService.abrirChat(context);
  }

  void _openProfile() {
    Navigator.push(
      context,
      _FadeSlidePageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoter = AuthSession.instance.isPromoter;
    final pages = promoter
        ? <Widget>[
            PromoterDashboardScreen(
              onOpenMap: () => setState(() => _navIndex = 1),
            ),
            const GisMapScreen(),
            const PromoterEventsScreen(),
            const PromoterReportsScreen(),
          ]
        : <Widget>[
            HomeScreen(
              onOpenMap: () => setState(() => _navIndex = 2),
              onNavigateToTab: (index) => setState(() => _navIndex = index),
            ),
            ProgressScreen(refreshSignal: _progressRefresh),
            const GisMapScreen(),
            RemindersScreen(
              refreshSignal: _remindersRefresh,
              onOpenMap: () => setState(() => _navIndex = 2),
            ),
          ];
    pages.add(
      const _PlaceholderBody(
        title: 'Perfil',
        icon: Icons.person_outline_rounded,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          reverseDuration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(.06, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_navIndex),
            child: pages[_navIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: !promoter && _navIndex == 3
          ? _buildAddReminderFAB()
          : !promoter && _navIndex == 1
          ? _buildAddEvolutionFAB()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 650;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: isWide ? 0 : 16,
      centerTitle: isWide,
      title: isWide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/branding/Logo_Horizontal.png',
                      width: 140,
                      height: 40,
                      fit: BoxFit.contain,
                      semanticLabel: 'Biomark AI',
                    ),
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
                  ],
                ),
              ),
            )
          : Image.asset(
              'assets/branding/Logo_Horizontal.png',
              width: 140,
              height: 40,
              fit: BoxFit.contain,
              semanticLabel: 'Biomark AI',
            ),
      actions: isWide
          ? null
          : [
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

  Widget _buildAddEvolutionFAB() {
    return FloatingActionButton(
      backgroundColor: BiomarkColors.green,
      elevation: 6,
      tooltip: 'Registrar evolución',
      onPressed: () => _showAddEvolutionModal(context),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  Future<void> _showAddReminderModal(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddReminderModal(),
    );
    if (created == true) {
      _remindersRefresh.value++;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recordatorio creado correctamente')),
      );
    }
  }

  Future<void> _showAddEvolutionModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEvolutionSheet(
        progressApi: ProgressApi(),
        onSaved: () => _progressRefresh.value++,
      ),
    );
  }

  Widget _buildBottomNav() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 650;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: isWide ? 620 : double.infinity,
            height: 96,
            child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: isWide ? 20 : 18,
                right: isWide ? 20 : 18,
                top: 28,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                child: Semantics(
                  label: 'Abrir asistente de salud Biomark AI',
                  button: true,
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
                          color: Theme.of(context).scaffoldBackgroundColor,
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
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _navItem(int index) {
    final promoter = AuthSession.instance.isPromoter;
    final labels = promoter ? _promoterNavLabels : _userNavLabels;
    final icons = promoter ? _promoterNavIcons : _userNavIcons;
    final selected = _navIndex == index;
    return Semantics(
      label: '${labels[index]}, pestaña ${index + 1} de ${labels.length}',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => _handleNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icons[index],
                  color: selected
                      ? BiomarkColors.green
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 74,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? BiomarkColors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  String _selectedFrecuencia = 'UNA_VEZ';
  String _selectedAvisoPrevio = 'AL_MOMENTO';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

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

  Future<void> _createReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un título'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión expiró. Inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await RemindersService(
        baseUrl: AppConfig.apiUrl,
        accessToken: accessToken,
      ).createReminder(
        tipo: _selectedType,
        titulo: title,
        descripcion: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        fechaRecordatorio: _selectedDate,
        hora: _hourController.text,
        frecuencia: _selectedFrecuencia,
        avisoPrevio: _selectedAvisoPrevio,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ReminderException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con el servidor.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                      _buildTypeButton('CITA', Icons.medical_services_outlined),
                      const SizedBox(width: 10),
                      _buildTypeButton('VACUNA', Icons.vaccines_rounded),
                      const SizedBox(width: 10),
                      _buildTypeButton(
                        'CONTROL',
                        Icons.health_and_safety_outlined,
                      ),
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
                const SizedBox(height: 18),
                // Frecuencia
                const Text(
                  'Frecuencia de repetición',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFrequencyChip('UNA_VEZ', 'Una vez', Icons.looks_one_outlined),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('HORARIA', 'Cada hora', Icons.hourglass_bottom_rounded),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('DIARIA', 'Diario', Icons.today_rounded),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('SEMANAL', 'Semanal', Icons.date_range_rounded),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('QUINCENAL', 'Quincenal (15 días)', Icons.calendar_view_week_rounded),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('MENSUAL', 'Mensual', Icons.calendar_month_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Aviso previo
                const Text(
                  'Aviso previo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAvisoPrevioChip(
                        'AL_MOMENTO',
                        'A la hora exacta',
                        Icons.notifications_active_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildAvisoPrevioChip(
                        '1_HORA_ANTES',
                        '1 hora antes',
                        Icons.schedule_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAvisoPrevioChip(
                        '1_DIA_ANTES',
                        '1 día antes',
                        Icons.event_available_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildAvisoPrevioChip(
                        '2_DIAS_ANTES',
                        '2 días antes',
                        Icons.calendar_today_rounded,
                      ),
                    ],
                  ),
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
                    onPressed: _isSaving ? null : _createReminder,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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
          color: isSelected
              ? BiomarkColors.green
              : Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              typeLabel,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label, IconData icon) {
    final isSelected = _selectedFrecuencia == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFrecuencia = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? BiomarkColors.green
              : Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisoPrevioChip(String value, String label, IconData icon) {
    final isSelected = _selectedAvisoPrevio == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAvisoPrevio = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? BiomarkColors.green
              : Theme.of(context).colorScheme.surfaceContainerHighest,
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
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
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
