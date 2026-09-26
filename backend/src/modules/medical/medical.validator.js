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

const replaceSurveySchema = z.object({
  enfermedades_cronicas: z.array(z.string().trim().min(1)).default([]),
  antecedentes_hereditarios: z.array(z.string().trim().min(1)).default([]),
  alergias: z.array(z.string().trim().min(1)).default([]),
  medicamentos: z.string().trim().max(2000).default('')
});

const interviewSchema = z.object({
  fecha_nacimiento: z.string().date('fecha_nacimiento debe tener formato YYYY-MM-DD').optional(),
  edad: z.number().int().min(0).max(120).optional(),
  sexo: z.string().trim().min(1),
  peso: z.number().min(1).max(500).optional(),
  altura: z.number().min(30).max(300).optional(),
  enfermedades_cronicas: z.array(z.string().trim()).default([]),
  antecedentes_hereditarios: z.array(z.string().trim()).default([]),
  alergias: z.array(z.string().trim()).default([]),
  medicamentos: z.string().trim().default(''),
  fuma: z.string().trim().default('NO'),
  alcohol: z.string().trim().default('NO'),
  actividad_fisica: z.string().trim().default('MODERADA'),
  vacunas: z.array(z.string().trim()).default([])
});

module.exports = {
  createMedicalRecordSchema,
  createAllergySchema,
  createMedicationSchema,
  createFamilyHistorySchema,
  replaceSurveySchema,
  interviewSchema,
  SEVERIDADES_ALERGIA
};
