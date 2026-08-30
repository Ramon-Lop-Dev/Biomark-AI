-- Completa el contrato de dispositivos push para entrega gestionada por n8n.
ALTER TABLE public.dispositivos_push
  ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS fecha_creacion timestamp with time zone NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_dispositivos_push_usuario_activo
  ON public.dispositivos_push(usuario_id) WHERE activo = true;