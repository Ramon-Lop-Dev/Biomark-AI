-- Migración 013: Tabla de recomendaciones de salud validadas con RBAC y normativas MINSA.
-- Permite que promotores de salud (TRABAJADOR_SALUD, PROMOTOR) y administradores (ADMIN)
-- gestionen pautas oficiales de salud comunitaria, con estructura estricta de colores y categorías.

CREATE TABLE IF NOT EXISTS public.recomendaciones_salud (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria VARCHAR(50) NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  resumen TEXT NOT NULL,
  detalle_clinico TEXT NOT NULL,
  normativa_minsa VARCHAR(255) NOT NULL,
  etiqueta VARCHAR(100) NOT NULL,
  icono VARCHAR(50) NOT NULL DEFAULT 'shield',
  color_hex VARCHAR(10) NOT NULL,
  puntos_clave JSONB NOT NULL DEFAULT '[]'::jsonb,
  condiciones_diana JSONB NOT NULL DEFAULT '[]'::jsonb,
  alertas_diana JSONB NOT NULL DEFAULT '[]'::jsonb,
  municipios_objetivo JSONB NOT NULL DEFAULT '[]'::jsonb,
  edad_minima INT,
  edad_maxima INT,
  creado_por UUID REFERENCES public.usuarios(id) ON DELETE SET NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'PUBLICADO',
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_recomendacion_categoria CHECK (
    categoria IN (
      'dengue',
      'heatWave',
      'cardiovascular',
      'treatment',
      'minsaNotice',
      'diabetes',
      'respiratory'
    )
  ),
  CONSTRAINT chk_recomendacion_estado CHECK (
    estado IN ('BORRADOR', 'PUBLICADO', 'ARCHIVADO')
  )
);

CREATE INDEX IF NOT EXISTS idx_recomendaciones_categoria_estado
  ON public.recomendaciones_salud(categoria, estado);

CREATE INDEX IF NOT EXISTS idx_recomendaciones_fecha_creacion
  ON public.recomendaciones_salud(fecha_creacion DESC);

-- Semillas oficiales del MINSA de Nicaragua
INSERT INTO public.recomendaciones_salud (
  id,
  categoria,
  titulo,
  resumen,
  detalle_clinico,
  normativa_minsa,
  etiqueta,
  icono,
  color_hex,
  puntos_clave,
  condiciones_diana,
  alertas_diana,
  municipios_objetivo
) VALUES
(
  'a1000000-0000-0000-0000-000000000001',
  'dengue',
  'Prevención Activa de Dengue y Arbovirosis',
  'Elimina criaderos en recipientes con agua y reconoce signos de alarma tempranos.',
  'El zancudo Aedes aegypti se reproduce en agua limpia estancada. Las lluvias en Nicaragua aumentan el riesgo de transmisión comunitaria. La detección oportuna previene el dengue grave.',
  'Normativa 004 MINSA - Protocolo de Abordaje del Dengue',
  'Salud Vectorial MINSA',
  'shield',
  '#EF4444',
  '["Lava y cepilla pilas, barriles y floreros al menos dos veces por semana.", "Desecha llantas viejas, latas y recipientes que acumulen agua de lluvia.", "Permite el ingreso a brigadistas de fumigación y aplicación de BTI.", "Signos de alarma: dolor abdominal intenso, vómitos persistentes y somnolencia.", "¡No te automediques! Evita la aspirina o el ibuprofeno ante fiebre."]'::jsonb,
  '["fiebre", "dengue", "infeccion"]'::jsonb,
  '["dengue", "arbovirosis", "malaria"]'::jsonb,
  '[]'::jsonb
),
(
  'a1000000-0000-0000-0000-000000000002',
  'heatWave',
  'Hidratación y Prevención de Golpe de Calor',
  'Pautas de reposición hídrica en temperaturas superiores a 30°C.',
  'En las regiones del Pacífico y Centro de Nicaragua, las temperaturas elevadas incrementan la pérdida hídrica dérmica y el riesgo de insolación en niños y adultos mayores.',
  'Guía Técnica MINSA para Emergencias Climáticas',
  'Clima y Termorregulación',
  'water_drop',
  '#0EA5E9',
  '["Consume entre 2.5 y 3 litros de agua potable distribuida a lo largo del día.", "Evita la exposición solar directa entre las 11:00 AM y 3:00 PM.", "Usa ropa holgada, de algodón y colores claros con protección solar o sombrero.", "Ten a mano sales de rehidratación oral (Sobres MINSA) ante signos de deshidratación.", "Atención especial a adultos mayores: pueden perder la sensación de sed."]'::jsonb,
  '["hipertension", "renal"]'::jsonb,
  '["calor", "sequia", "ola_de_calor"]'::jsonb,
  '["Managua", "León", "Chinandega"]'::jsonb
),
(
  'a1000000-0000-0000-0000-000000000003',
  'cardiovascular',
  'Salud Cardiovascular y Control del Pulso',
  'Monitorea tu frecuencia cardíaca y reconoce los valores normales en reposo.',
  'El pulso refleja el ritmo y gasto cardíaco. Una frecuencia regular entre 60 y 100 BPM en reposo indica un funcionamiento cardiovascular dentro de los parámetros esperados.',
  'Protocolo de Prevención de Enfermedades Crónicas MINSA',
  'Cardiovascular',
  'favorite',
  '#E11D48',
  '["El pulso normal en adultos en reposo oscila entre 60 y 100 latidos por minuto.", "Factores como el estrés, cafeína, tabaco y fiebre pueden acelerar el pulso temporalmente.", "Mide tu pulso con la función de sismocardiografía o PPG de Biomark AI luego de reposar 5 minutos.", "Consulta si experimentas palpitaciones recurrentes, mareos o sensación de desmayo.", "La actividad física moderada diaria fortalece el miocardio."]'::jsonb,
  '["hipertension", "arritmia", "cardiopatia", "insuficiencia_cardiaca"]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb
),
(
  'a1000000-0000-0000-0000-000000000004',
  'treatment',
  'Adherencia al Tratamiento Farmacológico',
  'No interrumpas ni modifiques dosis prescritas por tu médico tratante.',
  'El abandono temprano de tratamientos para hipertensión, diabetes o infecciones es una causa común de recaídas y complicaciones graves.',
  'Estrategia de Uso Racional de Medicamentos MINSA',
  'Farmacovigilancia',
  'medication',
  '#10B981',
  '["Toma tus medicamentos todos los días a la misma hora para mantener niveles estables.", "Nunca suspendas antibióticos antes de la fecha indicada por el médico.", "Configura recordatorios en la pestaña de Recordatorios de Biomark AI.", "Guarda las medicinas en un lugar fresco, seco y fuera del alcance de los niños.", "Si sientes molestias o efectos secundarios, comunícate con tu centro de salud."]'::jsonb,
  '["hipertension", "diabetes", "asma", "infeccion"]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb
),
(
  'a1000000-0000-0000-0000-000000000005',
  'diabetes',
  'Control Glucémico y Cuidado Integral en Diabetes',
  'Pautas para la prevención de picos glucémicos y cuidado de miembros inferiores.',
  'La diabetes mellitus requiere monitoreo dietético, ejercicio regular y revisión periódica de los pies para evitar el pie diabético y daños vasculares.',
  'Normativa 078 MINSA - Manejo de la Diabetes Mellitus',
  'Metabólica y Nutrición',
  'restaurant',
  '#F59E0B',
  '["Reduce el consumo de azúcares refinados, bebidas azucaradas y harinas procesadas.", "Revisa tus pies diariamente en busca de pequeñas heridas, grietas o cambios de coloración.", "Mantén un horario regular de comidas y no te saltes el desayuno.", "Realiza al menos 30 minutos de caminata diaria si tu médico lo autoriza.", "Acude a tus controles periódicos de hemoglobina glucosilada (HbA1c) en tu centro de salud."]'::jsonb,
  '["diabetes", "diabetes_mellitus", "obesidad", "glucosa"]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb
),
(
  'a1000000-0000-0000-0000-000000000006',
  'respiratory',
  'Prevención de Infecciones Respiratorias y Manejo del Asma',
  'Protege tus vías respiratorias ante cambios de clima y polvo ambiental.',
  'Las infecciones respiratorias agudas (IRA) y las crisis asmáticas aumentan durante los cambios estacionales de lluvia a época seca en Nicaragua.',
  'Normativa 028 MINSA - Abordaje de Infecciones Respiratorias Agudas',
  'Salud Respiratoria',
  'air',
  '#06B6D4',
  '["Cúbrete la boca y nariz con el ángulo interno del codo al toser o estornudar.", "Evita la exposición al humo de leña, cigarrillo y quemas de basura.", "Identifica los desencadenantes de tu asma: polvo, polen, cambios bruscos de temperatura.", "Ten siempre a mano tu inhalador de rescate según la indicación médica.", "Acude de inmediato si presentas dificultad para respirar, hundimiento de costillas o labios azulados."]'::jsonb,
  '["asma", "epoc", "bronquitis", "alergia_respiratoria"]'::jsonb,
  '["respiratorio", "influenza", "infeccion_respiratoria"]'::jsonb,
  '[]'::jsonb
)
ON CONFLICT (id) DO NOTHING;
