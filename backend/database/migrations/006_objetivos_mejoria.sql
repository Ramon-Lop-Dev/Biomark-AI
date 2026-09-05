-- Objetivos personales de mejoría y sus hitos de seguimiento.
CREATE TABLE IF NOT EXISTS public.objetivos_mejoria (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id),
  titulo text NOT NULL,
  descripcion text,
  periodicidad text NOT NULL CHECK (periodicidad IN ('SEMANAL', 'QUINCENAL', 'MENSUAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL')),
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  estado text NOT NULL DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'COMPLETADO', 'CANCELADO')),
  fecha_creacion timestamptz NOT NULL DEFAULT now(),
  fecha_actualizacion timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT objetivos_mejoria_pkey PRIMARY KEY (id),
  CONSTRAINT objetivos_mejoria_fechas_validas CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE IF NOT EXISTS public.hitos_mejoria (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  objetivo_id uuid NOT NULL REFERENCES public.objetivos_mejoria(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  fecha_objetivo date NOT NULL,
  completado boolean NOT NULL DEFAULT false,
  fecha_completado timestamptz,
  fecha_creacion timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT hitos_mejoria_pkey PRIMARY KEY (id)
);

CREATE INDEX IF NOT EXISTS objetivos_mejoria_usuario_idx ON public.objetivos_mejoria(usuario_id);
CREATE INDEX IF NOT EXISTS hitos_mejoria_objetivo_idx ON public.hitos_mejoria(objetivo_id, fecha_objetivo);