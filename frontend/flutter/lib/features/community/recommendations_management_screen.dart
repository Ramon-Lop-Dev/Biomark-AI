import 'package:flutter/material.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/design/responsive_layout.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
import 'package:flutter_biomark/features/home/data/recommendations_service.dart';
import 'package:flutter_biomark/features/home/domain/health_recommendation.dart';

class RecommendationsManagementScreen extends StatefulWidget {
  const RecommendationsManagementScreen({super.key});

  @override
  State<RecommendationsManagementScreen> createState() =>
      _RecommendationsManagementScreenState();
}

class _RecommendationsManagementScreenState
    extends State<RecommendationsManagementScreen> {
  List<HealthRecommendation> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final list = await RecommendationsService.fetchRecommendations();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _abrirModalCrear() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CrearRecomendacionSheet(),
    ).then((creado) {
      if (creado == true) {
        _cargar();
      }
    });
  }

  Future<void> _eliminar(HealthRecommendation rec) async {
    final confirmar = await BiomarkDialog.showConfirm(
      context,
      title: 'Eliminar Recomendación',
      message: '¿Deseas retirar la pauta "${rec.title}"?',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );

    if (!confirmar) return;
    final ok = await RecommendationsService.deleteRecommendation(rec.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recomendación retirada correctamente')),
      );
      _cargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la recomendación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pautas y Recomendaciones MINSA',
          maxLines: 2,
          softWrap: true,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalCrear,
        backgroundColor: BiomarkColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Pauta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 900,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(
                    child: Text('No hay recomendaciones registradas'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rec = _items[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: rec.accentColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: rec.accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    rec.icon,
                                    color: rec.accentColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.tag,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: rec.accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rec.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                  tooltip: 'Eliminar pauta',
                                  onPressed: () => _eliminar(rec),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec.summary,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            if (rec.minsaNormative != null &&
                                rec.minsaNormative!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: BiomarkColors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        rec.minsaNormative!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (rec.keyPoints.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: rec.keyPoints.take(2).map((kp) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: TextStyle(
                                          color: rec.accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          kp,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _CrearRecomendacionSheet extends StatefulWidget {
  const _CrearRecomendacionSheet();

  @override
  State<_CrearRecomendacionSheet> createState() =>
      _CrearRecomendacionSheetState();
}

class _CrearRecomendacionSheetState extends State<_CrearRecomendacionSheet> {
  final _formKey = GlobalKey<FormState>();
  RecommendationCategory _categoria = RecommendationCategory.dengue;

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _resumenCtrl;
  late final TextEditingController _detalleCtrl;
  late final TextEditingController _normativaCtrl;
  late final TextEditingController _etiquetaCtrl;
  late final TextEditingController _puntosCtrl;
  late final TextEditingController _condicionesCtrl;
  late final TextEditingController _alertasCtrl;
  late final TextEditingController _municipiosCtrl;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _resumenCtrl = TextEditingController();
    _detalleCtrl = TextEditingController();
    _normativaCtrl = TextEditingController(
      text: HealthRecommendation.defaultNormativeForCategory(_categoria),
    );
    _etiquetaCtrl = TextEditingController(
      text: HealthRecommendation.defaultTagForCategory(_categoria),
    );
    _puntosCtrl = TextEditingController();
    _condicionesCtrl = TextEditingController();
    _alertasCtrl = TextEditingController();
    _municipiosCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _resumenCtrl.dispose();
    _detalleCtrl.dispose();
    _normativaCtrl.dispose();
    _etiquetaCtrl.dispose();
    _puntosCtrl.dispose();
    _condicionesCtrl.dispose();
    _alertasCtrl.dispose();
    _municipiosCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(RecommendationCategory cat) {
    setState(() {
      _categoria = cat;
      _normativaCtrl.text = HealthRecommendation.defaultNormativeForCategory(cat);
      _etiquetaCtrl.text = HealthRecommendation.defaultTagForCategory(cat);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final puntos = _puntosCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (puntos.isEmpty) {
      puntos.add('Seguir indicaciones del personal de salud local.');
    }

    final condiciones = _condicionesCtrl.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final alertas = _alertasCtrl.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final municipios = _municipiosCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rec = HealthRecommendation(
      id: '',
      category: _categoria,
      title: _tituloCtrl.text.trim(),
      summary: _resumenCtrl.text.trim(),
      details: _detalleCtrl.text.trim(),
      icon: HealthRecommendation.iconForCategory(_categoria),
      accentColor: HealthRecommendation.colorForCategory(_categoria),
      minsaNormative: _normativaCtrl.text.trim(),
      tag: _etiquetaCtrl.text.trim(),
      keyPoints: puntos,
      targetConditions: condiciones,
      targetDiseases: alertas,
      targetMunicipalities: municipios,
    );

    final ok = await RecommendationsService.createRecommendation(rec);
    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pauta de salud MINSA publicada exitosamente'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar. Revisa tu conexión con el servidor.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = HealthRecommendation.colorForCategory(_categoria);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    HealthRecommendation.iconForCategory(_categoria),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nueva Pauta de Salud MINSA',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categoría Sanitaria (Define color e icono normativo)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<RecommendationCategory>(
                      initialValue: _categoria,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      items: RecommendationCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: HealthRecommendation.colorForCategory(cat),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(HealthRecommendation.labelForCategory(cat)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _onCategoryChanged(val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _normativaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Normativa Oficial MINSA (Requisito Obligatorio)',
                        prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Debes citar la normativa o protocolo MINSA'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: InputDecoration(
                        labelText: 'Título de la Recomendación',
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Ingresa un título descriptivo (mínimo 5 letras)'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _etiquetaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Etiqueta o Tag de la Tarjeta',
                        prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _resumenCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Resumen visible en tarjeta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Resumen debe tener al menos 10 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _detalleCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Detalle clínico completo (al tocar la tarjeta)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 15)
                          ? 'Detalle clínico debe tener al menos 15 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _puntosCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Puntos clave de prevención (uno por línea)',
                        hintText: '• Lavar pilas con cloro\n• No automedicarse\n• Eliminar recipientes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _condicionesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Condiciones Diana (separadas por coma)',
                        hintText: 'hipertension, diabetes, asma, arritmia',
                        prefixIcon: const Icon(Icons.favorite_border_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alertasCtrl,
                      decoration: InputDecoration(
                        labelText: 'Alertas Sanitarias Diana (separadas por coma)',
                        hintText: 'dengue, malaria, calor, respiratorio',
                        prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _municipiosCtrl,
                      decoration: InputDecoration(
                        labelText: 'Municipios Objetivo (opcional, vacío = Nacional)',
                        hintText: 'Managua, León, Chinandega',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Publicar y Validar Recomendación',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
