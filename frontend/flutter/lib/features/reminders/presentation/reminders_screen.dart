import 'package:flutter/material.dart';

import '../../../biomark_brand.dart';
import '../data/reminders_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // late RemindersService _remindersService; // COMENTADO
  late Future<List<Reminder>> _remindersFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // TODO: Get baseUrl and accessToken from your app config/provider
    // _remindersService = RemindersService(
    //   baseUrl: 'http://localhost:3001', // Replace with actual baseUrl
    //   accessToken: '', // Replace with actual token from auth
    // );
    // _remindersFuture = _remindersService.getReminders();

    // Datos de prueba comentados - Descomenta líneas anteriores para conectar backend
    _remindersFuture = Future.value(_getTestReminders());
  }

  // Datos de prueba para visualización
  List<Reminder> _getTestReminders() {
    return [
      Reminder(
        id: '1',
        usuarioId: 'user123',
        tipo: 'MEDICAMENTO',
        titulo: 'Losartán 50mg',
        descripcion: 'Tomar con alimentos',
        fechaRecordatorio: DateTime.now(),
        hora: '08:00',
        estado: 'PENDIENTE',
        fechaCreacion: DateTime.now(),
      ),
      Reminder(
        id: '2',
        usuarioId: 'user123',
        tipo: 'CITA_MEDICA',
        titulo: 'Control cardiología',
        descripcion: 'Dr. Roberto Sánchez',
        fechaRecordatorio: DateTime.now(),
        hora: '10:30',
        estado: 'PENDIENTE',
        fechaCreacion: DateTime.now(),
      ),
      Reminder(
        id: '3',
        usuarioId: 'user123',
        tipo: 'VACUNA',
        titulo: 'Vacuna anual',
        descripcion: 'Influenza 2024',
        fechaRecordatorio: DateTime.now().add(const Duration(days: 3)),
        hora: '15:00',
        estado: 'PENDIENTE',
        fechaCreacion: DateTime.now(),
      ),
    ];
  }

  // COMENTADO - Descomenta para conectar al backend
  // Future<void> _completeReminder(String reminderId) async {
  //   try {
  //     await _remindersService.updateReminderStatus(
  //       reminderId: reminderId,
  //       estado: 'COMPLETADO',
  //     );
  //     setState(() {
  //       _remindersFuture = _remindersService.getReminders();
  //     });
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Recordatorio completado')),
  //     );
  //   } on ReminderException catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  // Visualización solo - Muestra confirmación sin guardar
  Future<void> _completeReminder(String reminderId) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorio completado (visualización)')),
    );
  }

  // COMENTADO - Descomenta para conectar al backend
  // Future<void> _archiveReminder(String reminderId) async {
  //   try {
  //     await _remindersService.updateReminderStatus(
  //       reminderId: reminderId,
  //       estado: 'ARCHIVADO',
  //     );
  //     setState(() {
  //       _remindersFuture = _remindersService.getReminders();
  //     });
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Recordatorio archivado')),
  //     );
  //   } on ReminderException catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  // Visualización solo - Muestra confirmación sin guardar
  Future<void> _archiveReminder(String reminderId) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorio archivado (visualización)')),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reminder>>(
      future: _remindersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: BiomarkColors.green),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 52, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar recordatorios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final reminders = snapshot.data ?? [];
        final todayReminders = reminders
            .where((r) => _sameDay(r.fechaRecordatorio, DateTime.now()) && r.estado == 'PENDIENTE')
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 18),
            _buildTodayHeader(todayReminders.length),
            const SizedBox(height: 12),
            if (todayReminders.isEmpty)
              _buildEmptyState()
            else
              ...todayReminders.map(
                (reminder) => Column(
                  children: [
                    _buildReminderCard(reminder),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    final monthName = _getMonthName(_selectedDate.month);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: BiomarkColors.green.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _calendarNavButton(Icons.chevron_left_rounded, _previousMonth),
              Text(
                '$monthName ${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BiomarkColors.black,
                ),
              ),
              _calendarNavButton(Icons.chevron_right_rounded, _nextMonth),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _weekdayLabel('Lun')),
              Expanded(child: _weekdayLabel('Mar')),
              Expanded(child: _weekdayLabel('Mié')),
              Expanded(child: _weekdayLabel('Jue')),
              Expanded(child: _weekdayLabel('Vie')),
              Expanded(child: _weekdayLabel('Sáb')),
              Expanded(child: _weekdayLabel('Dom', isSunday: true)),
            ],
          ),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    final days = <Widget>[];
    for (int i = 1; i < startingWeekday; i++) {
      days.add(const SizedBox());
    }
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, i);
      final isSelected = _sameDay(date, DateTime.now());
      days.add(_buildCalendarDay(i, isSelected));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 4,
      children: days,
    );
  }

  Widget _buildCalendarDay(int day, bool isSelected) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, day);
    final isSunday = date.weekday == DateTime.sunday;

    return Container(
      alignment: Alignment.center,
      decoration: isSelected
          ? BoxDecoration(
              color: BiomarkColors.green,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: GestureDetector(
        onTap: () => setState(() => _selectedDate = date),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isSunday
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFF1A1C1E),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDate(DateTime.now()),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: BiomarkColors.black,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8EA),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count ${count == 1 ? 'Evento' : 'Eventos'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3F4A3B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isCompleted = reminder.estado == 'COMPLETADO';
    final iconColor = _getTypeColor(reminder.tipo);
    final icon = _getTypeIcon(reminder.tipo);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 76,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFBDBDBD) : iconColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.hora ?? '00:00',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: BiomarkColors.black,
                ),
              ),
              Text(
                reminder.estado.toLowerCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F4A3B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BiomarkColors.black,
                  ),
                ),
                if (reminder.descripcion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      reminder.descripcion!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3F4A3B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isCompleted)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _completeReminder(reminder.id),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Completar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _archiveReminder(reminder.id),
                  child: const Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Archivar'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, color: Color(0xFF3F4A3B)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No tienes recordatorios hoy',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  Color _getTypeColor(String tipo) {
    switch (tipo) {
      case 'VACUNA':
        return BiomarkColors.green;
      case 'CITA_MEDICA':
        return BiomarkColors.blue;
      case 'MEDICAMENTO':
      default:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(String tipo) {
    switch (tipo) {
      case 'VACUNA':
        return Icons.vaccines_rounded;
      case 'CITA_MEDICA':
        return Icons.medical_services_outlined;
      case 'MEDICAMENTO':
      default:
        return Icons.medication_rounded;
    }
  }

  Widget _calendarNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF1A1C1E)),
      ),
    );
  }

  static Widget _weekdayLabel(String label, {bool isSunday = false}) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSunday ? const Color(0xFFBA1A1A) : const Color(0xFF3F4A3B),
        ),
      ),
    );
  }
}
