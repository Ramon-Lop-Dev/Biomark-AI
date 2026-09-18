import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_biomark/core/auth/auth_session.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import '../domain/health_recommendation.dart';

class RecommendationsService {
  RecommendationsService._();

  static const _kCacheKey = 'biomark_cached_recommendations_v2';
  static List<HealthRecommendation> _cachedRecommendations = [];

  static const List<HealthRecommendation> defaultRecommendations = [
    HealthRecommendation(
      id: 'minsa_dengue_prev',
      category: RecommendationCategory.dengue,
      title: 'Prevención Activa de Dengue y Arbovirosis',
      summary: 'Elimina criaderos en recipientes con agua y reconoce signos de alarma tempranos.',
      details: 'El zancudo Aedes aegypti se reproduce en agua limpia estancada. Las lluvias en Nicaragua aumentan el riesgo de transmisión comunitaria. La detección oportuna previene el dengue grave.',
      icon: Icons.shield_rounded,
      accentColor: Color(0xFFEF4444),
      minsaNormative: 'Normativa 004 MINSA - Protocolo de Abordaje del Dengue',
      tag: 'Salud Vectorial MINSA',
      keyPoints: [
        'Lava y cepilla pilas, barriles y floreros al menos dos veces por semana.',
        'Desecha llantas viejas, latas y recipientes que acumulen agua de lluvia.',
        'Permite el ingreso a brigadistas de fumigación y aplicación de BTI.',
        'Signos de alarma: dolor abdominal intenso, vómitos persistentes y somnolencia.',
        '¡No te automediques! Evita la aspirina o el ibuprofeno ante fiebre.',
      ],
      targetConditions: ['fiebre', 'dengue', 'infeccion', 'dolor de cuerpo'],
      targetDiseases: ['dengue', 'arbovirosis', 'malaria', 'zika'],
      targetMunicipalities: [],
    ),
    HealthRecommendation(
      id: 'minsa_heat_wave',
      category: RecommendationCategory.heatWave,
      title: 'Hidratación y Prevención de Golpe de Calor',
      summary: 'Pautas de reposición hídrica en temperaturas superiores a 30°C.',
      details: 'En las regiones del Pacífico y Centro de Nicaragua, las temperaturas elevadas incrementan la pérdida hídrica dérmica y el riesgo de insolación en niños y adultos mayores.',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF0EA5E9),
      minsaNormative: 'Guía Técnica MINSA para Emergencias Climáticas',
      tag: 'Clima y Termorregulación',
      keyPoints: [
        'Consume entre 2.5 y 3 litros de agua potable distribuida a lo largo del día.',
        'Evita la exposición solar directa entre las 11:00 AM y 3:00 PM.',
        'Usa ropa holgada, de algodón y colores claros con protección solar o sombrero.',
        'Ten a mano sales de rehidratación oral (Sobres MINSA) ante signos de deshidratación.',
        'Atención especial a adultos mayores: pueden perder la sensación de sed.',
      ],
      targetConditions: ['deshidratacion', 'insolacion', 'golpe de calor'],
      targetDiseases: ['calor', 'sequia', 'ola_de_calor'],
      targetMunicipalities: ['Managua', 'León', 'Chinandega', 'Rivas', 'Tipitapa'],
    ),
    HealthRecommendation(
      id: 'minsa_cardio_pulse',
      category: RecommendationCategory.cardiovascular,
      title: 'Salud Cardiovascular y Control del Pulso',
      summary: 'Monitorea tu frecuencia cardíaca y reconoce los valores normales en reposo.',
      details: 'El pulso refleja el ritmo y gasto cardíaco. Una frecuencia regular entre 60 y 100 BPM en reposo indica un funcionamiento cardiovascular dentro de los parámetros esperados.',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFFE11D48),
      minsaNormative: 'Protocolo de Prevención de Enfermedades Crónicas MINSA',
      tag: 'Cardiovascular',
      keyPoints: [
        'El pulso normal en adultos en reposo oscila entre 60 y 100 latidos por minuto.',
        'Factores como el estrés, cafeína, tabaco y fiebre pueden acelerar el pulso temporalmente.',
        'Mide tu pulso con la función de sismocardiografía o PPG de Biomark AI luego de reposar 5 minutos.',
        'Consulta si experimentas palpitaciones recurrentes, mareos o sensación de desmayo.',
        'La actividad física moderada diaria fortalece el miocardio.',
      ],
      targetConditions: [
        'hipertension',
        'presion arterial',
        'cardiopatia',
        'arritmia',
        'infarto',
        'insuficiencia cardiaca'
      ],
      targetDiseases: [],
      targetMunicipalities: [],
    ),
    HealthRecommendation(
      id: 'minsa_treatment_adherence',
      category: RecommendationCategory.treatment,
      title: 'Adherencia al Tratamiento Farmacológico',
      summary: 'No interrumpas ni modifiques dosis prescritas por tu médico tratante.',
      details: 'El abandono temprano de tratamientos para hipertensión, diabetes o infecciones es una causa común de recaídas y complicaciones graves.',
      icon: Icons.medication_rounded,
      accentColor: Color(0xFF10B981),
      minsaNormative: 'Estrategia de Uso Racional de Medicamentos MINSA',
      tag: 'Farmacovigilancia',
      keyPoints: [
        'Toma tus medicamentos todos los días a la misma hora para mantener niveles estables.',
        'Nunca suspendas antibióticos antes de la fecha indicada por el médico.',
        'Configura recordatorios en la pestaña de Recordatorios de Biomark AI.',
        'Guarda las medicinas en un lugar fresco, seco y fuera del alcance de los niños.',
        'Si sientes molestias o efectos secundarios, comunícate con tu centro de salud.',
      ],
      targetConditions: ['medicamento', 'tratamiento', 'farmaco', 'prescripcion'],
      targetDiseases: [],
      targetMunicipalities: [],
    ),
    HealthRecommendation(
      id: 'minsa_diabetes_care',
      category: RecommendationCategory.diabetes,
      title: 'Control Glucémico y Cuidado en Diabetes',
      summary: 'Pautas para prevenir picos de glucosa y proteger la salud de tus pies.',
      details: 'La diabetes mellitus requiere monitoreo dietético, hidratación, caminatas y revisión diaria de los pies para evitar complicaciones microvasculares.',
      icon: Icons.restaurant_rounded,
      accentColor: Color(0xFFF59E0B),
      minsaNormative: 'Normativa 078 MINSA - Manejo de la Diabetes Mellitus',
      tag: 'Metabólica y Nutrición',
      keyPoints: [
        'Disminuye el consumo de gaseosas, jugos con azúcar agregada y frituras.',
        'Revisa tus pies cada noche para detectar pequeñas heridas o rozaduras.',
        'Mantén un horario regular de comidas y consume vegetales frescos.',
        'Realiza al menos 30 minutos de actividad física de bajo impacto al día.',
        'Acude a tu control mensual de glucemia en tu centro de salud o puesto médico.',
      ],
      targetConditions: [
        'diabetes',
        'glucosa',
        'azucar',
        'resistencia a la insulina',
        'obesidad'
      ],
      targetDiseases: [],
      targetMunicipalities: [],
    ),
    HealthRecommendation(
      id: 'minsa_respiratory_care',
      category: RecommendationCategory.respiratory,
      title: 'Salud Respiratoria y Manejo del Asma',
      summary: 'Protección broncopulmonar ante humo, polvo y variaciones térmicas.',
      details: 'En Nicaragua, las quemas agrícolas y el humo de leña pueden desencadenar broncoespasmos o agravar el asma bronquial.',
      icon: Icons.air_rounded,
      accentColor: Color(0xFF06B6D4),
      minsaNormative: 'Normativa 028 MINSA - Abordaje de Infecciones Respiratorias Agudas',
      tag: 'Salud Respiratoria',
      keyPoints: [
        'Evita exponerte al humo de quemas de basura o cocinas de leña.',
        'Cúbrete la boca al toser y lava tus manos frecuentemente.',
        'Usa tu inhalador preventivo según la indicación de tu médico.',
        'Ventila las habitaciones para evitar la concentración de polvo y ácaros.',
        'Signos de alarma: dificultad para hablar por falta de aire y labios azulados.',
      ],
      targetConditions: [
        'asma',
        'bronquitis',
        'alergia respiratoria',
        'epoc',
        'tos cronica'
      ],
      targetDiseases: ['respiratorio', 'influenza', 'neumonia'],
      targetMunicipalities: [],
    ),
  ];

  static List<HealthRecommendation> getRecommendations() {
    if (_cachedRecommendations.isNotEmpty) {
      return _cachedRecommendations;
    }
    return defaultRecommendations;
  }

  /// Carga recomendaciones desde el backend con fallback offline automático
  static Future<List<HealthRecommendation>> fetchRecommendations() async {
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      final headers = {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$base/api/recommendations'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final list = (decoded['data'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(HealthRecommendation.fromJson)
                .toList() ??
            [];

        if (list.isNotEmpty) {
          _cachedRecommendations = list;
          await _saveToLocalCache(list);
          return list;
        }
      }
    } catch (e) {
      debugPrint('[RecommendationsService] Error de red al cargar del backend: $e');
    }

    // Si falló la red, leer caché local
    final cached = await _loadFromLocalCache();
    if (cached.isNotEmpty) {
      _cachedRecommendations = cached;
      return cached;
    }

    _cachedRecommendations = defaultRecommendations;
    return defaultRecommendations;
  }

  static Future<void> _saveToLocalCache(List<HealthRecommendation> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((r) => r.toJson()).toList();
      await prefs.setString(_kCacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<List<HealthRecommendation>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(HealthRecommendation.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .trim();
  }

  /// Motor de priorización contextual inteligente:
  /// Evalúa el perfil clínico del usuario, sus signos vitales y alertas epidemiológicas locales.
  static List<HealthRecommendation> getPrioritized({
    List<HealthRecommendation>? sourceList,
    Map<String, dynamic>? surveyAnswers,
    String? userMunicipality,
    List<String>? activeAlerts,
    int? latestHeartRate,
  }) {
    final list = (sourceList != null && sourceList.isNotEmpty)
        ? sourceList
        : getRecommendations();

    final userConditions = ((surveyAnswers?['enfermedadesCronicas'] as List?) ?? [])
        .map((e) => _normalize(e.toString()))
        .toList();

    final meds = _normalize(surveyAnswers?['medicamentosActuales'] as String? ?? '');

    final alerts = (activeAlerts ?? []).map((a) => _normalize(a)).toList();
    final muni = _normalize(userMunicipality ?? '');

    final scored = list.map((rec) {
      int score = 1; // Base
      String? badge;

      final normalizedTargets = rec.targetConditions.map(_normalize).toList();
      final normalizedDiseases = rec.targetDiseases.map(_normalize).toList();
      final normalizedMunis = rec.targetMunicipalities.map(_normalize).toList();

      // 1. Alerta epidemiológica territorial activa (+10)
      final matchesAlert = alerts.any((alerta) =>
          normalizedDiseases.any((target) => alerta.contains(target) || target.contains(alerta)));
      if (matchesAlert) {
        score += 10;
        badge = '🚨 Alerta comunitaria activa';
      }

      // 2. Coincidencia con padecimiento crónico del usuario (+8)
      final matchesCondition = userConditions.any((cond) =>
          normalizedTargets.any((target) => cond.contains(target) || target.contains(cond)));
      if (matchesCondition) {
        score += 8;
        badge ??= '⭐ Prioritario para tu salud';
      }

      // 3. Signo vital reciente alterado (+7)
      if (rec.category == RecommendationCategory.cardiovascular && latestHeartRate != null) {
        if (latestHeartRate > 100 || latestHeartRate < 60) {
          score += 7;
          badge ??= '❤️ Atención a tu pulso reciente';
        }
      }

      // 4. Tratamiento farmacológico activo (+5)
      if (rec.category == RecommendationCategory.treatment && meds.isNotEmpty) {
        score += 5;
        badge ??= '💊 Para tus medicamentos';
      }

      // 5. Relevancia por municipio o departamento (+4)
      if (muni.isNotEmpty &&
          normalizedMunis.any((m) => muni.contains(m))) {
        score += 4;
        badge ??= '📍 Pauta para tu zona';
      }

      return rec.copyWith(
        relevanceScore: score,
        dynamicBadge: badge,
      );
    }).toList();

    scored.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return scored;
  }

  // --- MÉTODOS DE GESTIÓN PARA PROMOTORES Y ADMINISTRADORES ---

  static Future<bool> createRecommendation(HealthRecommendation rec) async {
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'categoria': HealthRecommendation.categoryToString(rec.category),
        'titulo': rec.title,
        'resumen': rec.summary,
        'detalle_clinico': rec.details,
        'normativa_minsa': rec.minsaNormative ?? HealthRecommendation.defaultNormativeForCategory(rec.category),
        'etiqueta': rec.tag,
        'puntos_clave': rec.keyPoints,
        'condiciones_diana': rec.targetConditions,
        'alertas_diana': rec.targetDiseases,
        'municipios_objetivo': rec.targetMunicipalities,
        'edad_minima': rec.minAge,
        'edad_maxima': rec.maxAge,
      });

      final response = await http.post(
        Uri.parse('$base/api/recommendations'),
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchRecommendations();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteRecommendation(String id) async {
    try {
      final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
      final token = AuthSession.instance.accessToken ?? '';
      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.delete(
        Uri.parse('$base/api/recommendations/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _cachedRecommendations.removeWhere((r) => r.id == id);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
