// Repositorio de recomendaciones de salud con persistencia y fallback.
const supabase = require('../../config/supabase');

const SEMILLAS_OFICIALES = [
  {
    id: 'a1000000-0000-0000-0000-000000000001',
    categoria: 'dengue',
    titulo: 'Prevención Activa de Dengue y Arbovirosis',
    resumen: 'Elimina criaderos en recipientes con agua y reconoce signos de alarma tempranos.',
    detalle_clinico: 'El zancudo Aedes aegypti se reproduce en agua limpia estancada. Las lluvias en Nicaragua aumentan el riesgo de transmisión comunitaria. La detección oportuna previene el dengue grave.',
    normativa_minsa: 'Normativa 004 MINSA - Protocolo de Abordaje del Dengue',
    etiqueta: 'Salud Vectorial MINSA',
    icono: 'shield',
    color_hex: '#EF4444',
    puntos_clave: [
      'Lava y cepilla pilas, barriles y floreros al menos dos veces por semana.',
      'Desecha llantas viejas, latas y recipientes que acumulen agua de lluvia.',
      'Permite el ingreso a brigadistas de fumigación y aplicación de BTI.',
      'Signos de alarma: dolor abdominal intenso, vómitos persistentes y somnolencia.',
      '¡No te automediques! Evita la aspirina o el ibuprofeno ante fiebre.'
    ],
    condiciones_diana: ['fiebre', 'dengue', 'infeccion'],
    alertas_diana: ['dengue', 'arbovirosis', 'malaria'],
    municipios_objetivo: [],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  },
  {
    id: 'a1000000-0000-0000-0000-000000000002',
    categoria: 'heatWave',
    titulo: 'Hidratación y Prevención de Golpe de Calor',
    resumen: 'Pautas de reposición hídrica en temperaturas superiores a 30°C.',
    detalle_clinico: 'En las regiones del Pacífico y Centro de Nicaragua, las temperaturas elevadas incrementan la pérdida hídrica dérmica y el riesgo de insolación en niños y adultos mayores.',
    normativa_minsa: 'Guía Técnica MINSA para Emergencias Climáticas',
    etiqueta: 'Clima y Termorregulación',
    icono: 'water_drop',
    color_hex: '#0EA5E9',
    puntos_clave: [
      'Consume entre 2.5 y 3 litros de agua potable distribuida a lo largo del día.',
      'Evita la exposición solar directa entre las 11:00 AM y 3:00 PM.',
      'Usa ropa holgada, de algodón y colores claros con protección solar o sombrero.',
      'Ten a mano sales de rehidratación oral (Sobres MINSA) ante signos de deshidratación.',
      'Atención especial a adultos mayores: pueden perder la sensación de sed.'
    ],
    condiciones_diana: ['hipertension', 'renal'],
    alertas_diana: ['calor', 'sequia', 'ola_de_calor'],
    municipios_objetivo: ['Managua', 'León', 'Chinandega'],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  },
  {
    id: 'a1000000-0000-0000-0000-000000000003',
    categoria: 'cardiovascular',
    titulo: 'Salud Cardiovascular y Control del Pulso',
    resumen: 'Monitorea tu frecuencia cardíaca y reconoce los valores normales en reposo.',
    detalle_clinico: 'El pulso refleja el ritmo y gasto cardíaco. Una frecuencia regular entre 60 y 100 BPM en reposo indica un funcionamiento cardiovascular dentro de los parámetros esperados.',
    normativa_minsa: 'Protocolo de Prevención de Enfermedades Crónicas MINSA',
    etiqueta: 'Cardiovascular',
    icono: 'favorite',
    color_hex: '#E11D48',
    puntos_clave: [
      'El pulso normal en adultos en reposo oscila entre 60 y 100 latidos por minuto.',
      'Factores como el estrés, cafeína, tabaco y fiebre pueden acelerar el pulso temporalmente.',
      'Mide tu pulso con la función de sismocardiografía o PPG de Biomark AI luego de reposar 5 minutos.',
      'Consulta si experimentas palpitaciones recurrentes, mareos o sensación de desmayo.',
      'La actividad física moderada diaria fortalece el miocardio.'
    ],
    condiciones_diana: ['hipertension', 'arritmia', 'cardiopatia', 'insuficiencia_cardiaca'],
    alertas_diana: [],
    municipios_objetivo: [],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  },
  {
    id: 'a1000000-0000-0000-0000-000000000004',
    categoria: 'treatment',
    titulo: 'Adherencia al Tratamiento Farmacológico',
    resumen: 'No interrumpas ni modifiques dosis prescritas por tu médico tratante.',
    detalle_clinico: 'El abandono temprano de tratamientos para hipertensión, diabetes o infecciones es una causa común de recaídas y complicaciones graves.',
    normativa_minsa: 'Estrategia de Uso Racional de Medicamentos MINSA',
    etiqueta: 'Farmacovigilancia',
    icono: 'medication',
    color_hex: '#10B981',
    puntos_clave: [
      'Toma tus medicamentos todos los días a la misma hora para mantener niveles estables.',
      'Nunca suspendas antibióticos antes de la fecha indicada por el médico.',
      'Configura recordatorios en la pestaña de Recordatorios de Biomark AI.',
      'Guarda las medicinas en un lugar fresco, seco y fuera del alcance de los niños.',
      'Si sientes molestias o efectos secundarios, comunícate con tu centro de salud.'
    ],
    condiciones_diana: ['hipertension', 'diabetes', 'asma', 'infeccion'],
    alertas_diana: [],
    municipios_objetivo: [],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  },
  {
    id: 'a1000000-0000-0000-0000-000000000005',
    categoria: 'diabetes',
    titulo: 'Control Glucémico y Cuidado Integral en Diabetes',
    resumen: 'Pautas para la prevención de picos glucémicos y cuidado de miembros inferiores.',
    detalle_clinico: 'La diabetes mellitus requiere monitoreo dietético, ejercicio regular y revisión periódica de los pies para evitar el pie diabético y daños vasculares.',
    normativa_minsa: 'Normativa 078 MINSA - Manejo de la Diabetes Mellitus',
    etiqueta: 'Metabólica y Nutrición',
    icono: 'restaurant',
    color_hex: '#F59E0B',
    puntos_clave: [
      'Reduce el consumo de azúcares refinados, bebidas azucaradas y harinas procesadas.',
      'Revisa tus pies diariamente en busca de pequeñas heridas, grietas o cambios de coloración.',
      'Mantén un horario regular de comidas y no te saltes el desayuno.',
      'Realiza al menos 30 minutos de caminata diaria si tu médico lo autoriza.',
      'Acude a tus controles periódicos de hemoglobina glucosilada (HbA1c) en tu centro de salud.'
    ],
    condiciones_diana: ['diabetes', 'diabetes_mellitus', 'obesidad', 'glucosa'],
    alertas_diana: [],
    municipios_objetivo: [],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  },
  {
    id: 'a1000000-0000-0000-0000-000000000006',
    categoria: 'respiratory',
    titulo: 'Prevención de Infecciones Respiratorias y Manejo del Asma',
    resumen: 'Protege tus vías respiratorias ante cambios de clima y polvo ambiental.',
    detalle_clinico: 'Las infecciones respiratorias agudas (IRA) y las crisis asmáticas aumentan durante los cambios estacionales de lluvia a época seca en Nicaragua.',
    normativa_minsa: 'Normativa 028 MINSA - Abordaje de Infecciones Respiratorias Agudas',
    etiqueta: 'Salud Respiratoria',
    icono: 'air',
    color_hex: '#06B6D4',
    puntos_clave: [
      'Cúbrete la boca y nariz con el ángulo interno del codo al toser o estornudar.',
      'Evita la exposición al humo de leña, cigarrillo y quemas de basura.',
      'Identifica los desencadenantes de tu asma: polvo, polen, cambios bruscos de temperatura.',
      'Ten siempre a mano tu inhalador de rescate según la indicación médica.',
      'Acude de inmediato si presentas dificultad para respirar, hundimiento de costillas o labios azulados.'
    ],
    condiciones_diana: ['asma', 'epoc', 'bronquitis', 'alergia_respiratoria'],
    alertas_diana: ['respiratorio', 'influenza', 'infeccion_respiratoria'],
    municipios_objetivo: [],
    estado: 'PUBLICADO',
    fecha_creacion: '2026-01-01T00:00:00Z'
  }
];

// Fallback en memoria para almacenar tarjetas añadidas dinámicamente cuando
// la tabla aún no se ha sincronizado en Supabase
const fallbackStore = [...SEMILLAS_OFICIALES];

const listarRecomendaciones = async ({ categoria, estado = 'PUBLICADO' } = {}) => {
  try {
    let query = supabase
      .from('recomendaciones_salud')
      .select('*')
      .order('fecha_creacion', { ascending: false });

    if (estado) {
      query = query.eq('estado', estado);
    }
    if (categoria) {
      query = query.eq('categoria', categoria);
    }

    const { data, error } = await query;
    if (!error && Array.isArray(data) && data.length > 0) {
      return { data, error: null };
    }
    // Si la tabla no existe en la base o está vacía, retornar fallback
    let filtradas = fallbackStore;
    if (estado) filtradas = filtradas.filter((r) => r.estado === estado);
    if (categoria) filtradas = filtradas.filter((r) => r.categoria === categoria);
    return { data: filtradas, error: null };
  } catch (_) {
    return { data: fallbackStore, error: null };
  }
};

const obtenerRecomendacionPorId = async (id) => {
  try {
    const { data, error } = await supabase
      .from('recomendaciones_salud')
      .select('*')
      .eq('id', id)
      .single();

    if (!error && data) return { data, error: null };
    const local = fallbackStore.find((r) => r.id === id);
    return { data: local || null, error: null };
  } catch (_) {
    const local = fallbackStore.find((r) => r.id === id);
    return { data: local || null, error: null };
  }
};

const crearRecomendacion = async (creadoPor, datos) => {
  const payload = {
    ...datos,
    creado_por: creadoPor,
    fecha_creacion: new Date().toISOString(),
    fecha_actualizacion: new Date().toISOString()
  };

  try {
    const { data, error } = await supabase
      .from('recomendaciones_salud')
      .insert([payload])
      .select();

    if (!error && data && data.length > 0) {
      return { data: data[0], error: null };
    }
  } catch (_) {}

  // Respaldo en store de memoria
  const nuevoRegistro = {
    ...payload,
    id: `local-${Date.now()}`
  };
  fallbackStore.unshift(nuevoRegistro);
  return { data: nuevoRegistro, error: null };
};

const actualizarRecomendacion = async (id, datos) => {
  const payload = {
    ...datos,
    fecha_actualizacion: new Date().toISOString()
  };

  try {
    const { data, error } = await supabase
      .from('recomendaciones_salud')
      .update(payload)
      .eq('id', id)
      .select();

    if (!error && data && data.length > 0) {
      return { data: data[0], error: null };
    }
  } catch (_) {}

  const index = fallbackStore.findIndex((r) => r.id === id);
  if (index !== -1) {
    fallbackStore[index] = { ...fallbackStore[index], ...payload };
    return { data: fallbackStore[index], error: null };
  }
  return { data: null, error: new Error('Recomendación no encontrada') };
};

const eliminarRecomendacion = async (id) => {
  try {
    await supabase.from('recomendaciones_salud').delete().eq('id', id);
  } catch (_) {}

  const index = fallbackStore.findIndex((r) => r.id === id);
  if (index !== -1) {
    fallbackStore.splice(index, 1);
  }
  return { success: true };
};

module.exports = {
  SEMILLAS_OFICIALES,
  listarRecomendaciones,
  obtenerRecomendacionPorId,
  crearRecomendacion,
  actualizarRecomendacion,
  eliminarRecomendacion
};
