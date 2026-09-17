import 'package:flutter/material.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/survey_service.dart';
import 'package:flutter_biomark/health_history.dart';
class DatosPersonalesScreen extends StatefulWidget {
  final String nombreActual;
  final String? generoActual;

  const DatosPersonalesScreen({
    super.key,
    required this.nombreActual,
    this.generoActual,
  });

  @override
  State<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends State<DatosPersonalesScreen> {
  late TextEditingController _nombreController;
  String? _generoSeleccionado;

  final List<String> _opcionesGenero = const [
    'Femenino',
    'Masculino',
    'Otro',
    'Prefiero no decir',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
    _generoSeleccionado = _normalizarGenero(widget.generoActual);
  }

  String? _normalizarGenero(String? genero) {
    const valoresBackend = {
      'FEMENINO': 'Femenino',
      'MASCULINO': 'Masculino',
      'OTRO': 'Otro',
      'NO_ESPECIFICA': 'Prefiero no decir',
    };
    return valoresBackend[genero?.toUpperCase()] ??
        (_opcionesGenero.contains(genero) ? genero : null);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    // TODO: persistir nombre y género reales, por ejemplo:
    // await AuthSession.instance.actualizarNombre(_nombreController.text.trim());
    // await AuthSession.instance.actualizarGenero(_generoSeleccionado);

    Navigator.pop(context, {
      'nombre': _nombreController.text.trim(),
      'genero': _generoSeleccionado,
    });
  }

  @override
  Widget build(BuildContext context) {
    final respuestas = SurveyService.respuestas;

    final cronicas = List<String>.from(
      respuestas['enfermedadesCronicas'] ?? const [],
    );
    final hereditarios = List<String>.from(
      respuestas['antecedentesHereditarios'] ?? const [],
    );
    final alergias = List<String>.from(respuestas['alergias'] ?? const []);
    final medicamentos = (respuestas['medicamentosActuales'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Mis datos personales',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _guardarCambios,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: BiomarkColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildSeccionTitulo('Información básica'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: BiomarkColors.blue,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  DropdownButtonFormField<String>(
                    initialValue: _generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.wc_rounded,
                        color: BiomarkColors.blue,
                      ),
                    ),
                    hint: const Text('Selecciona'),
                    items: _opcionesGenero
                        .map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => _generoSeleccionado = valor);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSeccionTitulo('Mis antecedentes'),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AntecedentesScreen(),
                      ),
                    );
                    // Al volver, refrescamos por si se editó algo.
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: BiomarkColors.blue,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildResumenAntecedentes(
              icono: Icons.medical_information_outlined,
              titulo: 'Enfermedades crónicas',
              valores: cronicas,
            ),
            const SizedBox(height: 12),
            _buildResumenAntecedentes(
              icono: Icons.family_restroom_rounded,
              titulo: 'Antecedentes hereditarios',
              valores: hereditarios,
            ),
            const SizedBox(height: 12),
            _buildResumenAntecedentes(
              icono: Icons.warning_amber_rounded,
              titulo: 'Alergias',
              valores: alergias,
            ),
            const SizedBox(height: 12),
            _buildResumenAntecedentes(
              icono: Icons.medication_liquid_rounded,
              titulo: 'Medicamentos actuales',
              valores: medicamentos.trim().isEmpty ? [] : [medicamentos],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
      ),
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .3 : .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildResumenAntecedentes({
    required IconData icono,
    required String titulo,
    required List<String> valores,
  }) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .25 : .04),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
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
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tema.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (valores.isEmpty)
                  Text(
                    'Sin información registrada',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurface.withValues(alpha: .45),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: valores
                        .map(
                          (v) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: BiomarkColors.blue.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BiomarkColors.blue,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}