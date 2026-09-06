// Mis Antecedentes — muestra lo que el usuario indicó en la encuesta de
// salud (enfermedades crónicas, hereditarias, alergias, medicamentos) y
// permite agregar nueva información sin repetir toda la encuesta.
//
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'survey_service.dart';
import 'health_survey.dart';

class AntecedentesScreen extends StatefulWidget {
  const AntecedentesScreen({super.key});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> {
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: tema.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tema.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Mis Antecedentes',
          style: TextStyle(color: tema.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SurveyService.completado ? _buildContenido(tema) : _buildEstadoVacio(tema),
      ),
    );
  }

  // ------------------------------------------------------------
  // ESTADO VACÍO — todavía no completó la encuesta
  // ------------------------------------------------------------
  Widget _buildEstadoVacio(ThemeData tema) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(shape: BoxShape.circle, color: BiomarkColors.blue.withValues(alpha: .12)),
              child: const Icon(Icons.folder_shared_outlined, color: BiomarkColors.blue, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes antecedentes registrados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tema.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa la breve encuesta de salud para que Biomark AI conozca tu historial y te dé mejores consejos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tema.colorScheme.onSurface.withValues(alpha: .6)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BiomarkColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthSurveyScreen()),
                  );
                },
                child: const Text(
                  'Completar encuesta de salud',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CONTENIDO — muestra las respuestas guardadas
  // ------------------------------------------------------------
  Widget _buildContenido(ThemeData tema) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildCategoria(
          tema: tema,
          titulo: 'Enfermedades crónicas',
          icono: Icons.medical_information_outlined,
          color: BiomarkColors.blue,
          categoria: 'enfermedadesCronicas',
        ),
        const SizedBox(height: 14),
        _buildCategoria(
          tema: tema,
          titulo: 'Antecedentes hereditarios',
          icono: Icons.family_restroom_rounded,
          color: BiomarkColors.green,
          categoria: 'antecedentesHereditarios',
        ),
        const SizedBox(height: 14),
        _buildCategoria(
          tema: tema,
          titulo: 'Alergias',
          icono: Icons.warning_amber_rounded,
          color: Colors.orange,
          categoria: 'alergias',
        ),
        const SizedBox(height: 14),
        _buildMedicamentos(tema),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthSurveyScreen()),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18, color: BiomarkColors.blue),
            label: const Text(
              'Rehacer la encuesta completa',
              style: TextStyle(color: BiomarkColors.blue, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _valoresDe(String categoria) {
    return List<String>.from(SurveyService.respuestas[categoria] ?? const []);
  }

  Widget _buildCategoria({
    required ThemeData tema,
    required String titulo,
    required IconData icono,
    required Color color,
    required String categoria,
  }) {
    final valores = _valoresDe(categoria);
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .25 : .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .12)),
                child: Icon(icono, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tema.colorScheme.onSurface),
                ),
              ),
              GestureDetector(
                onTap: () => _mostrarDialogoAgregar(categoria, titulo),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .12)),
                  child: Icon(Icons.add_rounded, color: color, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (valores.isEmpty)
            Text(
              'Sin información registrada',
              style: TextStyle(fontSize: 12.5, color: tema.colorScheme.onSurface.withValues(alpha: .45)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: valores.map((v) => _buildChip(v, color, () => _confirmarEliminar(categoria, v))).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicamentos(ThemeData tema) {
    final texto = (SurveyService.respuestas['medicamentosActuales'] as String?)?.trim() ?? '';
    final esOscuro = tema.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .25 : .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BiomarkColors.blue.withValues(alpha: .12)),
                child: const Icon(Icons.medication_liquid_rounded, color: BiomarkColors.blue, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Medicamentos actuales',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tema.colorScheme.onSurface),
                ),
              ),
              GestureDetector(
                onTap: () => _mostrarDialogoMedicamentos(texto),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: BiomarkColors.blue.withValues(alpha: .12)),
                  child: const Icon(Icons.edit_rounded, color: BiomarkColors.blue, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            texto.isEmpty ? 'Sin información registrada' : texto,
            style: TextStyle(
              fontSize: 12.5,
              color: texto.isEmpty
                  ? tema.colorScheme.onSurface.withValues(alpha: .45)
                  : tema.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String texto, Color color, VoidCallback onEliminar) {
    return GestureDetector(
      onTap: onEliminar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded, size: 13, color: color),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DIÁLOGOS: agregar / eliminar / editar
  // (AlertDialog ya toma su color de fondo y texto de Theme
  // automáticamente, así que no necesitan cambios aquí)
  // ------------------------------------------------------------
  void _mostrarDialogoAgregar(String categoria, String tituloCategoria) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Agregar a "$tituloCategoria"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej. Migraña crónica',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BiomarkColors.green),
            onPressed: () {
              setState(() => SurveyService.agregarItem(categoria, controller.text));
              Navigator.pop(dialogContext);
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(String categoria, String valor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Eliminar este registro?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text('Se quitará "$valor" de tus antecedentes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() => SurveyService.eliminarItem(categoria, valor));
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoMedicamentos(String textoActual) {
    final controller = TextEditingController(text: textoActual);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Medicamentos actuales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ej. Metformina 500mg, Losartán 50mg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BiomarkColors.green),
            onPressed: () {
              setState(() => SurveyService.actualizarMedicamentos(controller.text));
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}