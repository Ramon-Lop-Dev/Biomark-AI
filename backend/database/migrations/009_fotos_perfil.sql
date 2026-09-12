-- Guarda solo la ruta privada del archivo; la API genera URLs firmadas al leer el perfil.
ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS foto_path text;

-- Bucket privado para fotos de perfil. El backend usa la service role key para Storage.
INSERT INTO storage.buckets (id, name, public)
VALUES ('fotos-perfil', 'fotos-perfil', false)
ON CONFLICT (id) DO UPDATE SET public = false;