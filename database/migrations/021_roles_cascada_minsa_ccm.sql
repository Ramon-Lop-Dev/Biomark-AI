-- ==============================================================================
-- Migración 021: Roles de Confianza en Cascada, Scoping Territorial y Triaje CCM
-- Proyecto: Biomark AI (Nicaragua - MINSA)
-- ==============================================================================
-- Objetivos:
-- 1. Vincular usuarios a centros de salud (centro_salud_id), trazabilidad de quién
--    los invitó (invitado_por) y control de estado (estado_cuenta).
-- 2. Tabla de invitaciones de un solo uso para alta delegada (ADMIN -> TRABAJADOR_SALUD -> PROMOTOR).
-- 3. Código oficial de establecimiento en centros_salud (Normativa 112 MINSA).
-- 4. Soporte para triaje semafórico CCM (Manejo de Casos Comunitarios: VERDE, AMARILLO, ROJO)
--    y asignación de establecimiento en reportes comunitarios.
-- ==============================================================================

BEGIN;

-- 1. Ampliar usuarios con ancla de establecimiento y jerarquía
ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS centro_salud_id uuid REFERENCES public.centros_salud(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS invitado_por uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS estado_cuenta text NOT NULL DEFAULT 'ACTIVO';

-- Asegurar restricción check para estado_cuenta
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_usuarios_estado_cuenta'
  ) THEN
    ALTER TABLE public.usuarios
      ADD CONSTRAINT chk_usuarios_estado_cuenta
      CHECK (estado_cuenta IN ('ACTIVO', 'SUSPENDIDO'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usuarios_centro_salud ON public.usuarios(centro_salud_id) WHERE centro_salud_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_usuarios_invitado_por ON public.usuarios(invitado_por) WHERE invitado_por IS NOT NULL;

-- 2. Código oficial MINSA en centros_salud (Normativa 112)
ALTER TABLE public.centros_salud
  ADD COLUMN IF NOT EXISTS codigo_establecimiento text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_centros_salud_codigo_establecimiento'
  ) THEN
    ALTER TABLE public.centros_salud
      ADD CONSTRAINT uq_centros_salud_codigo_establecimiento UNIQUE (codigo_establecimiento);
  END IF;
END $$;

-- 3. Tabla de Invitaciones de un solo uso para gobernanza en cascada
CREATE TABLE IF NOT EXISTS public.invitaciones (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  token text NOT NULL UNIQUE,
  contacto text NOT NULL,
  rol_destino text NOT NULL CHECK (rol_destino IN ('TRABAJADOR_SALUD', 'PROMOTOR')),
  centro_salud_id uuid NOT NULL REFERENCES public.centros_salud(id) ON DELETE CASCADE,
  creado_por uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  expira_en timestamptz NOT NULL,
  usado_en timestamptz,
  usuario_resultante_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL,
  fecha_creacion timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invitaciones_token_activas
  ON public.invitaciones(token)
  WHERE usado_en IS NULL;

CREATE INDEX IF NOT EXISTS idx_invitaciones_centro_rol
  ON public.invitaciones(centro_salud_id, rol_destino);

-- 4. Extensión a reportes comunitarios: centro de salud y clasificación CCM
ALTER TABLE public.reportes_comunitarios
  ADD COLUMN IF NOT EXISTS centro_salud_id uuid REFERENCES public.centros_salud(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS clasificacion_ccm text NOT NULL DEFAULT 'VERDE',
  ADD COLUMN IF NOT EXISTS asignado_a uuid REFERENCES public.usuarios(id) ON DELETE SET NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_reportes_clasificacion_ccm'
  ) THEN
    ALTER TABLE public.reportes_comunitarios
      ADD CONSTRAINT chk_reportes_clasificacion_ccm
      CHECK (clasificacion_ccm IN ('VERDE', 'AMARILLO', 'ROJO'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reportes_centro_clasificacion
  ON public.reportes_comunitarios(centro_salud_id, clasificacion_ccm, estado);

COMMIT;
