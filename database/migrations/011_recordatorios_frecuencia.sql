-- Agrega soporte de recurrencia/frecuencia para recordatorios y optimiza consultas de pendientes.
-- En PostgreSQL, los comandos ALTER TYPE ... ADD VALUE no deben ejecutarse dentro de bloques DO $$.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'frecuencia_recordatorio') THEN
    CREATE TYPE frecuencia_recordatorio AS ENUM ('UNA_VEZ', 'HORARIA', 'DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL');
  END IF;
END $$;

ALTER TYPE frecuencia_recordatorio ADD VALUE IF NOT EXISTS 'HORARIA';
ALTER TYPE frecuencia_recordatorio ADD VALUE IF NOT EXISTS 'QUINCENAL';

ALTER TABLE public.recordatorios
  ADD COLUMN IF NOT EXISTS frecuencia frecuencia_recordatorio NOT NULL DEFAULT 'UNA_VEZ';

CREATE INDEX IF NOT EXISTS idx_recordatorios_pendientes_fecha
  ON public.recordatorios (fecha_programada)
  WHERE estado = 'PENDIENTE';

