-- ==============================================================================
-- Migración 016: Onboarding, Entrevista Médica Única y Contenido de Salud Oficial
-- Proyecto: Biomark AI (Nicaragua / MINSA)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Ampliación de 'perfiles' para entrevista médica obligatoria y biometría
-- ------------------------------------------------------------------------------
ALTER TABLE public.perfiles
  ADD COLUMN IF NOT EXISTS entrevista_completada BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS peso NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS altura NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS fuma TEXT DEFAULT 'NO',
  ADD COLUMN IF NOT EXISTS alcohol TEXT DEFAULT 'NO',
  ADD COLUMN IF NOT EXISTS actividad_fisica TEXT DEFAULT 'MODERADA';

CREATE INDEX IF NOT EXISTS idx_perfiles_entrevista_completada
  ON public.perfiles(usuario_id, entrevista_completada);

-- ------------------------------------------------------------------------------
-- 2. Tabla 'contenido_salud' (Fuentes Oficiales: MINSA, OPS, OMS)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contenido_salud (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  contenido TEXT NOT NULL,
  categoria TEXT NOT NULL,
  imagen_url TEXT,
  fuente TEXT NOT NULL,
  fecha_publicacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  estado TEXT NOT NULL DEFAULT 'PUBLICADO',

  CONSTRAINT chk_contenido_salud_estado CHECK (
    estado IN ('BORRADOR', 'PUBLICADO', 'ARCHIVADO')
  )
);

CREATE INDEX IF NOT EXISTS idx_contenido_salud_categoria_estado
  ON public.contenido_salud(categoria, estado);

CREATE INDEX IF NOT EXISTS idx_contenido_salud_fecha
  ON public.contenido_salud(fecha_publicacion DESC);

CREATE INDEX IF NOT EXISTS idx_contenido_salud_fuente
  ON public.contenido_salud(fuente);

-- Habilitar RLS en contenido_salud
ALTER TABLE public.contenido_salud ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'contenido_salud' AND policyname = 'Lectura de contenido publicado para todos'
  ) THEN
    CREATE POLICY "Lectura de contenido publicado para todos"
      ON public.contenido_salud
      FOR SELECT
      USING (estado = 'PUBLICADO');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'contenido_salud' AND policyname = 'Gestion de contenido para personal de salud y admin'
  ) THEN
    CREATE POLICY "Gestion de contenido para personal de salud y admin"
      ON public.contenido_salud
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.usuarios u
          WHERE u.id = auth.uid()
            AND u.rol IN ('ADMIN', 'PROMOTOR', 'TRABAJADOR_SALUD')
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.usuarios u
          WHERE u.id = auth.uid()
            AND u.rol IN ('ADMIN', 'PROMOTOR', 'TRABAJADOR_SALUD')
        )
      );
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 3. Semillas de Contenido Oficial MINSA Nicaragua, OPS y OMS
-- ------------------------------------------------------------------------------
INSERT INTO public.contenido_salud (
  id,
  titulo,
  descripcion,
  contenido,
  categoria,
  imagen_url,
  fuente,
  estado
) VALUES
(
  'c1000000-0000-0000-0000-000000000001',
  'Campaña Nacional de Vacunación y Detección Temprana de Dengue',
  'Medidas de prevención en hogares nicaragüenses y signos de alarma según la Normativa 004 del MINSA.',
  'El Ministerio de Salud (MINSA) de Nicaragua reitera a las familias la importancia de inspeccionar pilas, barriles y techos para erradicar los criaderos del mosquito transmisor del dengue, zika y chikungunya. Ante síntomas como fiebre súbita, dolor detrás de los ojos, decaimiento o dolor abdominal intenso, no debe automedicarse con ácido acetilsalicílico ni antiinflamatorios no esteroideos; acuda de inmediato al puesto de salud más cercano.',
  'PREVENCION',
  'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
  'MINSA Nicaragua',
  'PUBLICADO'
),
(
  'c1000000-0000-0000-0000-000000000002',
  'Pautas OPS/OMS para el Control de la Hipertensión en la Comunidad',
  'Recomendaciones de monitoreo y reducción de sodio para la protección cardiovascular.',
  'La Organización Panamericana de la Salud (OPS) enfatiza que mantener la presión arterial por debajo de 130/80 mmHg reduce significativamente el riesgo de accidentes cerebrovasculares y daño renal. Se aconseja limitar el consumo de sal de mesa a menos de 5 gramos diarios, realizar al menos 150 minutos semanales de actividad aeróbica moderada y realizar controles periódicos de la frecuencia cardíaca y presión.',
  'CARDIOVASCULAR',
  'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
  'OPS / OMS',
  'PUBLICADO'
),
(
  'c1000000-0000-0000-0000-000000000003',
  'Guía Alimentaria y Manejo Glucémico en Climas Cálidos',
  'Protocolo MINSA para personas con diabetes tipo 2 durante olas de calor en el Pacífico.',
  'En temperaturas superiores a los 32°C, las personas con diabetes pueden presentar deshidratación acelerada que altera los niveles séricos de glucosa. El MINSA recomienda beber abundante agua purificada, priorizar verduras verdes frescas, tubérculos no procesados y mantener los medicamentos orales o insulina protegidos de la exposición directa al sol y a temperatura ambiente fresca.',
  'NUTRICION',
  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
  'MINSA Nicaragua',
  'PUBLICADO'
),
(
  'c1000000-0000-0000-0000-000000000004',
  'Salud Respiratoria Infantil: Reconocimiento de Signos de Peligro',
  'Criterios de la OMS para la atención de infecciones respiratorias agudas en el primer nivel.',
  'Durante los cambios de estación lluviosa, la OMS y el MINSA recomiendan vigilar la respiración rápida en lactantes y niños pequeños. Signos como tiraje subcostal (hundimiento de costillas), rechazo de alimentos o estridor en reposo constituyen una emergencia médica que exige valoración inmediata por el personal de salud.',
  'PEDIATRIA',
  'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=800&q=80',
  'OMS',
  'PUBLICADO'
)
ON CONFLICT (id) DO NOTHING;

COMMIT;
