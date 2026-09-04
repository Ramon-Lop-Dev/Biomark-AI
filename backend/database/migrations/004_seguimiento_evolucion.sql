-- Registra la evolución confirmada por el usuario sin mezclarla con el diagnóstico.
CREATE TABLE IF NOT EXISTS public.seguimiento_salud (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  sintoma text NOT NULL,
  estado text NOT NULL CHECK (estado IN ('MEJORO', 'IGUAL', 'EMPEORO', 'NO_SEGURO')),
  intensidad integer CHECK (intensidad BETWEEN 0 AND 10),
  notas text,
  fecha_registro timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT seguimiento_salud_pkey PRIMARY KEY (id),
  CONSTRAINT seguimiento_salud_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE INDEX IF NOT EXISTS idx_seguimiento_salud_usuario_fecha
  ON public.seguimiento_salud(usuario_id, fecha_registro DESC);
