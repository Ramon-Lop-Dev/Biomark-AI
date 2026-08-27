// Valida los datos médicos recibidos desde el cliente.
const { z } = require('zod');

const createMedicalRecordSchema = z.object({
  nombre_condicion: z.string().trim().min(1, "El campo 'nombre_condicion' es obligatorio"),
  fecha_diagnostico: z.string().date('fecha_diagnostico debe tener formato YYYY-MM-DD').optional(),
  notas: z.string().trim().max(2000).optional()
});

// Valores del enum severidad_alergia en Postgres.
const SEVERIDADES_ALERGIA = ['LEVE', 'MODERADA', 'SEVERA'];

const createAllergySchema = z.object({
  alergeno: z.string().trim().min(1, "El campo 'alergeno' es obligatorio"),
  severidad: z.enum(SEVERIDADES_ALERGIA, {
    error: `severidad debe ser una de: ${SEVERIDADES_ALERGIA.join(', ')}`
  }).default('LEVE').optional(),
  notas: z.string().trim().max(2000).optional()
});

const createMedicationSchema = z.object({
  nombre_medicamento: z.string().trim().min(1, "El campo 'nombre_medicamento' es obligatorio"),
  dosis: z.string().trim().max(200).optional(),
  frecuencia: z.string().trim().max(200).optional(),
  fecha_inicio: z.string().date('fecha_inicio debe tener formato YYYY-MM-DD').optional(),
  fecha_fin: z.string().date('fecha_fin debe tener formato YYYY-MM-DD').optional()
});

const createFamilyHistorySchema = z.object({
  parentesco: z.string().trim().min(1, "El campo 'parentesco' es obligatorio"),
  nombre_condicion: z.string().trim().min(1, "El campo 'nombre_condicion' es obligatorio"),
  notas: z.string().trim().max(2000).optional()
});

module.exports = {
  createMedicalRecordSchema,
  createAllergySchema,
  createMedicationSchema,
  createFamilyHistorySchema,
  SEVERIDADES_ALERGIA
};
