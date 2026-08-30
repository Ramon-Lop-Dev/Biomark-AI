// Valida cargas y niveles del módulo epidemiológico.
const { z } = require('zod');

// Valores del enum nivel_riesgo en Postgres. Usado tanto por
// alertas_epidemiologicas.nivel_alerta como por
// zonas_riesgo.nivel_riesgo_actual.
const NIVELES_RIESGO = ['BAJO', 'MODERADO', 'ALTO', 'CRITICO'];

// reportes_epidemiologicos: ingestión de un reporte crudo (de MINSA,
// jornada de salud, u otra fuente oficial) antes de que derive en una
// alerta. No lleva "cargado_por" en el body: se toma de req.usuarioId,
// igual que en el resto de los módulos.
const createReportSchema = z.object({
  fuente: z.string().trim().min(1, "El campo 'fuente' es obligatorio"),
  enfermedad: z.string().trim().min(1, "El campo 'enfermedad' es obligatorio"),
  municipio: z.string().trim().min(1, "El campo 'municipio' es obligatorio"),
  fecha_reporte: z.string().date('fecha_reporte debe tener formato YYYY-MM-DD')
});

// alertas_epidemiologicas: siempre nace de un reporte epidemiológico ya
// existente y apunta a una zona de riesgo ya existente (ambas FKs son
// NOT NULL en el schema).
const createAlertSchema = z.object({
  reporte_epidemiologico_id: z.string().uuid('reporte_epidemiologico_id debe ser un UUID válido'),
  zona_riesgo_id: z.string().uuid('zona_riesgo_id debe ser un UUID válido'),
  nivel_alerta: z.enum(NIVELES_RIESGO, {
    error: `nivel_alerta debe ser uno de: ${NIVELES_RIESGO.join(', ')}`
  }),
  mensaje: z.string().trim().min(1, "El campo 'mensaje' es obligatorio"),
  fecha_expiracion: z.string().datetime().optional()
});

// zonas_riesgo.nivel_riesgo_actual: único campo de esta tabla que hoy
// nadie podía actualizar desde la API.
const updateRiskZoneLevelSchema = z.object({
  nivel_riesgo_actual: z.enum(NIVELES_RIESGO, {
    error: `nivel_riesgo_actual debe ser uno de: ${NIVELES_RIESGO.join(', ')}`
  })
});

module.exports = {
  createReportSchema,
  createAlertSchema,
  updateRiskZoneLevelSchema,
  NIVELES_RIESGO
};
