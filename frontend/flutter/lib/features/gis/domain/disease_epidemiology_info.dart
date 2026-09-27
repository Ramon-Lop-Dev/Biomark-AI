import 'package:flutter/material.dart';

/// Catálogo de información clínica, vectores, síntomas y medidas preventivas
/// oficiales del Ministerio de Salud (MINSA) de Nicaragua para enriquecer las
/// alertas y brotes epidemiológicos en el mapa y la pantalla de inicio.
class DiseaseEpidemiologyInfo {
  final String diseaseName;
  final String officialClassification;
  final List<String> commonSymptoms;
  final String transmissionMechanism;
  final List<String> minsaPreventionMeasures;
  final String warningSigns;
  final Color themeColor;
  final IconData icon;

  const DiseaseEpidemiologyInfo({
    required this.diseaseName,
    required this.officialClassification,
    required this.commonSymptoms,
    required this.transmissionMechanism,
    required this.minsaPreventionMeasures,
    required this.warningSigns,
    required this.themeColor,
    required this.icon,
  });

  /// Resuelve la información contextual a partir del nombre o texto del reporte.
  factory DiseaseEpidemiologyInfo.forDisease(String? rawName, [String? description]) {
    final combined = '${rawName ?? ''} ${description ?? ''}'.toLowerCase();

    if (combined.contains('lepto')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Leptospirosis',
        officialClassification: 'Zoonosis de Notificación Inmediata (SILAIS / MINSA)',
        commonSymptoms: [
          'Fiebre súbita elevada y escalofríos intensos',
          'Dolor muscular fuerte en pantorrillas y espalda baja',
          'Dolor de cabeza intenso y dolor retroocular',
          'Enrojecimiento en los ojos (inyección conjuntival sin pus)',
          'Náuseas, vómitos y dolor abdominal',
          'Ictericia (color amarillo en ojos/piel) en casos complicados',
        ],
        transmissionMechanism:
            'Contacto directo de piel con heridas o mucosas con aguas estancadas, lodo o alimentos contaminados con orina de roedores tras lluvias o inundaciones.',
        minsaPreventionMeasures: [
          'No caminar descalzo ni bañarse en charcas, lodo o corrientes de agua estancada.',
          'Mantener alimentos y agua potable en recipientes tapados a prueba de roedores.',
          'Lavar con agua y jabón latas y recipientes de alimentos antes de abrirlos.',
          'Eliminar basura, malezas y escombros en patios para evitar madrigueras de ratas.',
          'Si estuvo expuesto a aguas de inundación, acuda al Puesto Médico por quimioprofilaxis preventiva.',
        ],
        warningSigns:
            'Disminución notable de la orina, sangrado nasal o gingival, vómitos incontrolables o dificultad respiratoria.',
        themeColor: Color(0xFFDC2626),
        icon: Icons.coronavirus_rounded,
      );
    }

    if (combined.contains('chikung') || combined.contains('chicung')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Chikungunya',
        officialClassification: 'Vigilancia Epidemiológica de Arbovirosis (MINSA)',
        commonSymptoms: [
          'Fiebre alta de inicio brusco',
          'Dolor articular severo e incapacitante (manos, rodillas y tobillos)',
          'Inflamación y rigidez articular matutina',
          'Erupción en la piel (rash) con manchas rojizas',
          'Fatiga extrema, cefalea y mialgias',
        ],
        transmissionMechanism:
            'Picadura de la hembra infectada de mosquito Aedes aegypti o Aedes albopictus.',
        minsaPreventionMeasures: [
          'Eliminar de inmediato todo objeto que acumule agua en patios y techos.',
          'Lavar pilas y barriles cepillando las paredes cada semana con abate o BTI.',
          'Usar repelente y ropa de manga larga, especialmente al amanecer y atardecer.',
          'Permitir el acceso a las brigadas del MINSA para fumigación térmica.',
          'Guardar reposo e ingerir abundantes líquidos (Sales de Rehidratación Oral).',
        ],
        warningSigns:
            'Incapacidad total para la marcha, dolor articular incontrolable o signos de deshidratación.',
        themeColor: Color(0xFFEA580C),
        icon: Icons.biotech_rounded,
      );
    }

    if (combined.contains('dengue')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Dengue',
        officialClassification: 'Alerta Nacional por Arbovirosis (Normativa 004 MINSA)',
        commonSymptoms: [
          'Fiebre repentina de más de 39°C',
          'Dolor intenso detrás de los ojos (retroocular)',
          'Dolores musculares y de articulaciones ("quebrantahuesos")',
          'Erupción cutánea (rash) y sensación de fatiga profunda',
          'Náuseas y pérdida del apetito',
        ],
        transmissionMechanism:
            'Picadura del mosquito Aedes aegypti infectado. El zancudo se reproduce activamente en recipientes con agua limpia estancada.',
        minsaPreventionMeasures: [
          'Inspeccionar y voltear recipientes que puedan acumular agua en el hogar.',
          'Mantener bien tapados todos los depósitos de almacenamiento de agua potable.',
          'Aplicar larvicida (BTI o abate) provisto por el MINSA en pilas y barriles.',
          'Dormir bajo mosquitero y usar mallas metálicas en puertas y ventanas.',
          'NO automedicarse con ácido acetilsalicílico (aspirina) ni ibuprofeno por riesgo hemorrágico.',
        ],
        warningSigns:
            'Dolor abdominal continuo e intenso, vómitos persistentes, sangrado de encías o nariz, somnolencia extrema.',
        themeColor: Color(0xFFDC2626),
        icon: Icons.coronavirus_rounded,
      );
    }

    if (combined.contains('zika')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Zika',
        officialClassification: 'Vigilancia Epidemiológica Prioritaria Materno-Fetal (MINSA)',
        commonSymptoms: [
          'Fiebre leve o febrícula',
          'Erupción en la piel con intensa picazón (prurito)',
          'Ojos rojos sin pus (conjuntivitis no purulenta)',
          'Dolor en pequeñas articulaciones de manos y pies',
          'Cefalea y debilidad general',
        ],
        transmissionMechanism:
            'Picadura de mosquito Aedes aegypti infectado, vía transplacentaria madre-hijo y transmisión sexual.',
        minsaPreventionMeasures: [
          'Protección prioritaria estricta a mujeres en estado de embarazo.',
          'Destrucción sistemática de criaderos de zancudos en toda la manzana comunitaria.',
          'Uso continuo de mosquiteros tratados y repelente certificado.',
          'Acudir al Centro de Salud ante el primer sarpullido febril.',
        ],
        warningSigns:
            'Debilidad muscular progresiva en miembros inferiores (alerta de Guillain-Barré).',
        themeColor: Color(0xFFD97706),
        icon: Icons.health_and_safety_rounded,
      );
    }

    if (combined.contains('malaria') || combined.contains('paludismo')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Malaria',
        officialClassification: 'Programa Nacional de Eliminación de la Malaria (MINSA)',
        commonSymptoms: [
          'Escalofríos intensos seguidos de fiebres muy altas recurrentes',
          'Sudoración profusa al bajar la temperatura',
          'Dolor de cabeza severo y cansancio extremo',
          'Náuseas y palidez por anemia',
        ],
        transmissionMechanism:
            'Picadura del mosquito hembra Anopheles infectado con Plasmodium vivax o falciparum.',
        minsaPreventionMeasures: [
          'Dormir permanentemente bajo mosquiteros impregnados con insecticida.',
          'Drenar zanjas y charcas de agua dulce cercanas a las viviendas.',
          'Acudir al puesto de salud para toma de muestra de gota gruesa gratuita.',
          'Completar el tratamiento medicamentoso antimalárico prescrito por el SILAIS.',
        ],
        warningSigns:
            'Fiebre que no cede, orina oscura tipo refresco de cola, ictericia o confusión mental.',
        themeColor: Color(0xFFB91C1C),
        icon: Icons.medication_liquid_rounded,
      );
    }

    if (combined.contains('gastro') || combined.contains('diarrea') || combined.contains('vomito') || combined.contains('vómito')) {
      return const DiseaseEpidemiologyInfo(
        diseaseName: 'Gastroenteritis Aguda / EDA',
        officialClassification: 'Protocolo de Vigilancia de Enfermedades Diarreicas (MINSA)',
        commonSymptoms: [
          'Evacuaciones líquidas frecuentes (más de 3 al día)',
          'Vómitos y náuseas repetidas',
          'Cólicos y retortijones abdominales',
          'Fiebre y sensación de sed constante',
          'Decaimiento y pérdida de electrolitos',
        ],
        transmissionMechanism:
            'Consumo de agua no segura, alimentos contaminados o mala higiene de manos (vía fecal-oral).',
        minsaPreventionMeasures: [
          'Consumir exclusivamente agua hervida o clorada (2 gotas de cloro por litro de agua).',
          'Lavarse las manos enérgicamente con agua y jabón antes de comer y tras ir al baño.',
          'Iniciar inmediatamente la hidratación con Suero Oral (SRO) tras cada deposición líquida.',
          'Cocer completamente las carnes y lavar con agua clorada frutas y verduras crudas.',
        ],
        warningSigns:
            'Ojos hundidos, llanto sin lágrimas, boca muy seca, vómitos incesantes o presencia de sangre en heces.',
        themeColor: Color(0xFFC026D3),
        icon: Icons.medical_services_rounded,
      );
    }

    // Caso general o brote sospechoso en investigación
    final cleanTitle = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Alerta Epidemiológica Comunitaria';

    return DiseaseEpidemiologyInfo(
      diseaseName: cleanTitle,
      officialClassification: 'Vigilancia Sanitaria Territorial Activa (MINSA / SILAIS)',
      commonSymptoms: const [
        'Fiebre persistente o de inicio repentino',
        'Malestar general, dolor muscular o articular',
        'Decaimiento físico y fatiga pronunciada',
        'Síntomas digestivos o respiratorios bajo evaluación médica',
      ],
      transmissionMechanism:
          'En investigación activa por brigadas comunitarias y equipo médico del SILAIS Managua.',
      minsaPreventionMeasures: const [
        'Acudir de inmediato al Centro de Salud o Puesto Médico más cercano.',
        'Mantener reposo en el hogar y ventilación adecuada en los ambientes.',
        'Asegurar consumo de agua potable y alimentos higiénicamente preparados.',
        'Evitar la automedicación con antibióticos o antiinflamatorios no recetados.',
        'Reportar nuevos casos en el vecindario a través de la brigada de salud.',
      ],
      warningSigns:
          'Fiebre que no cede con antipiréticos estándar, dificultad respiratoria o signos de deshidratación.',
      themeColor: const Color(0xFFDC2626),
      icon: Icons.health_and_safety_rounded,
    );
  }
}
