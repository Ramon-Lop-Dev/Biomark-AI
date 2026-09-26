// Repositorio para la tabla contenido_salud en Supabase.
const supabase = require('../../config/supabase');

// Lista contenidos publicados, opcionalmente filtrados por categoría o fuente.
const listarContenidos = async ({ categoria, fuente, limit = 20, offset = 0 } = {}) => {
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

// Semillas por defecto si la base de datos está offline o vacía.
const SEMILLAS_OFICIALES_FALLBACK = [
  {
    id: 'c1000000-0000-0000-0000-000000000001',
    titulo: 'Campaña Nacional de Vacunación y Detección Temprana de Dengue',
    descripcion: 'Medidas de prevención en hogares nicaragüenses y signos de alarma según la Normativa 004 del MINSA.',
    contenido: 'El Ministerio de Salud (MINSA) de Nicaragua reitera a las familias la importancia de inspeccionar pilas, barriles y techos para erradicar los criaderos del mosquito transmisor del dengue, zika y chikungunya. Ante síntomas como fiebre súbita, dolor detrás de los ojos, decaimiento o dolor abdominal intenso, no debe automedicarse con ácido acetilsalicílico ni antiinflamatorios no esteroideos; acuda de inmediato al puesto de salud más cercano.',
    categoria: 'PREVENCION',
    imagen_url: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000002',
    titulo: 'Pautas OPS/OMS para el Control de la Hipertensión en la Comunidad',
    descripcion: 'Recomendaciones de monitoreo y reducción de sodio para la protección cardiovascular.',
    contenido: 'La Organización Panamericana de la Salud (OPS) enfatiza que mantener la presión arterial por debajo de 130/80 mmHg reduce significativamente el riesgo de accidentes cerebrovasculares y daño renal. Se aconseja limitar el consumo de sal de mesa a menos de 5 gramos diarios, realizar al menos 150 minutos semanales de actividad aeróbica moderada y realizar controles periódicos de la frecuencia cardíaca y presión.',
    categoria: 'CARDIOVASCULAR',
    imagen_url: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
    fuente: 'OPS / OMS',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000003',
    titulo: 'Guía Alimentaria y Manejo Glucémico en Climas Cálidos',
    descripcion: 'Protocolo MINSA para personas con diabetes tipo 2 durante olas de calor en el Pacífico.',
    contenido: 'En temperaturas superiores a los 32°C, las personas con diabetes pueden presentar deshidratación acelerada que altera los niveles séricos de glucosa. El MINSA recomienda beber abundante agua purificada, priorizar verduras verdes frescas, tubérculos no procesados y mantener los medicamentos orales o insulina protegidos de la exposición directa al sol y a temperatura ambiente fresca.',
    categoria: 'NUTRICION',
    imagen_url: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
    fuente: 'MINSA Nicaragua',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  },
  {
    id: 'c1000000-0000-0000-0000-000000000004',
    titulo: 'Salud Respiratoria Infantil: Reconocimiento de Signos de Peligro',
    descripcion: 'Criterios de la OMS para la atención de infecciones respiratorias agudas en el primer nivel.',
    contenido: 'Durante los cambios de estación lluviosa, la OMS y el MINSA recomiendan vigilar la respiración rápida en lactantes y niños pequeños. Signos como tiraje subcostal (hundimiento de costillas), rechazo de alimentos o estridor en reposo constituyen una emergencia médica que exige valoración inmediata por el personal de salud.',
    categoria: 'PEDIATRIA',
    imagen_url: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=800&q=80',
    fuente: 'OMS',
    fecha_publicacion: new Date().toISOString(),
    estado: 'PUBLICADO'
  }
];

module.exports = {
  listarContenidos,
  buscarPorId,
  crearOActualizarContenido,
  SEMILLAS_OFICIALES_FALLBACK
};
