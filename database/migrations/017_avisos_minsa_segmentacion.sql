-- ==============================================================================
-- Migración 017: Segmentación de Contenido Oficial MINSA y Alertas Sanitarias
-- Proyecto: Biomark AI (Nicaragua / MINSA)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Ampliación de 'contenido_salud' con gobernanza sanitaria y segmentación
-- ------------------------------------------------------------------------------
ALTER TABLE public.contenido_salud
  ADD COLUMN IF NOT EXISTS normativa_codigo TEXT,
  ADD COLUMN IF NOT EXISTS normativa_url TEXT,
  ADD COLUMN IF NOT EXISTS tipo_aviso TEXT NOT NULL DEFAULT 'CONSEJO',
  ADD COLUMN IF NOT EXISTS prioridad TEXT NOT NULL DEFAULT 'MEDIA',
  ADD COLUMN IF NOT EXISTS alcance_tipo TEXT NOT NULL DEFAULT 'GENERAL',
  ADD COLUMN IF NOT EXISTS condiciones_objetivo TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS barrio_comunidad TEXT NOT NULL DEFAULT 'Managua',
  ADD COLUMN IF NOT EXISTS silais TEXT NOT NULL DEFAULT 'Managua';

CREATE INDEX IF NOT EXISTS idx_contenido_salud_segmentacion
  ON public.contenido_salud(tipo_aviso, prioridad, alcance_tipo);

CREATE INDEX IF NOT EXISTS idx_contenido_salud_condiciones
  ON public.contenido_salud USING GIN(condiciones_objetivo);

-- ------------------------------------------------------------------------------
-- 2. Semillas Oficiales MINSA segmentadas por patologías y normativas
-- ------------------------------------------------------------------------------
INSERT INTO public.contenido_salud (
  id,
  titulo,
  descripcion,
  contenido,
  categoria,
  imagen_url,
  fuente,
  normativa_codigo,
  tipo_aviso,
  prioridad,
  alcance_tipo,
  condiciones_objetivo,
  barrio_comunidad,
  silais
)
VALUES
  (
    '77777777-1111-4000-8000-000000000001',
    'Guía MINSA: Control de Presión Arterial en el Hogar',
    'Protocolo de control de presión y hábitos saludables según la Normativa 084 del MINSA.',
    'El Ministerio de Salud de Nicaragua establece en la Normativa 084 que los pacientes hipertensos deben registrar sus cifras matutinas y nocturnas. Reduzca el consumo de sodio, evite frituras y camine al menos 30 minutos al día. Acuda a su puesto médico barrial para retiro de tratamiento mensual.',
    'Prevención y Control',
    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&auto=format&fit=crop&q=80',
    'MINSA Nicaragua',
    'Normativa 084 - Manejo Clínico de la Hipertensión',
    'NORMATIVA',
    'ALTA',
    'CONDICION',
    ARRAY['hipertension', 'hipertensión', 'presion alta', 'presión arterial'],
    'Managua',
    'SILAIS Managua'
  ),
  (
    '77777777-2222-4000-8000-000000000002',
    'Cuidados del Pie y Glucosa en Pacientes Diabéticos',
    'Recomendaciones del Programa Nacional de Enfermedades Crónicas del MINSA para la prevención del pie diabético.',
    'Revise diariamente la planta de sus pies y entre los dedos. Mantenga la piel hidratada evitando cremas entre los dedos. No camine descalzo. Si nota enrojecimiento, calor o pequeñas heridas, acuda de inmediato al Centro de Salud más cercano según la Normativa 077.',
    'Enfermedades Crónicas',
    'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&auto=format&fit=crop&q=80',
    'MINSA Nicaragua',
    'Normativa 077 - Atención a la Diabetes Mellitus',
    'NORMATIVA',
    'ALTA',
    'CONDICION',
    ARRAY['diabetes', 'glucosa', 'azucar en sangre'],
    'Managua',
    'SILAIS Managua'
  ),
  (
    '77777777-3333-4000-8000-000000000003',
    'Alerta Epidemiológica: Prevención Activa del Dengue en Managua',
    'Jornadas de abatización y eliminación de criaderos de zancudos en distritos de Managua.',
    'Brigadistas del SILAIS Managua realizan visitas casa a casa para aplicar abate e identificar larvas. Lave pilas y barriles cada tres días con cepillo. Ante fiebre repentina, dolor detrás de los ojos o dolor articular, no se automedique con ibuprofeno ni aspirina y consulte a su centro asistencial.',
    'Alertas Sanitarias',
    'https://images.unsplash.com/photo-1583912267670-6575ad4736f2?w=800&auto=format&fit=crop&q=80',
    'SILAIS Managua / MINSA',
    'Protocolo de Vigilancia Arbovirosis',
    'ALERTA_EPIDEMIOLOGICA',
    'ALTA',
    'GENERAL',
    ARRAY['dengue', 'fiebre', 'infeccion'],
    'Managua',
    'SILAIS Managua'
  ),
  (
    '77777777-4444-4000-8000-000000000004',
    'Jornada de Salud Comunitaria y Vacunación en Barrios Cercanos',
    'Atención médica gratuita, odontología, medicina natural y esquema de vacunación en distritos.',
    'El MINSA despliega Clínicas Móviles para brindar consulta general, ultrasonidos, tomas de Papanicolaou y actualización de esquemas de vacunas. Consulte la ubicación exacta en el mapa asistencial de Biomark AI.',
    'Vacunación y Jornadas',
    'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&auto=format&fit=crop&q=80',
    'MINSA Nicaragua',
    'Modelo de Salud Familiar y Comunitario (MOSAFC)',
    'JORNADA_VACUNACION',
    'MEDIA',
    'GENERAL',
    ARRAY['vacunacion', 'salud preventiva'],
    'Managua',
    'SILAIS Managua'
  ),
  (
    '77777777-5555-4000-8000-000000000005',
    'Vigilancia Respiratoria: Manejo de Crisis Asmáticas',
    'Guía para familias con niños o adultos asmáticos durante cambios estacionales en Managua.',
    'Identifique signos de alarma: dificultad para respirar, hundimiento de costillas o labios morados. Tenga a mano su broncodilatador de rescate y evite la exposición a humo de leña o polvo. Si los síntomas persisten, acuda a urgencias.',
    'Salud Respiratoria',
    'https://images.unsplash.com/photo-1584362917165-526a968579e8?w=800&auto=format&fit=crop&q=80',
    'MINSA Nicaragua',
    'Normativa 062 - Infecciones Respiratorias Agudas',
    'NORMATIVA',
    'MEDIA',
    'CONDICION',
    ARRAY['asma', 'alergia', 'respiratorio', 'tos'],
    'Managua',
    'SILAIS Managua'
  )
ON CONFLICT (id) DO UPDATE SET
  titulo = EXCLUDED.titulo,
  descripcion = EXCLUDED.descripcion,
  contenido = EXCLUDED.contenido,
  categoria = EXCLUDED.categoria,
  imagen_url = EXCLUDED.imagen_url,
  fuente = EXCLUDED.fuente,
  normativa_codigo = EXCLUDED.normativa_codigo,
  tipo_aviso = EXCLUDED.tipo_aviso,
  prioridad = EXCLUDED.prioridad,
  alcance_tipo = EXCLUDED.alcance_tipo,
  condiciones_objetivo = EXCLUDED.condiciones_objetivo,
  barrio_comunidad = EXCLUDED.barrio_comunidad,
  silais = EXCLUDED.silais,
  fecha_actualizacion = now();

COMMIT;
