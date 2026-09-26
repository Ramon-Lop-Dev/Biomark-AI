// Formulario completo de Reporte Comunitario estilo MINSA.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/gis_api.dart';

const _recomendacionesMINSA = <String, _EnfermedadInfo>{
  'Dengue': _EnfermedadInfo(
    icon: Icons.bug_report_rounded,
    color: Color(0xFFEF4444),
    recomendaciones: [
      'Elimine recipientes con agua estancada (latas, floreros, llantas).',
      'Acuda al centro de salud si presenta fiebre repentina, dolor de cabeza intenso o manchas rojas.',
      'Use ropa de manga larga y repelente de insectos aprobado por el MINSA.',
      'Reporte a las brigadas SILAIS si observa criaderos del mosquito Aedes aegypti.',
    ],
  ),
  'Zika': _EnfermedadInfo(
    icon: Icons.pregnant_woman_rounded,
    color: Color(0xFFEF4444),
    recomendaciones: [
      'Las embarazadas deben acudir inmediatamente al centro de salud ante síntomas.',
      'Use repelente de insectos y ropa de manga larga.',
      'Elimine depósitos de agua estancada en el hogar.',
    ],
  ),
  'Chikungunya': _EnfermedadInfo(
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFFF59E0B),
    recomendaciones: [
      'Descanse y mantenga hidratación (agua, suero oral).',
      'Tome acetaminofén — NO aspirina ni ibuprofeno.',
      'Consulte al médico si el dolor articular persiste más de 7 días.',
    ],
  ),
  'Leptospirosis': _EnfermedadInfo(
    icon: Icons.water_drop_rounded,
    color: Color(0xFF3B82F6),
    recomendaciones: [
      'Use botas y guantes al manipular agua de inundación o barro.',
      'No nade en ríos o pozas con posible contaminación.',
      'Ante fiebre y dolores musculares intensos, acuda al hospital de inmediato.',
    ],
  ),
  'IRA': _EnfermedadInfo(
    icon: Icons.air_rounded,
    color: Color(0xFF0284C7),
    recomendaciones: [
      'Use mascarilla en espacios cerrados y concurridos.',
      'Lave sus manos frecuentemente con agua y jabón.',
      'Acuda al médico si hay dificultad para respirar, especialmente en niños y adultos mayores.',
    ],
  ),
  'COVID-19': _EnfermedadInfo(
    icon: Icons.coronavirus_rounded,
    color: Color(0xFF6366F1),
    recomendaciones: [
      'Aísle al enfermo en cuarto separado con buena ventilación.',
      'Consulte al centro de salud si hay fiebre alta o dificultad respiratoria.',
      'Notifique a sus contactos cercanos.',
    ],
  ),
  'Otro': _EnfermedadInfo(
    icon: Icons.healing_rounded,
    color: Color(0xFF10B981),
    recomendaciones: [
      'Acuda al centro de salud más cercano para evaluación médica.',
      'Evite automedicarse.',
    ],
  ),
};

class _EnfermedadInfo {
  const _EnfermedadInfo({
    required this.icon,
    required this.color,
    required this.recomendaciones,
  });
  final IconData icon;
  final Color color;
  final List<String> recomendaciones;
}

/// Abre el formulario robusto de reporte comunitario.
Future<void> showCommunityReportSheet(
  BuildContext context,
  GisApi gisApi, {
  required double latitude,
  required double longitude,
  void Function()? onReportSent,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _CommunityReportSheet(
      gisApi: gisApi,
      latitude: latitude,
      longitude: longitude,
      onReportSent: onReportSent,
    ),
  );
}

class _CommunityReportSheet extends StatefulWidget {
  const _CommunityReportSheet({
    required this.gisApi,
    required this.latitude,
    required this.longitude,
    this.onReportSent,
  });

  final GisApi gisApi;
  final double latitude;
  final double longitude;
  final void Function()? onReportSent;

  @override
  State<_CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<_CommunityReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _direccionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _medidasCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _casosCtrl = TextEditingController(text: '1');

  String? _tipoEnfermedad;
  DateTime _fechaInicioSintomas = DateTime.now();
  bool _enviando = false;

  static const _enfermedades = [
    'Dengue',
    'Zika',
    'Chikungunya',
    'Leptospirosis',
    'IRA',
    'COVID-19',
    'Otro',
  ];

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _descripcionCtrl.dispose();
    _medidasCtrl.dispose();
    _contactoCtrl.dispose();
    _casosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioSintomas,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      helpText: 'Fecha de inicio de síntomas',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (picked != null && mounted) {
      setState(() => _fechaInicioSintomas = picked);
    }
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    try {
      await widget.gisApi.createCommunityReport(
        latitude: widget.latitude,
        longitude: widget.longitude,
        description: _descripcionCtrl.text.trim(),
        caseCount: int.tryParse(_casosCtrl.text.trim()) ?? 1,
        tipoEnfermedad: _tipoEnfermedad,
        direccionExacta: _direccionCtrl.text.trim(),
        fechaInicioSintomas: _fechaInicioSintomas,
        medidasTomadas: _medidasCtrl.text.trim().isEmpty
            ? null
            : _medidasCtrl.text.trim(),
        contactoReportante: _contactoCtrl.text.trim().isEmpty
            ? null
            : _contactoCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onReportSent?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reporte enviado al MINSA para validación. ¡Gracias!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo enviar el reporte. Verifica tu conexión.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enfermedadInfo = _tipoEnfermedad != null
        ? _recomendacionesMINSA[_tipoEnfermedad]
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 44, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFEF4444), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reporte Comunitario MINSA',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          Text('Confidencial — Vigilancia epidemiológica SILAIS Managua',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(icon: Icons.coronavirus_rounded, text: 'Tipo de enfermedad o incidencia *', color: const Color(0xFFEF4444)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _tipoEnfermedad,
                          decoration: _dec('Selecciona la enfermedad', isDark),
                          items: _enfermedades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _tipoEnfermedad = v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el tipo de enfermedad' : null,
                        ),

                        if (enfermedadInfo != null) ...[
                          const SizedBox(height: 16),
                          _RecomendacionesMinsa(enfermedad: _tipoEnfermedad!, info: enfermedadInfo),
                        ],

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.location_on_rounded, text: 'Dirección o lugar exacto *', color: const Color(0xFF0284C7)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _direccionCtrl,
                          decoration: _dec('Ej: Barrio Altagracia, frente al Centro de Salud, Managua', isDark),
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().length < 5) ? 'Ingresa la dirección exacta (mín. 5 caracteres)' : null,
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.description_rounded, text: 'Descripción detallada *', color: const Color(0xFF0284C7)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descripcionCtrl,
                          decoration: _dec('¿Qué observaste? ¿Cuándo inició? ¿Cuántas personas afectadas?', isDark),
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().length < 10) ? 'Describe con más detalle (mín. 10 caracteres)' : null,
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.people_rounded, text: 'Cantidad aproximada de casos *', color: const Color(0xFFF59E0B)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _casosCtrl,
                          decoration: _dec('Número de personas afectadas', isDark),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return (n == null || n < 1) ? 'Ingresa al menos 1 caso' : null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.calendar_today_rounded, text: 'Fecha de inicio de síntomas', color: const Color(0xFF8B5CF6)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickFecha,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF8B5CF6)),
                                const SizedBox(width: 10),
                                Text(
                                  '${_fechaInicioSintomas.day.toString().padLeft(2, '0')}/${_fechaInicioSintomas.month.toString().padLeft(2, '0')}/${_fechaInicioSintomas.year}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.shield_rounded, text: 'Medidas ya tomadas (opcional)', color: const Color(0xFF10B981)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _medidasCtrl,
                          decoration: _dec('Ej: Se fumigó el área, se eliminaron depósitos de agua...', isDark),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel(icon: Icons.contact_phone_rounded, text: 'Datos de contacto (opcional)', color: Colors.grey),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactoCtrl,
                          decoration: _dec('Teléfono o correo — solo para que el MINSA pueda contactarte', isDark),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Este reporte es recibido por el sistema de vigilancia del SILAIS Managua. Tus datos son confidenciales.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _enviando ? null : _enviar,
                            icon: _enviando
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, size: 20),
                            label: Text(
                              _enviando ? 'Enviando...' : 'Enviar Reporte al MINSA',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        );
      },
    );
  }

  InputDecoration _dec(String hint, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
  );
}

class _RecomendacionesMinsa extends StatelessWidget {
  const _RecomendacionesMinsa({required this.enfermedad, required this.info});
  final String enfermedad;
  final _EnfermedadInfo info;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icon, size: 18, color: info.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recomendaciones MINSA — $enfermedad',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: info.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...info.recomendaciones.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, size: 18, color: info.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(rec,
                      style: TextStyle(fontSize: 12, height: 1.35,
                          color: isDark ? Colors.white70 : const Color(0xFF334155))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ),
    ],
  );
}
