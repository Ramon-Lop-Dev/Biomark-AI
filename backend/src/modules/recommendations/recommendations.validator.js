// Validador de recomendaciones de salud con normativas del MINSA y RBAC.
const { z } = require('zod');

const CATEGORIAS_VALIDAS = [
  'dengue',
  'heatWave',
  'cardiovascular',
  'treatment',
  'minsaNotice',
  'diabetes',
  'respiratory'
];

const COLOR_POR_CATEGORIA = {
  dengue: '#EF4444',
  heatWave: '#0EA5E9',
  cardiovascular: '#E11D48',
  treatment: '#10B981',
  minsaNotice: '#6366F1',
  diabetes: '#F59E0B',
  respiratory: '#06B6D4'
};

const ICONO_POR_CATEGORIA = {
  dengue: 'shield',
  heatWave: 'water_drop',
  cardiovascular: 'favorite',
  treatment: 'medication',
  minsaNotice: 'campaign',
  diabetes: 'restaurant',
  respiratory: 'air'
};

const createRecommendationSchema = z.object({
  categoria: z.enum(CATEGORIAS_VALIDAS, {
    error: `La categoría debe ser una de: ${CATEGORIAS_VALIDAS.join(', ')}`
  }),
  titulo: z.string().trim().min(5, 'El título debe tener al menos 5 caracteres').max(200),
  resumen: z.string().trim().min(10, 'El resumen debe tener al menos 10 caracteres'),
  detalle_clinico: z.string().trim().min(15, 'El detalle clínico debe tener al menos 15 caracteres'),
  normativa_minsa: z.string().trim().min(5, 'La normativa MINSA de respaldo es obligatoria para validar la recomendación'),
  etiqueta: z.string().trim().min(3, 'La etiqueta descriptiva es obligatoria').max(100),
  icono: z.string().trim().optional(),
  color_hex: z.string().trim().optional(),
  puntos_clave: z.array(z.string().trim().min(3)).min(1, 'Debe incluir al menos un punto clave de prevención'),
  condiciones_diana: z.array(z.string().trim()).default([]),
  alertas_diana: z.array(z.string().trim()).default([]),
  municipios_objetivo: z.array(z.string().trim()).default([]),
  edad_minima: z.number().int().min(0).max(120).nullable().optional(),
  edad_maxima: z.number().int().min(0).max(120).nullable().optional(),
  estado: z.enum(['BORRADOR', 'PUBLICADO', 'ARCHIVADO']).default('PUBLICADO')
}).transform((data) => {
  // Garantizar el color e icono normativo MINSA según categoría
  return {
    ...data,
    color_hex: COLOR_POR_CATEGORIA[data.categoria] || '#6366F1',
    icono: data.icono || ICONO_POR_CATEGORIA[data.categoria] || 'shield'
  };
});

const updateRecommendationSchema = z.object({
  categoria: z.enum(CATEGORIAS_VALIDAS).optional(),
  titulo: z.string().trim().min(5).max(200).optional(),
  resumen: z.string().trim().min(10).optional(),
  detalle_clinico: z.string().trim().min(15).optional(),
  normativa_minsa: z.string().trim().min(5).optional(),
  etiqueta: z.string().trim().min(3).max(100).optional(),
  icono: z.string().trim().optional(),
  color_hex: z.string().trim().optional(),
  puntos_clave: z.array(z.string().trim().min(3)).min(1).optional(),
  condiciones_diana: z.array(z.string().trim()).optional(),
  alertas_diana: z.array(z.string().trim()).optional(),
  municipios_objetivo: z.array(z.string().trim()).optional(),
  edad_minima: z.number().int().min(0).max(120).nullable().optional(),
  edad_maxima: z.number().int().min(0).max(120).nullable().optional(),
  estado: z.enum(['BORRADOR', 'PUBLICADO', 'ARCHIVADO']).optional()
}).transform((data) => {
  if (data.categoria) {
    return {
      ...data,
      color_hex: COLOR_POR_CATEGORIA[data.categoria] || data.color_hex || '#6366F1',
      icono: data.icono || ICONO_POR_CATEGORIA[data.categoria] || 'shield'
    };
  }
  return data;
});

module.exports = {
  CATEGORIAS_VALIDAS,
  COLOR_POR_CATEGORIA,
  ICONO_POR_CATEGORIA,
  createRecommendationSchema,
  updateRecommendationSchema
};
