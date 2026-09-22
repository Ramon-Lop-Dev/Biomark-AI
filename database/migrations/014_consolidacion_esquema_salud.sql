-- ==============================================================================
-- Migración 014: Consolidación del Esquema de Salud y Optimización de Notificaciones
-- Proyecto: Biomark AI (Nicaragua - MINSA)
-- ==============================================================================
-- Objetivos:
-- 1. Unificar la redundancia entre 'sintomas' + 'registros_sintomas' y 'seguimiento_salud'.
-- 2. Dotar a 'seguimiento_salud' de columnas clínicas completas (temperatura, presión arterial, url_foto).
-- 3. Migrar datos existentes preservando integridad referencial.
-- 4. Optimizar la tabla 'notificaciones' para consultas de bandeja in-app (leída, índices de alto rendimiento).
-- 5. Definir gobernanza RBAC para roles ADMIN, PROMOTOR, TRABAJADOR_SALUD y USUARIO.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Potenciar 'seguimiento_salud' como tabla canónica clínica del usuario
-- ------------------------------------------------------------------------------
ALTER TABLE public.seguimiento_salud
  ADD COLUMN IF NOT EXISTS temperatura numeric(4,1),
  ADD COLUMN IF NOT EXISTS presion_arterial text,
  ADD COLUMN IF NOT EXISTS url_foto text;

-- Si el check de estado requería valores estrictos anteriores, aseguramos soporte
-- para los estados reportados en la app (MEJORO, IGUAL, EMPEORO, NO_SEGURO, MEJORANDO, EMPEORANDO)
ALTER TABLE public.seguimiento_salud
  DROP CONSTRAINT IF EXISTS seguimiento_salud_estado_check;

ALTER TABLE public.seguimiento_salud
  ADD CONSTRAINT seguimiento_salud_estado_check
  CHECK (estado = ANY (ARRAY[
    'MEJORO'::text,
    'MEJORANDO'::text,
    'IGUAL'::text,
    'EMPEORO'::text,
    'EMPEORANDO'::text,
    'NO_SEGURO'::text
  ]));

CREATE INDEX IF NOT EXISTS idx_seguimiento_salud_usuario_fecha
  ON public.seguimiento_salud (usuario_id, fecha_registro DESC);

CREATE INDEX IF NOT EXISTS idx_seguimiento_salud_sintoma
  ON public.seguimiento_salud (usuario_id, sintoma);

-- ------------------------------------------------------------------------------
-- 2. Migrar datos históricos de 'registros_sintomas' hacia 'seguimiento_salud'
-- ------------------------------------------------------------------------------
INSERT INTO public.seguimiento_salud (
  usuario_id,
  sintoma,
  estado,
  intensidad,
  notas,
  temperatura,
  presion_arterial,
  url_foto,
  fecha_registro
)
SELECT
  s.usuario_id,
  s.nombre_sintoma,
  'NO_SEGURO',
  5,
  r.notas,
  r.temperatura,
  r.presion_arterial,
  r.url_foto,
  r.fecha_registro
FROM public.registros_sintomas r
JOIN public.sintomas s ON r.sintoma_id = s.id
WHERE NOT EXISTS (
  SELECT 1 FROM public.seguimiento_salud ss
  WHERE ss.usuario_id = s.usuario_id
    AND ss.sintoma = s.nombre_sintoma
    AND ss.fecha_registro = r.fecha_registro
);

-- ------------------------------------------------------------------------------
-- 3. Optimizar la tabla 'notificaciones' para la bandeja in-app del usuario
-- ------------------------------------------------------------------------------
ALTER TABLE public.notificaciones
  ADD COLUMN IF NOT EXISTS leida boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS titulo text,
  ADD COLUMN IF NOT EXISTS datos_adicionales jsonb DEFAULT '{}'::jsonb;

-- Sincronizar columna leida según fecha_lectura previa
UPDATE public.notificaciones
SET leida = true
WHERE fecha_lectura IS NOT NULL AND leida = false;

CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida_fecha
  ON public.notificaciones (usuario_id, leida, fecha_creacion DESC);

CREATE INDEX IF NOT EXISTS idx_notificaciones_tipo
  ON public.notificaciones (tipo);

-- ------------------------------------------------------------------------------
-- 4. Gobernanza de Roles (RBAC y Políticas RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.seguimiento_salud ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reportes_comunitarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos_comunitarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zonas_riesgo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alertas_epidemiologicas ENABLE ROW LEVEL SECURITY;

-- Políticas de seguimiento_salud: cada usuario ve y edita solo su salud
DROP POLICY IF EXISTS p_seguimiento_salud_propio ON public.seguimiento_salud;
CREATE POLICY p_seguimiento_salud_propio ON public.seguimiento_salud
  FOR ALL
  TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Políticas de notificaciones: usuario lee y actualiza estado de sus notificaciones
DROP POLICY IF EXISTS p_notificaciones_usuario ON public.notificaciones;
CREATE POLICY p_notificaciones_usuario ON public.notificaciones
  FOR SELECT
  TO authenticated
  USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS p_notificaciones_update ON public.notificaciones;
CREATE POLICY p_notificaciones_update ON public.notificaciones
  FOR UPDATE
  TO authenticated
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Vistas públicas y lectura comunitaria
DROP POLICY IF EXISTS p_eventos_comunitarios_lectura ON public.eventos_comunitarios;
CREATE POLICY p_eventos_comunitarios_lectura ON public.eventos_comunitarios
  FOR SELECT
  TO authenticated
  USING (activo = true);

DROP POLICY IF EXISTS p_zonas_riesgo_lectura ON public.zonas_riesgo;
CREATE POLICY p_zonas_riesgo_lectura ON public.zonas_riesgo
  FOR SELECT
  TO authenticated
  USING (activo = true);

DROP POLICY IF EXISTS p_alertas_epidemiologicas_lectura ON public.alertas_epidemiologicas;
CREATE POLICY p_alertas_epidemiologicas_lectura ON public.alertas_epidemiologicas
  FOR SELECT
  TO authenticated
  USING (fecha_expiracion IS NULL OR fecha_expiracion > now());

COMMIT;
