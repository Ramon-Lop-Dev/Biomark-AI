import 'package:flutter/material.dart';
import '../../../core/ui/biomark_dialog.dart';
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
  bool _isSaving = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final unselectedText = isDark ? Colors.white70 : const Color(0xFF334155);
    final unselectedIcon = isDark ? Colors.white54 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? color : unselectedIcon),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? color : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                14,
                22,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: isDark ? 0.35 : 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_chart_rounded, size: 22, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Evolución de Síntoma',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Actualiza tu curva de recuperación y seguimiento clínico.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _symptomController,
                      decoration: InputDecoration(
                        labelText: 'Síntoma',
                        hintText: 'Ej: Dolor de cabeza, tos seca, fiebre...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '¿Cómo ha evolucionado?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(
                          label: 'Mejoró',
                          value: 'MEJORO',
                          selected: _selectedStatus == 'MEJORO',
                          color: const Color(0xFF10B981),
                          icon: Icons.trending_up_rounded,
                          onTap: () => setState(() => _selectedStatus = 'MEJORO'),
                        ),
                        _buildStatusChip(
                          label: 'Sigue igual',
                          value: 'IGUAL',
                          selected: _selectedStatus == 'IGUAL',
                          color: const Color(0xFF3B82F6),
                          icon: Icons.trending_flat_rounded,
                          onTap: () => setState(() => _selectedStatus = 'IGUAL'),
                        ),
                        _buildStatusChip(
                          label: 'Empeoró',
                          value: 'EMPEORO',
                          selected: _selectedStatus == 'EMPEORO',
                          color: const Color(0xFFEF4444),
                          icon: Icons.trending_down_rounded,
                          onTap: () => setState(() => _selectedStatus = 'EMPEORO'),
                        ),
                        _buildStatusChip(
                          label: 'No seguro',
                          value: 'NO_SEGURO',
                          selected: _selectedStatus == 'NO_SEGURO',
                          color: const Color(0xFF8B5CF6),
                          icon: Icons.help_outline_rounded,
                          onTap: () => setState(() => _selectedStatus = 'NO_SEGURO'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nivel de intensidad:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_selectedIntensity.round()} / 10',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _selectedIntensity,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => _selectedIntensity = val),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notas adicionales (opcional)',
                        hintText: 'Ej: Sentí alivio tras el descanso, tomé hidratación...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final symptom = _symptomController.text.trim();
                                if (symptom.isEmpty) {
                                  await BiomarkDialog.showError(
                                    context,
                                    title: 'Dato requerido',
                                    message: 'Por favor escribe el nombre del síntoma.',
                                  );
                                  return;
                                }

                                final nav = Navigator.of(context);
                                setState(() => _isSaving = true);
                                try {
                                  await widget.progressApi.createProgress(
                                    symptom: symptom,
                                    status: _selectedStatus,
                                    intensity: _selectedIntensity.round(),
                                    notes: _notesController.text.trim(),
                                  );
                                  if (!mounted) return;
                                  nav.pop();
                                  widget.onSaved();
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _isSaving = false);
                                  if (context.mounted) {
                                    await BiomarkDialog.showError(
                                      context,
                                      title: 'Error al registrar',
                                      message: '$e',
                                    );
                                  }
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text(
                                'Guardar Evolución',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
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
