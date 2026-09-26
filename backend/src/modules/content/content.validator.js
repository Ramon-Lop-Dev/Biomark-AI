const { z } = require('zod');

const queryContentSchema = z.object({
  categoria: z.string().trim().max(100).optional(),
  fuente: z.string().trim().max(100).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0)
});

const ingestContentSchema = z.object({
  id: z.string().uuid().optional(),
  titulo: z.string().trim().min(5, 'titulo debe tener al menos 5 caracteres').max(300),
  descripcion: z.string().trim().min(10, 'descripcion requerida'),
  contenido: z.string().trim().min(20, 'contenido clínico requerido'),
  categoria: z.string().trim().min(2).max(100),
  imagen_url: z.string().url().optional().nullable(),
  fuente: z.enum(['MINSA Nicaragua', 'OPS', 'OMS', 'OPS / OMS', 'MINSA / OPS']),
  estado: z.enum(['BORRADOR', 'PUBLICADO', 'ARCHIVADO']).default('PUBLICADO')
});

module.exports = {
  queryContentSchema,
  ingestContentSchema
};
