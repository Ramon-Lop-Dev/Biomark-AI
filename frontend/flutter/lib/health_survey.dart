// Encuesta de salud obligatoria — se muestra una sola vez, antes del
// primer chat con Biomark AI, para que la IA pueda personalizar sus
// consejos según enfermedades crónicas o hereditarias del usuario.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'survey_service.dart';
import 'features/chat/presentation/chat_screen.dart';

class HealthSurveyScreen extends StatefulWidget {
  const HealthSurveyScreen({super.key});

  @override
  State<HealthSurveyScreen> createState() => _HealthSurveyScreenState();
}

enum _PasoEncuesta { datosPersonales, cronicas, hereditarias, alergias, medicamentos, resumen }

class _HealthSurveyScreenState extends State<HealthSurveyScreen> {
  _PasoEncuesta _paso = _PasoEncuesta.cronicas;

  // ---- Opciones ----
  final List<String> _opcionesCronicas = const [
    'Diabetes',
    'Hipertensión',
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
    'Aspirina/AINEs',
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
      Navigator.maybePop(context); // sale de la encuesta sin completarla
    }
  }

  Future<void> _finalizar() async {
    await SurveyService.guardarRespuestas(
      edad: int.parse(_edadController.text.trim()),
      sexo: _sexoSeleccionado!,
      enfermedadesCronicas: _cronicasSeleccionadas.toList(),
      antecedentesHereditarios: _hereditariasSeleccionadas.toList(),
      alergias: _alergiasSeleccionadas.toList(),
      medicamentosActuales: _medicamentosController.text.trim(),
      consentimientoMedico: _consentimientoMedico,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              _buildProgreso(),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _buildContenidoPaso(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildBotonSiguiente(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR + PROGRESO
  // ------------------------------------------------------------
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _atras,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 8, offset: const Offset(3, 3)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: BiomarkColors.black),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Antes de conversar con Biomark AI',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: BiomarkColors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildProgreso() {
    final total = _PasoEncuesta.values.length;
    return Row(
      children: List.generate(total, (i) {
        final activo = i <= _indicePaso;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: activo ? BiomarkColors.green : const Color(0xFFE4E4EC),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  // ------------------------------------------------------------
  // CONTENIDO POR PASO
  // ------------------------------------------------------------
  Widget _buildContenidoPaso() {
    switch (_paso) {
      case _PasoEncuesta.datosPersonales:
        return _buildPasoDatosPersonales();
      case _PasoEncuesta.cronicas:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('cronicas'),
          icono: Icons.medical_information_outlined,
          titulo: '¿Padeces alguna enfermedad crónica?',
          subtitulo: 'Selecciona todas las que apliquen',
          opciones: _opcionesCronicas,
          seleccionadas: _cronicasSeleccionadas,
        );
      case _PasoEncuesta.hereditarias:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('hereditarias'),
          icono: Icons.family_restroom_rounded,
          titulo: '¿Hay antecedentes en tu familia?',
          subtitulo: 'Enfermedades hereditarias de padres, hermanos o abuelos',
          opciones: _opcionesHereditarias,
          seleccionadas: _hereditariasSeleccionadas,
        );
      case _PasoEncuesta.alergias:
        return _buildPasoSeleccionMultiple(
          key: const ValueKey('alergias'),
          icono: Icons.warning_amber_rounded,
          titulo: '¿Tienes alguna alergia conocida?',
          subtitulo: 'Selecciona todas las que apliquen',
          opciones: _opcionesAlergias,
          seleccionadas: _alergiasSeleccionadas,
        );
      case _PasoEncuesta.medicamentos:
        return _buildPasoMedicamentos();
      case _PasoEncuesta.resumen:
        return _buildPasoResumen();
    }
  }

  Widget _buildConsentimientoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _consentimientoMedico,
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
                const Text(
                  'Permito que Biomark AI use mi historial médico para personalizar mi respuesta.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Esta información ayuda a la IA a sugerir mejores alertas, recomendaciones y centros de salud más apropiados.',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoSeleccionMultiple({
    required Key key,
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required List<String> opciones,
    required Set<String> seleccionadas,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(icono),
        const SizedBox(height: 18),
        Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BiomarkColors.black)),
        const SizedBox(height: 6),
        Text(subtitulo, style: const TextStyle(fontSize: 13, color: Color(0xFF7A7A85))),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: opciones.map((opcion) {
            final activo = seleccionadas.contains(opcion);
            final esNinguna = opcion.toLowerCase().startsWith('ninguna');
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (esNinguna) {
                    // "Ninguna" es excluyente con el resto
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: activo ? BiomarkColors.green.withValues(alpha: .12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activo ? BiomarkColors.green : Colors.transparent,
                    width: 1.4,
                  ),
                  boxShadow: activo
                      ? []
                      : [
                          BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 6, offset: const Offset(2, 2)),
                        ],
                ),
                child: Text(
                  opcion,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                    color: activo ? BiomarkColors.green : BiomarkColors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPasoMedicamentos() {
    return Column(
      key: const ValueKey('medicamentos'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.medication_liquid_rounded),
        const SizedBox(height: 18),
        const Text(
          '¿Tomas algún medicamento actualmente?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BiomarkColors.black),
        ),
        const SizedBox(height: 6),
        const Text(
          'Opcional — nos ayuda a evitar recomendaciones que interactúen mal',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A7A85)),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 8, offset: const Offset(2, 3)),
            ],
          ),
          child: TextField(
            controller: _medicamentosController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ej. Metformina 500mg, Losartán 50mg...',
              hintStyle: TextStyle(color: Color(0xFF9C9CA6), fontSize: 13.5),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoDatosPersonales() {
    return Column(
      key: const ValueKey('datosPersonales'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.person_outline_rounded),
        const SizedBox(height: 18),
        const Text(
          'Cuéntanos un poco sobre ti',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BiomarkColors.black),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estos datos ayudan a interpretar mejor tus síntomas.',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A7A85)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _edadController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Edad',
            suffixText: 'años',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _sexoSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Género / sexo biológico',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
            DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
            DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
            DropdownMenuItem(value: 'NO_ESPECIFICA', child: Text('Prefiero no especificarlo')),
          ],
          onChanged: (value) => setState(() => _sexoSeleccionado = value),
        ),
      ],
    );
  }

  Widget _buildPasoResumen() {
    return Column(
      key: const ValueKey('resumen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconoCabecera(Icons.fact_check_rounded, color: BiomarkColors.green),
        const SizedBox(height: 18),
        const Text(
          '¡Listo! Esto es lo que registramos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BiomarkColors.black),
        ),
        const SizedBox(height: 6),
        const Text(
          'Biomark AI usará esto para darte consejos más precisos a la hora de conversar',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A7A85)),
        ),
        const SizedBox(height: 20),
        _buildResumenTarjeta('Enfermedades crónicas', _cronicasSeleccionadas, Icons.medical_information_outlined),
        const SizedBox(height: 12),
        _buildResumenTarjeta('Datos personales', {
          '${_edadController.text.trim()} años',
          _sexoSeleccionado ?? 'Sin especificar',
        }, Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _buildResumenTarjeta('Antecedentes hereditarios', _hereditariasSeleccionadas, Icons.family_restroom_rounded),
        const SizedBox(height: 12),
        _buildResumenTarjeta('Alergias', _alergiasSeleccionadas, Icons.warning_amber_rounded),
        const SizedBox(height: 12),
        _buildResumenTarjeta(
          'Medicamentos actuales',
          _medicamentosController.text.trim().isEmpty ? {'Ninguno indicado'} : {_medicamentosController.text.trim()},
          Icons.medication_liquid_rounded,
        ),
        const SizedBox(height: 18),
        _buildConsentimientoCard(),
      ],
    );
  }

  Widget _buildResumenTarjeta(String titulo, Set<String> valores, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8, offset: const Offset(2, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: BiomarkColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: BiomarkColors.black)),
                const SizedBox(height: 3),
                Text(
                  valores.isEmpty ? 'Sin información' : valores.join(', '),
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A7A85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconoCabecera(IconData icono, {Color color = BiomarkColors.blue}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: .12),
      ),
      child: Icon(icono, color: color, size: 26),
    );
  }

  // ------------------------------------------------------------
  // BOTÓN SIGUIENTE / FINALIZAR
  // ------------------------------------------------------------
  Widget _buildBotonSiguiente() {
    final esUltimo = _paso == _PasoEncuesta.resumen;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _puedeAvanzar ? _siguiente : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: BiomarkColors.green,
          disabledBackgroundColor: const Color(0xFFD9D9E0),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: BiomarkColors.green.withValues(alpha: .4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          esUltimo ? 'Comienza a conversar con Biomark AI' : 'Siguiente',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}