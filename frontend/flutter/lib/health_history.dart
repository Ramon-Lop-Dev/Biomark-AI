// Mis Antecedentes — muestra lo que el usuario indicó en la encuesta de
// salud (enfermedades crónicas, hereditarias, alergias, medicamentos) y
// permite agregar nueva información sin repetir toda la encuesta.
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BiomarkColors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Mis Antecedentes',
          style: TextStyle(color: BiomarkColors.black, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SurveyService.completado ? _buildContenido() : _buildEstadoVacio(),
      ),
    );
  }

  // ------------------------------------------------------------
  // ESTADO VACÍO — todavía no completó la encuesta
  // ------------------------------------------------------------
  Widget _buildEstadoVacio() {
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
            const Text(
              'Aún no tienes antecedentes registrados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BiomarkColors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa la breve encuesta de salud para que Biomark AI conozca tu historial y te dé mejores consejos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF7A7A85)),
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
  Widget _buildContenido() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildCategoria(
          titulo: 'Enfermedades crónicas',
          icono: Icons.medical_information_outlined,
          color: BiomarkColors.blue,
          categoria: 'enfermedadesCronicas',
        ),
        const SizedBox(height: 14),
        _buildCategoria(
          titulo: 'Antecedentes hereditarios',
          icono: Icons.family_restroom_rounded,
          color: BiomarkColors.green,
          categoria: 'antecedentesHereditarios',
        ),
        const SizedBox(height: 14),
        _buildCategoria(
          titulo: 'Alergias',
          icono: Icons.warning_amber_rounded,
          color: Colors.orange,
          categoria: 'alergias',
        ),
        const SizedBox(height: 14),
        _buildMedicamentos(),
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
    required String titulo,
    required IconData icono,
    required Color color,
    required String categoria,
  }) {
    final valores = _valoresDe(categoria);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 4)),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: BiomarkColors.black),
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
            const Text(
              'Sin información registrada',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF9C9CA6)),
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

  Widget _buildMedicamentos() {
    final texto = (SurveyService.respuestas['medicamentosActuales'] as String?)?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 4)),
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
              const Expanded(
                child: Text(
                  'Medicamentos actuales',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: BiomarkColors.black),
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
              color: texto.isEmpty ? const Color(0xFF9C9CA6) : BiomarkColors.black,
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