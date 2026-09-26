import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../domain/health_content_item.dart';

class HealthContentApi {
  const HealthContentApi._();

  static Future<List<HealthContentItem>> fetchContent({
    String? categoria,
    String? fuente,
    String? condicion,
  }) async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/api/content').replace(queryParameters: {
      if (categoria != null && categoria != 'TODAS') 'categoria': categoria,
      if (fuente != null && fuente.isNotEmpty) 'fuente': fuente,
      if (condicion != null && condicion.isNotEmpty) 'condicion': condicion,
      'limit': '20',
    });

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().map(HealthContentItem.fromJson).toList();
        }
      }
    } catch (_) {
      // Usar respaldo verificado
    }

    return _filterFallback(categoria: categoria, fuente: fuente, condicion: condicion);
  }

  static List<HealthContentItem> _filterFallback({
    String? categoria,
    String? fuente,
    String? condicion,
  }) {
    return _fallbackItems.where((item) {
      if (categoria != null && categoria != 'TODAS') {
        if (!item.categoria.toLowerCase().contains(categoria.toLowerCase())) return false;
      }
      if (fuente != null && fuente.isNotEmpty) {
        if (!item.fuente.toLowerCase().contains(fuente.toLowerCase())) return false;
      }
      if (condicion != null && condicion.isNotEmpty) {
        final term = condicion.toLowerCase();
        final matchCond = item.condicionesObjetivo.any((c) => c.toLowerCase().contains(term));
        final matchText = item.titulo.toLowerCase().contains(term) || item.descripcion.toLowerCase().contains(term);
        if (!matchCond && !matchText) return false;
      }
      return true;
    }).toList();
  }

  static final List<HealthContentItem> _fallbackItems = [
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000001',
      titulo: 'Alerta Epidemiológica: Prevención Activa de Dengue en Managua',
      descripcion: 'Medidas de prevención en hogares nicaragüenses y signos de alarma según la Normativa 004 del MINSA.',
      contenido: 'El Ministerio de Salud (MINSA) de Nicaragua reitera a las familias la importancia de inspeccionar pilas, barriles y techos para erradicar los criaderos del mosquito transmisor del dengue, zika y chikungunya. Ante síntomas como fiebre súbita, dolor detrás de los ojos, decaimiento o dolor abdominal intenso, no debe automedicarse con ácido acetilsalicílico ni antiinflamatorios no esteroideos; acuda de inmediato al puesto de salud más cercano.',
      categoria: 'PREVENCION',
      imagenUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      normativaCodigo: 'Normativa 004 - Protocolo Nacional de Vigilancia Arbovirosis',
      normativaUrl: 'http://minsa.gob.ni',
      tipoAviso: 'ALERTA_EPIDEMIOLOGICA',
      prioridad: 'ALTA',
      alcanceTipo: 'GENERAL',
      condicionesObjetivo: const ['dengue', 'fiebre', 'infeccion', 'general'],
      barrioComunidad: 'Managua',
      silais: 'MINSA - Cobertura Managua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 1)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000002',
      titulo: 'Guía MINSA: Control de la Hipertensión en la Comunidad',
      descripcion: 'Protocolo de control de presión y reducción de sodio según la Normativa 084 del MINSA.',
      contenido: 'El Ministerio de Salud de Nicaragua establece en la Normativa 084 que los pacientes hipertensos deben registrar sus cifras matutinas y nocturnas. Reduzca el consumo de sodio a menos de 5 gramos diarios, evite frituras y camine al menos 30 minutos al día. Acuda a su puesto médico barrial para retiro de tratamiento mensual.',
      categoria: 'CARDIOVASCULAR',
      imagenUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      normativaCodigo: 'Normativa 084 - Abordaje Clínico de la Hipertensión',
      normativaUrl: 'http://minsa.gob.ni',
      tipoAviso: 'NORMATIVA',
      prioridad: 'ALTA',
      alcanceTipo: 'CONDICION',
      condicionesObjetivo: const ['hipertension', 'hipertensión', 'presion alta', 'presión arterial', 'cardiovascular'],
      barrioComunidad: 'Managua',
      silais: 'MINSA - Cobertura Managua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 2)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000003',
      titulo: 'Cuidados del Pie y Manejo Glucémico en Diabetes Tipo 2',
      descripcion: 'Pautas del Programa de Enfermedades Crónicas del MINSA y Normativa 077.',
      contenido: 'Revise diariamente sus pies entre los dedos para evitar úlceras o heridas no percibidas. Mantenga una hidratación constante y respete los horarios de toma de medicamentos orales o insulina sin suspenderlos de manera abrupta.',
      categoria: 'NUTRICION',
      imagenUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      normativaCodigo: 'Normativa 077 - Atención Integral a la Diabetes Mellitus',
      normativaUrl: 'http://minsa.gob.ni',
      tipoAviso: 'NORMATIVA',
      prioridad: 'ALTA',
      alcanceTipo: 'CONDICION',
      condicionesObjetivo: const ['diabetes', 'glucosa', 'azucar en sangre', 'cronica'],
      barrioComunidad: 'Managua',
      silais: 'MINSA - Cobertura Managua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 3)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000004',
      titulo: 'Jornada Barrial de Vacunación Comunitaria y Atención Médica',
      descripcion: 'Clínicas móviles del MINSA en distritos de Managua brindando atención gratuita.',
      contenido: 'Personal de salud del MINSA brinda atención médica preventiva, toma de signos vitales, control prenatal y aplicación de esquemas de vacunas. Consulte la ubicación exacta en el mapa asistencial de Biomark AI.',
      categoria: 'PREVENCION',
      imagenUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      normativaCodigo: 'Modelo MOSAFC - Salud Familiar y Comunitaria',
      normativaUrl: 'http://minsa.gob.ni',
      tipoAviso: 'JORNADA_VACUNACION',
      prioridad: 'MEDIA',
      alcanceTipo: 'GENERAL',
      condicionesObjetivo: const ['vacunacion', 'salud preventiva', 'jornada'],
      barrioComunidad: 'Managua',
      silais: 'MINSA - Cobertura Managua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 4)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000005',
      titulo: 'Vigilancia Respiratoria: Signos de Alarma en Asma',
      descripcion: 'Criterios de la Normativa 062 para la atención oportuna de crisis respiratorias.',
      contenido: 'Durante cambios de clima en Managua, los pacientes con asma deben identificar a tiempo signos como tiraje subcostal o falta de aire al reposo. Tenga a mano su inhalador y no dude en acudir al centro de salud.',
      categoria: 'PEDIATRIA',
      imagenUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      normativaCodigo: 'Normativa 062 - Infecciones Respiratorias y Asma',
      normativaUrl: 'http://minsa.gob.ni',
      tipoAviso: 'NORMATIVA',
      prioridad: 'MEDIA',
      alcanceTipo: 'CONDICION',
      condicionesObjetivo: const ['asma', 'alergia', 'respiratorio', 'tos'],
      barrioComunidad: 'Managua',
      silais: 'MINSA - Cobertura Managua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
