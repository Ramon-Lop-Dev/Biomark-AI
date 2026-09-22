// Base de datos de conocimiento clínico offline de Biomark AI.
// Basada en normativas y guías oficiales del Ministerio de Salud (MINSA) de Nicaragua.

class MinsaOfflineEntry {
  final String id;
  final String title;
  final String normative;
  final String category;
  final List<String> keywords;
  final bool isEmergency;
  final String summary;
  final List<String> immediateCare;
  final List<String> alarmSigns;
  final List<String> contraindications;
  final String nextSteps;

  const MinsaOfflineEntry({
    required this.id,
    required this.title,
    required this.normative,
    required this.category,
    required this.keywords,
    this.isEmergency = false,
    required this.summary,
    required this.immediateCare,
    required this.alarmSigns,
    this.contraindications = const [],
    required this.nextSteps,
  });

  String formatResponse() {
    final buffer = StringBuffer();
    buffer.writeln('📋 $title');
    buffer.writeln('🏛️ Respaldo: $normative\n');
    buffer.writeln(summary);
    buffer.writeln();

    if (isEmergency) {
      buffer.writeln('🚨 ATENCIÓN INMEDIATA - SEÑAL DE ALERTA CRÍTICA:');
      for (final sign in alarmSigns) {
        buffer.writeln('• $sign');
      }
      buffer.writeln('\n⚠️ Acción requerida: Acude de inmediato al centro de salud u hospital más cercano.\n');
    }

    if (immediateCare.isNotEmpty) {
      buffer.writeln('💧 Medidas de autocuidado inmediato:');
      for (final care in immediateCare) {
        buffer.writeln('• $care');
      }
      buffer.writeln();
    }

    if (contraindications.isNotEmpty) {
      buffer.writeln('🚫 Lo que NO debes hacer (Contraindicaciones MINSA):');
      for (final contra in contraindications) {
        buffer.writeln('• $contra');
      }
      buffer.writeln();
    }

    if (!isEmergency && alarmSigns.isNotEmpty) {
      buffer.writeln('🚩 Signos de alarma para acudir a urgencias:');
      for (final sign in alarmSigns) {
        buffer.writeln('• $sign');
      }
      buffer.writeln();
    }

    buffer.writeln('🏥 Siguiente paso recomendado:');
    buffer.writeln(nextSteps);

    return buffer.toString().trim();
  }
}

class MinsaOfflineKnowledge {
  MinsaOfflineKnowledge._();

  static const List<MinsaOfflineEntry> catalog = [
    // 1. DENGUE Y ARBOVIROSIS (Normativa 073 / 004 MINSA)
    MinsaOfflineEntry(
      id: 'dengue_general',
      title: 'Protocolo de Abordaje del Dengue y Fiebres',
      normative: 'Normativa 004 / 073 MINSA - Manejo Clínico del Dengue',
      category: 'Arbovirosis',
      keywords: [
        'dengue', 'fiebre', 'calentura', 'zancudo', 'dolor de cuerpo',
        'dolor de ojos', 'dolor detras de los ojos', 'quebrantahuesos',
        'sarpullido', 'erupcion', 'plaquetas', 'artritis', 'chikungunya', 'zika'
      ],
      summary: 'El dengue es una infección viral transmitida por el mosquito Aedes aegypti. En Nicaragua es endémico y requiere seguimiento estricto para evitar su forma grave.',
      immediateCare: [
        'Reposo absoluto en cama bajo mosquitero para evitar picaduras a otros familiares.',
        'Hidratación oral constante: 2 a 3 litros diarios de agua limpia, agua de coco o Suero Oral MINSA.',
        'Control térmico con medios físicos: paños de agua tibia o a temperatura ambiente en frente y axilas.',
        'Alimentación blanda y fraccionada rica en líquidos.',
      ],
      contraindications: [
        'NO tomar Aspirina (ácido acetilsalicílico), Ibuprofeno, Diclofenac ni Naproxeno, ya que aumentan el riesgo de hemorragias.',
        'NO aplicar inyecciones intramusculares ni antibióticos sin indicación médica.',
      ],
      alarmSigns: [
        'Dolor abdominal intenso y continuo.',
        'Vómitos frecuentes (más de 3 veces en pocas horas).',
        'Sangrado de encías, nariz, piel (puntos rojos o moretones) o en heces.',
        'Somnolencia profunda, decaimiento extremo o irritabilidad.',
        'Piel pálida, fría o sudorosa.',
      ],
      nextSteps: 'Acude a tu puesto médico o centro de salud MINSA para evaluación clínica y toma de biometría hemática (control de plaquetas y hematocrito).',
    ),

    // 2. ATENCIÓN DE LA NIÑEZ Y DESHIDRATACIÓN (Normativa 153 MINSA)
    MinsaOfflineEntry(
      id: 'ninez_diarrea',
      title: 'Atención Integral de la Niñez y Diarrea',
      normative: 'Normativa 153 MINSA - Atención Integral a la Niñez',
      category: 'Salud Infantil',
      keywords: [
        'nino', 'nina', 'chavalo', 'chavala', 'bebe', 'lactante',
        'diarrea', 'vomito', 'deshidratacion', 'suero oral', 'suero',
        'cagantina', 'asiento', 'obradera', 'pansa', 'estomago'
      ],
      summary: 'La diarrea y el vómito en niños pequeños pueden causar deshidratación rápida y severa. El pilar fundamental es la Terapia de Rehidratación Oral (Plan A y B del MINSA).',
      immediateCare: [
        'Iniciar Sales de Rehidratación Oral (SRO) inmediatamente después de cada deposición líquida o vómito.',
        'Preparar el sobre de Suero Oral MINSA en exactamente 1 litro de agua potable o hervida.',
        'Ofrecer el suero con cuchara o vaso despacio (una cucharadita cada 2-3 minutos si hay vómitos).',
        'Continuar con la lactancia materna o la alimentación habitual si el niño tolera.',
      ],
      contraindications: [
        'NO administrar antidiarreicos (loperamida) ni antibióticos por cuenta propia.',
        'NO preparar el suero con gaseosas, refrescos azucarados ni té concentrado.',
      ],
      alarmSigns: [
        'Ojos hundidos, llanto sin lágrimas o boca muy seca.',
        'Mollera (fontanela) deprimida o hundida.',
        'El niño no puede beber o vomita absolutamente todo.',
        'Letargo, desgano profundo o dificultad para despertar.',
        'Presencia de sangre en las heces o fiebre muy alta que no cede.',
      ],
      nextSteps: 'Si el niño presenta alguno de los signos de alarma o no tolera el suero tras 2 horas, trasládalo de inmediato a la unidad de salud más cercana.',
    ),

    // 3. GOLPE DE CALOR Y TEMPERATURAS EXTREMAS
    MinsaOfflineEntry(
      id: 'golpe_calor',
      title: 'Prevención y Manejo de Golpe de Calor',
      normative: 'Guía Técnica MINSA para Emergencias Climáticas',
      category: 'Clima y Termorregulación',
      keywords: [
        'calor', 'golpe de calor', 'insolacion', 'mareo', 'desmayo',
        'sofocado', 'sofocacion', 'temperatura', 'sudor', 'bochorno',
        'calorazo', 'sed'
      ],
      summary: 'Las temperaturas mayores a 30°C comunes en el Pacífico y Centro de Nicaragua aumentan el riesgo de deshidratación e hipertermia por esfuerzo.',
      immediateCare: [
        'Mover a la persona de inmediato a un lugar con sombra, fresco y ventilado.',
        'Retirar ropa ajustada o innecesaria.',
        'Enfriar el cuerpo aplicando toallas mojadas con agua fresca en frente, cuello y axilas.',
        'Si está consciente, dar de beber sorbos pequeños de agua potable fresca o sales de rehidratación.',
      ],
      contraindications: [
        'NO dar bebidas alcohólicas, energizantes o café cargado.',
        'NO sumergir a la persona en agua con hielo de golpe (puede causar choque térmico).',
      ],
      alarmSigns: [
        'Piel muy caliente, roja y SECA (ausencia de sudoración).',
        'Confusión mental, delirio, habla incoherente o convulsiones.',
        'Pérdida del conocimiento o desmayo prolongado.',
        'Pulso rápido y débil o respiración acelerada superficial.',
      ],
      nextSteps: 'Si la persona pierde el conocimiento o la temperatura corporal no desciende tras 20 minutos, llévala a emergencias de inmediato.',
    ),

    // 4. SALUD CARDIOVASCULAR Y PULSO
    MinsaOfflineEntry(
      id: 'salud_cardiovascular',
      title: 'Manejo Preventivo y Monitoreo de Salud Cardiovascular',
      normative: 'Protocolo de Prevención de Enfermedades Crónicas MINSA',
      category: 'Cardiovascular',
      keywords: [
        'corazon', 'pulso', 'palpitaciones', 'taquicardia', 'bradicardia',
        'presion', 'presion alta', 'hipertension', 'pecho', 'latidos',
        'agitado', 'falta de aire', 'disnea'
      ],
      summary: 'El ritmo cardíaco en reposo en un adulto sano oscila entre 60 y 100 latidos por minuto. Valores sostenidos fuera de ese rango requieren valoración médica.',
      immediateCare: [
        'Sentarse o recostarse en posición cómoda con la cabeza ligeramente elevada.',
        'Aflojar prendas apretadas alrededor del cuello y pecho.',
        'Realizar respiraciones lentas y profundas (inhalar en 4 segundos, exhalar en 6).',
        'Evitar el tabaco, café, té oscuro y bebidas energizantes.',
        'Tomar los medicamentos antihipertensivos en el horario habitual prescrito.',
      ],
      contraindications: [
        'NO duplicar dosis de pastillas de la presión si olvidaste una toma previa.',
        'NO realizar esfuerzos físicos bruscos mientras persistan las palpitaciones.',
      ],
      alarmSigns: [
        'Dolor de pecho opresivo o pesadez que se irradia hacia el brazo izquierdo, cuello o mandíbula.',
        'Dificultad repentina para respirar en reposo.',
        'Mareo intenso con sensación inminente de desmayo.',
        'Hinchazón súbita de tobillos o piernas acompañada de cansancio extremo.',
      ],
      nextSteps: 'Si presentas dolor de pecho o falta de aire súbita, acude a emergencias hospitalarias de inmediato.',
    ),

    // 5. INFECCIONES RESPIRATORIAS AGUDAS (Normativa 028 MINSA)
    MinsaOfflineEntry(
      id: 'respiratorio_gripe',
      title: 'Abordaje de Infecciones Respiratorias y Gripe',
      normative: 'Normativa 028 MINSA - Manejo de Infecciones Respiratorias Agudas',
      category: 'Salud Respiratoria',
      keywords: [
        'gripe', 'tos', 'garganta', 'dolor de garganta', 'flema',
        'mocos', 'congestion', 'resfriado', 'catarro', 'ronquera',
        'estornudos', 'pecho apretado', 'asma'
      ],
      summary: 'La gran mayoría de resfriados y faringitis son de origen viral y no requieren antibióticos. El objetivo principal es mantener despejada la vía aérea y aliviar el malestar.',
      immediateCare: [
        'Aumentar la ingesta de líquidos calientes (té de manzanilla, sopas, agua con limón).',
        'Gárgaras de agua tibia con una pizca de sal para desinflamar la garganta.',
        'Reposo en habitación ventilada y uso de mascarilla para proteger a convivientes.',
        'Lavado de manos frecuente con agua y jabón.',
      ],
      contraindications: [
        'NO automedicarse con antibióticos (como amoxicilina o azitromicina) para catarros comunes.',
        'NO suspender inhaladores de control de asma si tienes diagnóstico previo.',
      ],
      alarmSigns: [
        'Dificultad para respirar: aleteo de la nariz o hundimiento de costillas al respirar.',
        'Fiebre alta que dura más de 3 días consecutivos.',
        'Labios o uñas de color azulado (cianosis / falta de oxígeno).',
        'Silbidos audibles en el pecho con fatiga al hablar.',
      ],
      nextSteps: 'Si observas dificultad respiratoria o silbidos en el pecho, asiste a consulta médica en tu puesto de salud.',
    ),

    // 6. DIABETES Y METABOLISMO (Normativa 078 MINSA)
    MinsaOfflineEntry(
      id: 'diabetes_metabolismo',
      title: 'Pautas de Cuidado en Diabetes Mellitus',
      normative: 'Normativa 078 MINSA - Manejo de la Diabetes Mellitus',
      category: 'Metabolismo',
      keywords: [
        'diabetes', 'azucar', 'glucosa', 'orina mucho', 'mucha sed',
        'perdida de peso', 'pie diabetico', 'insulina', 'metformina',
        'glibenclamida', 'hipoglicemia'
      ],
      summary: 'El control adecuado de la glucosa previene complicaciones crónicas en riñones, ojos, corazón y extremidades.',
      immediateCare: [
        'Mantener una hidratación adecuada con agua pura (evitar jugos envasados y gaseosas).',
        'Revisión diaria de los pies buscando ampollas, heridas o enrojecimiento.',
        'Respetar los horarios de comidas balanceadas y la toma regular de la medicación.',
        'Si sientes temblor, sudor frío o mareo (baja de azúcar/hipoglicemia): tomar medio vaso de agua con una cucharada de azúcar o jugo natural y reposar 15 minutos.',
      ],
      contraindications: [
        'NO caminar descalzo bajo ninguna circunstancia.',
        'NO cortar callos o lesiones en los pies con tijeras o navajas caseras.',
      ],
      alarmSigns: [
        'Herida en el pie que no cicatriza o presenta mal olor/supuración.',
        'Visión borrosa repentina o mareos persistentes.',
        'Respiración rápida y profunda con olor a frutas en el aliento.',
        'Pérdida de sensibilidad en dedos o plantas de los pies.',
      ],
      nextSteps: 'Programa tu control mensual en el programa de crónicos del MINSA para monitoreo de glucosa y revisión de pies.',
    ),

    // 7. PRIMEROS AUXILIOS BÁSICOS (Heridas, Quemaduras y Desmayos)
    MinsaOfflineEntry(
      id: 'primeros_auxilios',
      title: 'Guía de Primeros Auxilios Básicos',
      normative: 'Guía Nacional de Primeros Auxilios MINSA',
      category: 'Emergencias y Traumatismos',
      keywords: [
        'primeros auxilios', 'herida', 'corte', 'sangrado', 'quemadura',
        'desmayo', 'caida', 'golpe', 'mordedura', 'picadura', 'hemorragia'
      ],
      summary: 'Acciones inmediatas y seguras ante accidentes o lesiones frecuentes en el hogar o la comunidad.',
      immediateCare: [
        'En quemaduras leves: colocar la zona afectada bajo agua limpia corriente a temperatura ambiente durante 10-15 minutos. No aplicar hielo.',
        'En heridas con sangrado: presionar directamente la herida con un paño limpio o gasa estéril de forma continua durante al menos 5 minutos.',
        'En desmayo: acostar a la persona boca arriba y elevar sus piernas 30 cm para favorecer el retorno de sangre al cerebro. Asegurar buena ventilación.',
      ],
      contraindications: [
        'NO aplicar pasta dental, manteca, café molido ni telarañas sobre quemaduras o heridas abiertas.',
        'NO retirar objetos clavados profundamente en el cuerpo; inmovilízalos y acude a urgencias.',
      ],
      alarmSigns: [
        'Sangrado que no se detiene después de 10 minutos de presión directa.',
        'Quemaduras que abarcan áreas grandes, rostro, manos o articulaciones.',
        'Pérdida del conocimiento tras un golpe fuerte en la cabeza.',
      ],
      nextSteps: 'Tras estabilizar la lesión inicial, traslada al paciente a la unidad de salud para curación estéril, sutura o vacuna antitetánica según el caso.',
    ),

    // 8. SALUD EMOCIONAL Y NICARAGUANISMOS POPULARES
    MinsaOfflineEntry(
      id: 'salud_emocional_glosario',
      title: 'Orientación en Salud Emocional y Términos Locales',
      normative: 'Estrategia Comunitaria de Salud Mental MINSA',
      category: 'Salud Emocional y Bienestar',
      keywords: [
        'acabangado', 'acabanga', 'triste', 'deprimido', 'desanimado',
        'desconchavado', 'achicopalado', 'angustia', 'ansiedad',
        'estres', 'nervios', 'panico', 'llanto'
      ],
      summary: 'Estar "acabangado" o "achicopalado" describe un estado de tristeza, nostalgia o desánimo emocional que impacta el bienestar físico general.',
      immediateCare: [
        'Hablar de tus sentimientos con un familiar o amigo de confianza.',
        'Realizar caminatas diarias al aire libre y mantener horarios regulares de sueño.',
        'Practicar respiraciones conscientes cuando sientas opresión o angustia.',
        'Mantener una rutina de actividades cotidianas sin exigirte de más.',
      ],
      contraindications: [
        'NO recurrir al alcohol o automedicación con sedantes para calmar la angustia.',
        'NO aislarse por períodos prolongados.',
      ],
      alarmSigns: [
        'Pensamientos persistentes de desesperanza o de hacerte daño.',
        'Incapacidad para levantarse de la cama o alimentarse durante días.',
        'Ataques de pánico con palpitaciones intensas y sensación de muerte inminente.',
      ],
      nextSteps: 'Solicita apoyo en el área de psicología o medicina general de tu centro de salud MINSA. El cuidado de la salud mental es un derecho fundamental.',
    ),
  ];

  static const MinsaOfflineEntry emergenciaCriticaGenerica = MinsaOfflineEntry(
    id: 'emergencia_critica',
    title: 'ALERTA DE EMERGENCIA MÉDICA INMEDIATA',
    normative: 'Protocolo Nacional de Urgencias Médicas MINSA',
    category: 'Emergencia Crítica',
    keywords: ['emergencia', 'urgencia', 'morir', 'grave', 'infarto'],
    isEmergency: true,
    summary: 'Los síntomas descritos sugieren una condición clínica de urgencia que requiere evaluación médica presencial inmediata.',
    immediateCare: [
      'Mantener la calma y colocar al paciente en posición de reposo seguro.',
      'No dejar a la persona sola bajo ninguna circunstancia.',
      'Aflojar la ropa apretada y asegurar una buena ventilación.',
    ],
    contraindications: [
      'NO darle líquidos ni alimentos si está inconsciente o vomitando.',
      'NO demorar el traslado esperando a que los síntomas pasen por sí solos.',
    ],
    alarmSigns: [
      'Dolor de pecho fuerte u opresivo.',
      'Dificultad severa para respirar o labios morados.',
      'Pérdida del conocimiento, convulsiones o confusión repentina.',
      'Sangrado abundante e incontrolable.',
    ],
    nextSteps: 'Llama de inmediato a una ambulancia (Cruz Blanca / Bomberos) o acude sin demora al hospital o centro de salud MINSA más próximo.',
  );
}
