-- Campos y búsqueda para recomendar centros por padecimiento y cercanía.
BEGIN;

ALTER TABLE public.centros_salud
  ADD COLUMN IF NOT EXISTS tipo_unidad text,
  ADD COLUMN IF NOT EXISTS silais text,
  ADD COLUMN IF NOT EXISTS distrito text,
  ADD COLUMN IF NOT EXISTS municipio text,
  ADD COLUMN IF NOT EXISTS localidad text,
  ADD COLUMN IF NOT EXISTS zona text,
  ADD COLUMN IF NOT EXISTS especialidades text[],
  ADD COLUMN IF NOT EXISTS coordenadas_verificadas boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_centros_salud_municipio
  ON public.centros_salud(municipio);
CREATE INDEX IF NOT EXISTS idx_centros_salud_especialidades
  ON public.centros_salud USING GIN (especialidades);

COMMIT;