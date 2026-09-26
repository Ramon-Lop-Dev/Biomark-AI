import 'package:flutter/material.dart';
import 'package:flutter_biomark/app_shell.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
import 'package:flutter_biomark/survey_service.dart';

class HealthSurveyScreen extends StatefulWidget {
  const HealthSurveyScreen({super.key, this.editing = false});

  final bool editing;

  @override
  State<HealthSurveyScreen> createState() => _HealthSurveyScreenState();
}

enum _PasoEncuesta { datosPersonales, cronicas, hereditarias, alergias, medicamentos, resumen }

class _HealthSurveyScreenState extends State<HealthSurveyScreen> {
  _PasoEncuesta _paso = _PasoEncuesta.datosPersonales;
  bool _isLoading = false;

  // ---- Opciones ----
  final List<String> _opcionesCronicas = const [
    'Diabetes',
    'Hipertensión arterial',
    'Asma',
    'Enfermedad cardíaca',
    'Enfermedad renal',
    'Hipotiroidismo',
    'Artritis',
    'Epilepsia',
    'Obesidad',
    'Ninguna',
  ];

  final List<String> _opcionesHereditarias = const [
    'Diabetes',
    'Hipertensión',
    'Cáncer',
    'Enfermedades cardíacas',
    'Enfermedades renales',
    'Enfermedades neurológicas',
    'Asma',
    'Ninguna',
  ];

  final List<String> _opcionesAlergias = const [
    'Penicilina',
    'Aspirina / AINEs',
    'Ibuprofeno',
    'Polen',
    'Mariscos',
    'Frutos secos',
    'Látex',
    'Antibióticos',
    'Ninguna conocida',
  ];

  // ---- Selecciones del usuario ----
  final Set<String> _cronicasSeleccionadas = {};
  final Set<String> _hereditariasSeleccionadas = {};
  final Set<String> _alergiasSeleccionadas = {};
  final TextEditingController _medicamentosController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  String? _sexoSeleccionado;
  bool _consentimientoMedico = true;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _loadExistingAnswers();
  }

  Future<void> _loadExistingAnswers() async {
    setState(() => _isLoading = true);
    await SurveyService.cargarDesdeBackend();
    if (!mounted) return;
    final answers = SurveyService.respuestas;
    setState(() {
      final age = answers['edad'];
      if (age is num) _edadController.text = '${age.toInt()}';
      _sexoSeleccionado = answers['sexo'] is String ? answers['sexo'] as String : null;
      _cronicasSeleccionadas.addAll(List<String>.from(answers['enfermedadesCronicas'] ?? const []));
      _hereditariasSeleccionadas.addAll(List<String>.from(answers['antecedentesHereditarios'] ?? const []));
      _alergiasSeleccionadas.addAll(List<String>.from(answers['alergias'] ?? const []));
      _medicamentosController.text = '${answers['medicamentosActuales'] ?? ''}';
      _consentimientoMedico = answers['consentimientoMedico'] != false;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _medicamentosController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  int get _indicePaso => _PasoEncuesta.values.indexOf(_paso);

  bool get _puedeAvanzar {
    switch (_paso) {
      case _PasoEncuesta.datosPersonales:
        final edad = int.tryParse(_edadController.text.trim());
        return edad != null && edad > 0 && edad <= 120 && _sexoSeleccionado != null;
      case _PasoEncuesta.cronicas:
        return _cronicasSeleccionadas.isNotEmpty;
      case _PasoEncuesta.hereditarias:
        return _hereditariasSeleccionadas.isNotEmpty;
      case _PasoEncuesta.alergias:
        return _alergiasSeleccionadas.isNotEmpty;
      case _PasoEncuesta.medicamentos:
        return true; // opcional
      case _PasoEncuesta.resumen:
        return true;
    }
  }

  void _siguiente() {
    if (!_puedeAvanzar) return;
    final valores = _PasoEncuesta.values;
    final siguienteIndex = _indicePaso + 1;
    if (siguienteIndex < valores.length) {
      setState(() => _paso = valores[siguienteIndex]);
    } else {
      _finalizar();
    }
  }

  void _atras() {
    final valores = _PasoEncuesta.values;
    final anteriorIndex = _indicePaso - 1;
    if (anteriorIndex >= 0) {
      setState(() => _paso = valores[anteriorIndex]);
    } else {
      if (widget.editing) {
        Navigator.pop(context);
      } else {
        // En la primera configuración obligatoria, si está en el paso 0 mostramos diálogo
        _mostrarAlertaSalir();
      }
    }
  }

  Future<void> _mostrarAlertaSalir() async {
    final salir = await BiomarkDialog.showConfirm(
      context,
      icon: Icons.assignment_late_outlined,
      title: 'Completar más tarde',
      message: 'Completar tu perfil clínico permite a Biomark AI darte respuestas seguras y personalizadas. ¿Deseas ir al inicio ahora?',
      cancelLabel: 'Continuar entrevista',
      confirmLabel: 'Ir al inicio',
    );
    if (salir && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  Future<void> _finalizar() async {
    final edad = int.tryParse(_edadController.text.trim());
    final sexo = _sexoSeleccionado;
    if (edad == null || sexo == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.editing) {
        await SurveyService.reemplazarEncuesta(
          edad: edad,
          sexo: sexo,
          enfermedadesCronicas: _cronicasSeleccionadas.toList(),
          antecedentesHereditarios: _hereditariasSeleccionadas.toList(),
          alergias: _alergiasSeleccionadas.toList(),
          medicamentosActuales: _medicamentosController.text.trim(),
          consentimientoMedico: _consentimientoMedico,
        ).timeout(const Duration(seconds: 15), onTimeout: () {});
      } else {
        await SurveyService.guardarRespuestas(
          edad: edad,
          sexo: sexo,
          enfermedadesCronicas: _cronicasSeleccionadas.toList(),
          antecedentesHereditarios: _hereditariasSeleccionadas.toList(),
          alergias: _alergiasSeleccionadas.toList(),
          medicamentosActuales: _medicamentosController.text.trim(),
          consentimientoMedico: _consentimientoMedico,
        ).timeout(const Duration(seconds: 15), onTimeout: () {});
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.editing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expediente médico actualizado correctamente'),
          backgroundColor: BiomarkColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } else {
      // Primera vez completada: navegar al Dashboard principal (Home)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, _) => const AppShell(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : BiomarkColors.backgroundClaro;

    if (_isLoading && widget.editing) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: BiomarkColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(isDark),
                  const SizedBox(height: 16),
                  _buildProgreso(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildContenidoPaso(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBarraInferior(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR + PROGRESO
  // ------------------------------------------------------------
  Widget _buildTopBar(bool isDark) {
    final titulo = widget.editing ? 'Editar Expediente Médico' : 'Entrevista Clínica Inicial';
    final pasoActual = _indicePaso + 1;
    final totalPasos = _PasoEncuesta.values.length;

    return Row(
      children: [
        IconButton(
          onPressed: _atras,
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Paso $pasoActual de $totalPasos: ${_getNombrePaso(_paso)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: BiomarkColors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getNombrePaso(_PasoEncuesta paso) {
    switch (paso) {
      case _PasoEncuesta.datosPersonales:
        return 'Datos básicos';
      case _PasoEncuesta.cronicas:
        return 'Condiciones crónicas';
      case _PasoEncuesta.hereditarias:
        return 'Antecedentes familiares';
      case _PasoEncuesta.alergias:
        return 'Alergias conocidas';
      case _PasoEncuesta.medicamentos:
        return 'Tratamientos actuales';
      case _PasoEncuesta.resumen:
        return 'Confirmación';
    }
  }

  Widget _buildProgreso() {
    final total = _PasoEncuesta.values.length;
    return Row(
      children: List.generate(total, (i) {
        final activo = i <= _indicePaso;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: activo ? BiomarkColors.primary : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  // ------------------------------------------------------------
  // CONTENIDO POR PASO
  // ------------------------------------------------------------
  Widget _buildContenidoPaso(bool isDark) {
    switch (_paso) {
      case _PasoEncuesta.datosPersonales:
        return _buildPasoDatosPersonales(isDark);
      case _PasoEncuesta.cronicas:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('cronicas'),
          icono: Icons.health_and_safety_rounded,
          titulo: '¿Padeces alguna enfermedad crónica?',
          subtitulo: 'Selecciona las condiciones diagnosticadas por un profesional:',
          opciones: _opcionesCronicas,
          seleccionadas: _cronicasSeleccionadas,
          isDark: isDark,
        );
      case _PasoEncuesta.hereditarias:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('hereditarias'),
          icono: Icons.family_restroom_rounded,
          titulo: '¿Hay antecedentes en tu familia?',
          subtitulo: 'Condiciones de salud relevantes en padres, hermanos o abuelos:',
          opciones: _opcionesHereditarias,
          seleccionadas: _hereditariasSeleccionadas,
          isDark: isDark,
        );
      case _PasoEncuesta.alergias:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('alergias'),
          icono: Icons.warning_amber_rounded,
          titulo: '¿Tienes alguna alergia conocida?',
          subtitulo: 'Medicamentos, alimentos o sustancias a las que presentes reacción:',
          opciones: _opcionesAlergias,
          seleccionadas: _alergiasSeleccionadas,
          isDark: isDark,
        );
      case _PasoEncuesta.medicamentos:
        return _buildPasoMedicamentos(isDark);
      case _PasoEncuesta.resumen:
        return _buildPasoResumen(isDark);
    }
  }

  Widget _buildPasoDatosPersonales(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      key: const ValueKey('datosPersonales'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.person_outline_rounded),
        const SizedBox(height: 18),
        Text(
          'Cuéntanos un poco sobre ti',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estos datos básicos son indispensables para contextualizar tus síntomas clínicos.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 24),

        // Tarjeta con inputs
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _edadController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Edad *',
                  hintText: 'Ej. 28',
                  suffixText: 'años',
                  prefixIcon: const Icon(Icons.cake_outlined, color: BiomarkColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BiomarkColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _sexoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Sexo biológico *',
                  prefixIcon: const Icon(Icons.wc_rounded, color: BiomarkColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BiomarkColors.primary, width: 2),
                  ),
                ),
                dropdownColor: cardBg,
                items: const [
                  DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                  DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                  DropdownMenuItem(value: 'NO_ESPECIFICA', child: Text('Prefiero no especificarlo')),
                ],
                onChanged: (value) => setState(() => _sexoSeleccionado = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasoSeleccionMultiple({
    required Key key,
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required List<String> opciones,
    required Set<String> seleccionadas,
    required bool isDark,
  }) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(icono),
        const SizedBox(height: 18),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: opciones.map((opcion) {
            final activo = seleccionadas.contains(opcion);
            final esNinguna = opcion.toLowerCase().startsWith('ninguna');

            return InkWell(
              onTap: () {
                setState(() {
                  if (esNinguna) {
                    seleccionadas.clear();
                    seleccionadas.add(opcion);
                  } else {
                    seleccionadas.removeWhere((o) => o.toLowerCase().startsWith('ninguna'));
                    if (activo) {
                      seleccionadas.remove(opcion);
                    } else {
                      seleccionadas.add(opcion);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: activo
                      ? BiomarkColors.primary.withValues(alpha: 0.12)
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activo ? BiomarkColors.primary : Colors.black.withValues(alpha: 0.08),
                    width: activo ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: activo ? 0.02 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activo) ...[
                      const Icon(Icons.check_circle_rounded, size: 16, color: BiomarkColors.primary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      opcion,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                        color: activo ? BiomarkColors.primary : textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPasoMedicamentos(bool isDark) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      key: const ValueKey('medicamentos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.medication_rounded),
        const SizedBox(height: 18),
        Text(
          '¿Tomas algún medicamento actualmente?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Opcional — ayuda a prevenir interacciones farmacológicas desfavorables.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _medicamentosController,
            maxLines: 4,
            style: TextStyle(color: textDark),
            decoration: const InputDecoration(
              hintText: 'Ej. Enalapril 10mg diario, Metformina 850mg con desayuno...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoResumen(bool isDark) {
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      key: const ValueKey('resumen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.verified_rounded, color: BiomarkColors.primary),
        const SizedBox(height: 18),
        Text(
          'Confirmación del Expediente',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verifica tus datos antes de continuar. Podrás actualizarlos en cualquier momento desde tu Perfil.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 20),
        _buildResumenTarjeta(
          'Datos Personales',
          {
            '${_edadController.text.trim()} años',
            _sexoSeleccionado ?? 'Sin especificar',
          },
          Icons.person_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _buildResumenTarjeta(
          'Condiciones Crónicas',
          _cronicasSeleccionadas,
          Icons.health_and_safety_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _buildResumenTarjeta(
          'Antecedentes Familiares',
          _hereditariasSeleccionadas,
          Icons.family_restroom_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _buildResumenTarjeta(
          'Alergias Conocidas',
          _alergiasSeleccionadas,
          Icons.warning_amber_rounded,
          isDark,
        ),
        const SizedBox(height: 10),
        _buildResumenTarjeta(
          'Medicamentos Actuales',
          _medicamentosController.text.trim().isEmpty
              ? {'Ninguno reportado'}
              : {_medicamentosController.text.trim()},
          Icons.medication_rounded,
          isDark,
        ),
        const SizedBox(height: 18),
        _buildConsentimientoCard(isDark),
      ],
    );
  }

  Widget _buildResumenTarjeta(
    String titulo,
    Set<String> valores,
    IconData icono,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BiomarkColors.blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: BiomarkColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valores.isEmpty ? 'Sin registros' : valores.join(', '),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentimientoCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BiomarkColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _consentimientoMedico,
            activeColor: BiomarkColors.primary,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _consentimientoMedico = value);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consentimiento de Contexto Médico Asistido',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Autorizo a BIOMARK AI a utilizar esta información exclusivamente para enriquecer mis orientaciones clínicas y sugerir centros de salud pertinentes.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconoCabecera(IconData icono, {Color color = BiomarkColors.primary}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icono, color: color, size: 26),
    );
  }

  // ------------------------------------------------------------
  // BARRA INFERIOR (BOTÓN SIGUIENTE / FINALIZAR)
  // ------------------------------------------------------------
  Widget _buildBarraInferior() {
    final esUltimo = _paso == _PasoEncuesta.resumen;
    final textoBoton = esUltimo
        ? (widget.editing ? 'Guardar y Actualizar' : 'Finalizar y Entrar al Inicio')
        : 'Siguiente';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _puedeAvanzar && !_isLoading ? _siguiente : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: BiomarkColors.primary,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    textoBoton,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    esUltimo ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}