-- Migra mapa, alertas, integridad e índices para operación en Supabase.
-- Ejecutar después de verificar los enums existentes en Supabase.

ALTER TABLE public.eventos_comunitarios
  ADD COLUMN IF NOT EXISTS latitud numeric,
  ADD COLUMN IF NOT EXISTS longitud numeric,
  ADD COLUMN IF NOT EXISTS tipo text,
  ADD COLUMN IF NOT EXISTS radio_notificacion_km numeric NOT NULL DEFAULT 5;

ALTER TABLE public.alertas_epidemiologicas
  ADD COLUMN IF NOT EXISTS fecha_expiracion timestamp with time zone;

CREATE INDEX IF NOT EXISTS idx_historial_medico_usuario ON public.historial_medico(usuario_id);
CREATE INDEX IF NOT EXISTS idx_alergias_usuario ON public.alergias(usuario_id);
CREATE INDEX IF NOT EXISTS idx_medicamentos_usuario ON public.medicamentos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_antecedentes_usuario ON public.antecedentes_familiares(usuario_id);
CREATE INDEX IF NOT EXISTS idx_vacunas_usuario ON public.vacunas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_sintomas_usuario ON public.sintomas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_registros_sintomas_sintoma ON public.registros_sintomas(sintoma_id);
CREATE INDEX IF NOT EXISTS idx_eventos_medicos_usuario ON public.eventos_medicos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_imagenes_medicas_evento ON public.imagenes_medicas(evento_medico_id);
CREATE INDEX IF NOT EXISTS idx_recordatorios_estado_fecha ON public.recordatorios(estado, fecha_programada);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_lectura ON public.notificaciones(usuario_id, fecha_lectura);
CREATE INDEX IF NOT EXISTS idx_mensajes_chat_sesion_fecha ON public.mensajes_chat(sesion_chat_id, fecha_creacion);
CREATE INDEX IF NOT EXISTS idx_reportes_comunitarios_estado ON public.reportes_comunitarios(estado);
CREATE INDEX IF NOT EXISTS idx_registros_auditoria_entidad ON public.registros_auditoria(tipo_entidad, id_entidad);
CREATE INDEX IF NOT EXISTS idx_registros_auditoria_fecha ON public.registros_auditoria(fecha_creacion);
CREATE INDEX IF NOT EXISTS idx_eventos_comunitarios_fecha ON public.eventos_comunitarios(fecha_evento);

ALTER TABLE public.medicamentos
  DROP CONSTRAINT IF EXISTS chk_fechas_medicamento;
ALTER TABLE public.medicamentos
  ADD CONSTRAINT chk_fechas_medicamento
  CHECK (fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio);

ALTER TABLE public.vacunas
  DROP CONSTRAINT IF EXISTS chk_vacunas_numero_dosis;
ALTER TABLE public.vacunas
  ADD CONSTRAINT chk_vacunas_numero_dosis CHECK (numero_dosis > 0);

ALTER TABLE public.eventos_comunitarios
  DROP CONSTRAINT IF EXISTS chk_eventos_comunitarios_coordenadas;
ALTER TABLE public.eventos_comunitarios
  ADD CONSTRAINT chk_eventos_comunitarios_coordenadas
  CHECK ((latitud IS NULL AND longitud IS NULL) OR (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180));
