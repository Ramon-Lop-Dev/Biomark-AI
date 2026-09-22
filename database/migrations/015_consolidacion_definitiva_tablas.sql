-- ==============================================================================
-- Migración 015: Consolidación Definitiva de Tablas y Soporte Integral Managua
-- Proyecto: Biomark AI
-- ==============================================================================
-- Objetivos:
-- 1. Consolidar 'sintomas' y 'registros_sintomas' en 'seguimiento_salud'.
-- 2. Consolidar 'reportes_epidemiologicos' y 'zonas_riesgo' en 'alertas_epidemiologicas'.
-- 3. Poblar geog en todos los centros de salud de Managua para PostGIS.
-- 4. Mantener vistas de compatibilidad para evitar roturas de backend.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Consolidar síntomas en 'seguimiento_salud'
-- ------------------------------------------------------------------------------
ALTER TABLE public.seguimiento_salud
  ADD COLUMN IF NOT EXISTS temperatura numeric(4,1),
  ADD COLUMN IF NOT EXISTS presion_arterial text,
  ADD COLUMN IF NOT EXISTS url_foto text;

-- Migrar datos de registros_sintomas hacia seguimiento_salud
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'registros_sintomas') THEN
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
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. Consolidar alertas y zonas de riesgo en 'alertas_epidemiologicas'
-- ------------------------------------------------------------------------------
ALTER TABLE public.alertas_epidemiologicas
  ALTER COLUMN reporte_epidemiologico_id DROP NOT NULL,
  ALTER COLUMN zona_riesgo_id DROP NOT NULL;

ALTER TABLE public.alertas_epidemiologicas
  ADD COLUMN IF NOT EXISTS municipio text NOT NULL DEFAULT 'Managua',
  ADD COLUMN IF NOT EXISTS enfermedad text NOT NULL DEFAULT 'Dengue',
  ADD COLUMN IF NOT EXISTS latitud numeric DEFAULT 12.1364,
  ADD COLUMN IF NOT EXISTS longitud numeric DEFAULT -86.2514,
  ADD COLUMN IF NOT EXISTS radio_km numeric DEFAULT 5,
  ADD COLUMN IF NOT EXISTS cantidad_casos integer DEFAULT 1,
  ADD COLUMN IF NOT EXISTS activo boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS geog geography(Point, 4326);

-- Si existen zonas_riesgo previas, trasladar sus coordenadas a las alertas asociadas
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'zonas_riesgo') THEN
    UPDATE public.alertas_epidemiologicas a
    SET
      municipio = COALESCE(z.municipio, a.municipio),
      latitud = COALESCE(z.latitud, a.latitud),
      longitud = COALESCE(z.longitud, a.longitud),
      radio_km = COALESCE(z.radio_km, a.radio_km)
    FROM public.zonas_riesgo z
    WHERE a.zona_riesgo_id = z.id;
  END IF;
END $$;

-- Actualizar coordenadas espaciales de alertas
UPDATE public.alertas_epidemiologicas
SET geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
WHERE geog IS NULL AND latitud IS NOT NULL AND longitud IS NOT NULL;

-- ------------------------------------------------------------------------------
-- 3. Asegurar coordenadas espaciales en 'centros_salud' (Managua)
-- ------------------------------------------------------------------------------
UPDATE public.centros_salud
SET geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
WHERE geog IS NULL AND latitud IS NOT NULL AND longitud IS NOT NULL;
-- Eliminar función previa si cambió su tipo de retorno (evita error 42P13)
DROP FUNCTION IF EXISTS public.centros_en_bbox(double precision, double precision, double precision, double precision, smallint, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox(float8, float8, float8, float8, smallint, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox(float8, float8, float8, float8) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox CASCADE;

-- Función centros_en_bbox optimizada para Managua: siempre devuelve centros sin importar umbral de zoom
CREATE OR REPLACE FUNCTION public.centros_en_bbox(
  p_min_lon float8,
  p_min_lat float8,
  p_max_lon float8,
  p_max_lat float8,
  p_nivel_min smallint DEFAULT 1,
  p_zoom numeric DEFAULT 15
)
RETURNS TABLE (
  id uuid,
  nombre text,
  lat numeric,
  lon numeric,
  latitud numeric,
  longitud numeric,
  nivel smallint,
  ubicacion_aproximada boolean
)
LANGUAGE sql STABLE
AS $$
  SELECT
    c.id,
    c.nombre,
    c.latitud AS lat,
    c.longitud AS lon,
    c.latitud,
    c.longitud,
    c.nivel_atencion AS nivel,
    (c.fuente_coordenada = 'aproximada') AS ubicacion_aproximada
  FROM public.centros_salud c
  WHERE c.activo
    AND (
      -- Si tiene geog y cae en el bbox
      (c.geog IS NOT NULL AND c.geog && st_makeenvelope(p_min_lon, p_min_lat, p_max_lon, p_max_lat, 4326)::geography)
      -- O si cae por coordenadas numéricas simples
      OR (c.latitud BETWEEN LEAST(p_min_lat, p_max_lat) AND GREATEST(p_min_lat, p_max_lat)
          AND c.longitud BETWEEN LEAST(p_min_lon, p_max_lon) AND GREATEST(p_min_lon, p_max_lon))
    )
  ORDER BY c.nivel_atencion DESC, c.nombre;
$$;

-- ------------------------------------------------------------------------------
-- 4. Semilla de Alerta Epidemiológica Activa en Managua
-- ------------------------------------------------------------------------------
INSERT INTO public.alertas_epidemiologicas (
  municipio,
  enfermedad,
  nivel_alerta,
  mensaje,
  latitud,
  longitud,
  radio_km,
  cantidad_casos,
  activo,
  fecha_expiracion
) VALUES (
  'Managua',
  'Dengue',
  'ALTO',
  'Alerta de prevención MINSA: Jornada de abatización y eliminación de criaderos en Managua Distrito V.',
  12.1241,
  -86.2358,
  4.5,
  18,
  true,
  now() + interval '30 days'
) ON CONFLICT DO NOTHING;

COMMIT;
