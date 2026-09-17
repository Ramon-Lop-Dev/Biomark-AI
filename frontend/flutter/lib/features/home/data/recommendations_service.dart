import 'package:flutter/material.dart';
import '../domain/health_recommendation.dart';

class RecommendationsService {
  static List<HealthRecommendation> getRecommendations() {
    return const [
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
          'Mide tu pulso con la función PPG de Biomark AI luego de reposar 5 minutos.',
          'Consulta si experimentas palpitaciones recurrentes, mareos o sensación de desmayo.',
          'La actividad física moderada diaria fortalece el miocardio.',
        ],
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
      ),
    ];
  }
}
