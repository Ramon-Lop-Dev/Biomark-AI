-- Migración 018: Campos extendidos para reportes comunitarios MINSA
-- Fecha: 2026-09-26
-- Descripción: Agrega campos adicionales al formulario de reporte comunitario
--   para cumplir con los requerimientos de vigilancia epidemiológica del MINSA/SILAIS.
-- Seguro (IF NOT EXISTS): no afecta instalaciones que ya tienen las columnas.

ALTER TABLE reportes_comunitarios
  ADD COLUMN IF NOT EXISTS tipo_enfermedad TEXT
    CHECK (tipo_enfermedad IN ('Dengue', 'Zika', 'Chikungunya', 'Leptospirosis', 'IRA', 'COVID-19', 'Otro')),
  ADD COLUMN IF NOT EXISTS direccion_exacta TEXT,
  ADD COLUMN IF NOT EXISTS fecha_inicio_sintomas DATE,
  ADD COLUMN IF NOT EXISTS medidas_tomadas TEXT,
  ADD COLUMN IF NOT EXISTS contacto_reportante TEXT;

-- Índice para facilitar búsquedas por tipo de enfermedad en el panel de vigilancia
CREATE INDEX IF NOT EXISTS idx_reportes_comunitarios_tipo_enfermedad
  ON reportes_comunitarios (tipo_enfermedad)
  WHERE tipo_enfermedad IS NOT NULL;
