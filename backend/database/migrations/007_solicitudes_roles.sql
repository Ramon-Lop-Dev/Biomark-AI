-- Solicitudes de roles privilegiados. Nunca se autoasigna PROMOTOR desde el cliente.
CREATE TABLE IF NOT EXISTS public.solicitudes_roles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  rol_solicitado text NOT NULL CHECK (rol_solicitado IN ('PROMOTOR')),
  estado text NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA')),
  revisado_por uuid REFERENCES public.usuarios(id),
  fecha_creacion timestamptz NOT NULL DEFAULT now(),
  fecha_revision timestamptz
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_roles_estado
  ON public.solicitudes_roles(estado, fecha_creacion);