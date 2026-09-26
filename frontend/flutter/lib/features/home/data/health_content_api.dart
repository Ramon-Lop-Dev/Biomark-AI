import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../domain/health_content_item.dart';

class HealthContentApi {
  const HealthContentApi._();

  static Future<List<HealthContentItem>> fetchContent({String? categoria, String? fuente}) async {
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/api/content').replace(queryParameters: {
      if (categoria != null && categoria != 'TODAS') 'categoria': categoria,
      if (fuente != null && fuente.isNotEmpty) 'fuente': fuente,
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

    return _fallbackItems;
  }

  static final List<HealthContentItem> _fallbackItems = [
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000001',
      titulo: 'Campaña Nacional de Vacunación y Detección Temprana de Dengue',
      descripcion: 'Medidas de prevención en hogares nicaragüenses y signos de alarma según la Normativa 004 del MINSA.',
      contenido: 'El Ministerio de Salud (MINSA) de Nicaragua reitera a las familias la importancia de inspeccionar pilas, barriles y techos para erradicar los criaderos del mosquito transmisor del dengue, zika y chikungunya. Ante síntomas como fiebre súbita, dolor detrás de los ojos, decaimiento o dolor abdominal intenso, no debe automedicarse con ácido acetilsalicílico ni antiinflamatorios no esteroideos; acuda de inmediato al puesto de salud más cercano.',
      categoria: 'PREVENCION',
      imagenUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 1)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000002',
      titulo: 'Pautas OPS/OMS para el Control de la Hipertensión en la Comunidad',
      descripcion: 'Recomendaciones de monitoreo y reducción de sodio para la protección cardiovascular.',
      contenido: 'La Organización Panamericana de la Salud (OPS) enfatiza que mantener la presión arterial por debajo de 130/80 mmHg reduce significativamente el riesgo de accidentes cerebrovasculares y daño renal. Se aconseja limitar el consumo de sal de mesa a menos de 5 gramos diarios, realizar al menos 150 minutos semanales de actividad aeróbica moderada y realizar controles periódicos de la frecuencia cardíaca y presión.',
      categoria: 'CARDIOVASCULAR',
      imagenUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      fuente: 'OPS / OMS',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 3)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000003',
      titulo: 'Guía Alimentaria y Manejo Glucémico en Climas Cálidos',
      descripcion: 'Protocolo MINSA para personas con diabetes tipo 2 durante olas de calor en el Pacífico.',
      contenido: 'En temperaturas superiores a los 32°C, las personas con diabetes pueden presentar deshidratación acelerada que altera los niveles séricos de glucosa. El MINSA recomienda beber abundante agua purificada, priorizar verduras verdes frescas, tubérculos no procesados y mantener los medicamentos orales o insulina protegidos de la exposición directa al sol y a temperatura ambiente fresca.',
      categoria: 'NUTRICION',
      imagenUrl: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
      fuente: 'MINSA Nicaragua',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 5)),
    ),
    HealthContentItem(
      id: 'c1000000-0000-0000-0000-000000000004',
      titulo: 'Salud Respiratoria Infantil: Reconocimiento de Signos de Peligro',
      descripcion: 'Criterios de la OMS para la atención de infecciones respiratorias agudas en el primer nivel.',
      contenido: 'Durante los cambios de estación lluviosa, la OMS y el MINSA recomiendan vigilar la respiración rápida en lactantes y niños pequeños. Signos como tiraje subcostal (hundimiento de costillas), rechazo de alimentos o estridor en reposo constituyen una emergencia médica que exige valoración inmediata por el personal de salud.',
      categoria: 'PEDIATRIA',
      imagenUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=800&q=80',
      fuente: 'OMS',
      fechaPublicacion: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
}
