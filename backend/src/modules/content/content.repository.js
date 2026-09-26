// Repositorio para la tabla contenido_salud en Supabase.
const supabase = require('../../config/supabase');

// Lista contenidos publicados, opcionalmente filtrados por categoría, fuente o condición médica.
const listarContenidos = async ({ categoria, fuente, condicion, limit = 20, offset = 0 } = {}) => {
  let query = supabase
    .from('contenido_salud')
    .select('*')
    .eq('estado', 'PUBLICADO')
    .order('fecha_publicacion', { ascending: false })
    .range(offset, offset + limit - 1);

  if (categoria && categoria.trim().toUpperCase() !== 'TODAS') {
    query = query.ilike('categoria', `%${categoria.trim()}%`);
  }

  if (fuente && fuente.trim()) {
    query = query.ilike('fuente', `%${fuente.trim()}%`);
  }

  if (condicion && condicion.trim()) {
    const term = condicion.trim().toLowerCase();
    query = query.or(`condiciones_objetivo.cs.{"${term}"},titulo.ilike.%${term}%,descripcion.ilike.%${term}%`);
  }

  return query;
};

const buscarPorId = async (id) =>
  supabase
    .from('contenido_salud')
    .select('*')
    .eq('id', id)
    .single();

// Inserción o actualización desacoplada (usado por servicios de ingesta / n8n / admin).
const crearOActualizarContenido = async (payload) =>
  supabase
    .from('contenido_salud')
    .upsert({
      ...payload,
      fecha_actualizacion: new Date().toISOString()
    })
    .select()
    .single();

// Semillas oficiales verificadas del MINSA Nicaragua, OPS y OMS con gobernanza sanitaria.
const SEMILLAS_OFICIALES_FALLBACK = [
  {
    id: 'c1000000-0000-0000-0000-000000000001',
    titulo: 'Alerta Epidemiológica: Prevención Activa de Dengue en Managua',
    descripcion: 'Medidas de prevención en hogares nicaragüenses y signos de alarma según la Normativa 004 del MINSA.',
    contenido: 'El Ministerio de Salud (MINSA) de Nicaragua reitera a las familias la importancia de inspeccionar pilas, barriles y techos para erradicar los criaderos del mosquito transmisor del dengue, zika y chikungunya. Ante síntomas como fiebre súbita, dolor detrás de los ojos, decaimiento o dolor abdominal intenso, no debe automedicarse con ácido acetilsalicílico ni antiinflamatorios no esteroideos; acuda de inmediato al puesto de salud más cercano.',
    categoria: 'PREVENCION',
    imagen_url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    normativa_codigo: 'Normativa 004 - Protocolo Nacional de Vigilancia Arbovirosis',
    normativa_url: 'http://minsa.gob.ni',
    tipo_aviso: 'ALERTA_EPIDEMIOLOGICA',
    prioridad: 'ALTA',
    alcance_tipo: 'GENERAL',
    condiciones_objetivo: ['dengue', 'fiebre', 'infeccion', 'general'],
    barrio_comunidad: 'Managua',
    silais: 'SILAIS Managua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000002',
    titulo: 'Guía MINSA: Control de la Hipertensión en la Comunidad',
    descripcion: 'Protocolo de control de presión y reducción de sodio según la Normativa 084 del MINSA.',
    contenido: 'El Ministerio de Salud de Nicaragua establece en la Normativa 084 que los pacientes hipertensos deben registrar sus cifras matutinas y nocturnas. Reduzca el consumo de sodio a menos de 5 gramos diarios, evite frituras y camine al menos 30 minutos al día. Acuda a su puesto médico barrial para retiro de tratamiento mensual.',
    categoria: 'CARDIOVASCULAR',
    imagen_url: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    normativa_codigo: 'Normativa 084 - Abordaje Clínico de la Hipertensión',
    normativa_url: 'http://minsa.gob.ni',
    tipo_aviso: 'NORMATIVA',
    prioridad: 'ALTA',
    alcance_tipo: 'CONDICION',
    condiciones_objetivo: ['hipertension', 'hipertensión', 'presion alta', 'presión arterial', 'cardiovascular'],
    barrio_comunidad: 'Managua',
    silais: 'SILAIS Managua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000003',
    titulo: 'Cuidados del Pie y Manejo Glucémico en Diabetes Tipo 2',
    descripcion: 'Pautas del Programa de Enfermedades Crónicas del MINSA y Normativa 077.',
    contenido: 'Revise diariamente sus pies entre los dedos para evitar úlceras o heridas no percibidas. Mantenga una hidratación constante y respete los horarios de toma de medicamentos orales o insulina sin suspenderlos de manera abrupta.',
    categoria: 'NUTRICION',
    imagen_url: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    normativa_codigo: 'Normativa 077 - Atención Integral a la Diabetes Mellitus',
    normativa_url: 'http://minsa.gob.ni',
    tipo_aviso: 'NORMATIVA',
    prioridad: 'ALTA',
    alcance_tipo: 'CONDICION',
    condiciones_objetivo: ['diabetes', 'glucosa', 'azucar en sangre', 'cronica'],
    barrio_comunidad: 'Managua',
    silais: 'SILAIS Managua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000004',
    titulo: 'Jornada Barrial de Vacunación Comunitaria y Atención Médica',
    descripcion: 'Clínicas móviles del MINSA en distritos de Managua brindando atención gratuita.',
    contenido: 'Personal de salud del SILAIS Managua brinda atención médica preventiva, toma de signos vitales, control prenatal y aplicación de esquemas de vacunas. Consulte la ubicación exacta en el mapa asistencial de Biomark AI.',
    categoria: 'PREVENCION',
    imagen_url: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    normativa_codigo: 'Modelo MOSAFC - Salud Familiar y Comunitaria',
    normativa_url: 'http://minsa.gob.ni',
    tipo_aviso: 'JORNADA_VACUNACION',
    prioridad: 'MEDIA',
    alcance_tipo: 'GENERAL',
    condiciones_objetivo: ['vacunacion', 'salud preventiva', 'jornada'],
    barrio_comunidad: 'Managua',
    silais: 'SILAIS Managua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000005',
    titulo: 'Vigilancia Respiratoria: Signos de Alarma en Asma',
    descripcion: 'Criterios de la Normativa 062 para la atención oportuna de crisis respiratorias.',
    contenido: 'Durante cambios de clima en Managua, los pacientes con asma deben identificar a tiempo signos como tiraje subcostal o falta de aire al reposo. Tenga a mano su inhalador y no dude en acudir al centro de salud.',
    categoria: 'PEDIATRIA',
    imagen_url: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    normativa_codigo: 'Normativa 062 - Infecciones Respiratorias y Asma',
    normativa_url: 'http://minsa.gob.ni',
    tipo_aviso: 'NORMATIVA',
    prioridad: 'MEDIA',
    alcance_tipo: 'CONDICION',
    condiciones_objetivo: ['asma', 'alergia', 'respiratorio', 'tos'],
    barrio_comunidad: 'Managua',
    silais: 'SILAIS Managua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  }
];

const filtrarFallback = ({ categoria, fuente, condicion } = {}) => {
  return SEMILLAS_OFICIALES_FALLBACK.filter((item) => {
    if (categoria && categoria.trim().toUpperCase() !== 'TODAS') {
      if (!item.categoria.toLowerCase().includes(categoria.trim().toLowerCase())) return false;
    }
    if (fuente && fuente.trim()) {
      if (!item.fuente.toLowerCase().includes(fuente.trim().toLowerCase())) return false;
    }
    if (condicion && condicion.trim()) {
      const term = condicion.trim().toLowerCase();
      const matchCond = (item.condiciones_objetivo || []).some(c => c.toLowerCase().includes(term));
      const matchText = item.titulo.toLowerCase().includes(term) || item.descripcion.toLowerCase().includes(term);
      if (!matchCond && !matchText) return false;
    }
    return true;
  });
};

module.exports = {
  listarContenidos,
  buscarPorId,
  crearOActualizarContenido,
  SEMILLAS_OFICIALES_FALLBACK,
  filtrarFallback
};
