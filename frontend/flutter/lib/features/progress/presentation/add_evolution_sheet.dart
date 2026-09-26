import 'package:flutter/material.dart';
import '../data/progress_api.dart';

class AddEvolutionSheet extends StatefulWidget {
  final ProgressApi progressApi;
  final VoidCallback onSaved;

  const AddEvolutionSheet({
    super.key,
    required this.progressApi,
    required this.onSaved,
  });

  @override
  State<AddEvolutionSheet> createState() => _AddEvolutionSheetState();
}

class _AddEvolutionSheetState extends State<AddEvolutionSheet> {
  late final TextEditingController _symptomController;
  late final TextEditingController _notesController;
  String _selectedStatus = 'MEJORO';
  double _selectedIntensity = 5.0;

  @override
  void initState() {
    super.initState();
    _symptomController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required bool selected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : const Color(0xFF6B756E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : const Color(0xFF2E332F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Registrar Evolución de Síntoma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Indica cómo ha progresado tu salud para actualizar tus estadísticas.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _symptomController,
                  decoration: InputDecoration(
                    labelText: 'Síntoma',
                    hintText: 'Ej: Dolor de cabeza, fiebre, tos...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cómo ha evolucionado?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(
                      label: 'Mejoró',
                      value: 'MEJORO',
                      selected: _selectedStatus == 'MEJORO',
                      color: const Color(0xFF1B8E44),
                      icon: Icons.trending_up_rounded,
                      onTap: () => setState(() => _selectedStatus = 'MEJORO'),
                    ),
                    _buildStatusChip(
                      label: 'Sigue igual',
                      value: 'IGUAL',
                      selected: _selectedStatus == 'IGUAL',
                      color: const Color(0xFF1D64D8),
                      icon: Icons.trending_flat_rounded,
                      onTap: () => setState(() => _selectedStatus = 'IGUAL'),
                    ),
                    _buildStatusChip(
                      label: 'Empeoró',
                      value: 'EMPEORO',
                      selected: _selectedStatus == 'EMPEORO',
                      color: const Color(0xFFD32F2F),
                      icon: Icons.trending_down_rounded,
                      onTap: () => setState(() => _selectedStatus = 'EMPEORO'),
                    ),
                    _buildStatusChip(
                      label: 'No seguro',
                      value: 'NO_SEGURO',
                      selected: _selectedStatus == 'NO_SEGURO',
                      color: const Color(0xFF7C3AED),
                      icon: Icons.help_outline_rounded,
                      onTap: () => setState(() => _selectedStatus = 'NO_SEGURO'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nivel de intensidad:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_selectedIntensity.round()}/10',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B8E44)),
                    ),
                  ],
                ),
                Slider(
                  value: _selectedIntensity,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: const Color(0xFF1B8E44),
                  onChanged: (val) => setState(() => _selectedIntensity = val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas adicionales (opcional)',
                    hintText: 'Ej: Bajó la fiebre después de descansar...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8E44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final symptom = _symptomController.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      if (symptom.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Por favor escribe el nombre del síntoma.')),
                        );
                        return;
                      }
                      try {
                        await widget.progressApi.createProgress(
                          symptom: symptom,
                          status: _selectedStatus,
                          intensity: _selectedIntensity.round(),
                          notes: _notesController.text.trim(),
                        );
                        navigator.pop();
                        widget.onSaved();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Evolución guardada correctamente.'),
                            backgroundColor: Color(0xFF1B8E44),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Guardar evolución', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
