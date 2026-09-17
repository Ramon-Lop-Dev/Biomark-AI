-- Agrega soporte de aviso previo (anticipación de notificación) para recordatorios.
ALTER TABLE public.recordatorios
  ADD COLUMN IF NOT EXISTS aviso_previo TEXT NOT NULL DEFAULT 'AL_MOMENTO',
  ADD COLUMN IF NOT EXISTS fecha_notificacion TIMESTAMP WITH TIME ZONE;

-- Actualizar filas existentes donde fecha_notificacion sea nula
UPDATE public.recordatorios
  SET fecha_notificacion = fecha_programada
  WHERE fecha_notificacion IS NULL;

-- Índice para optimizar la consulta del scheduler que busca notificaciones pendientes
CREATE INDEX IF NOT EXISTS idx_recordatorios_pendientes_notificacion
  ON public.recordatorios (fecha_notificacion)
  WHERE estado = 'PENDIENTE';
