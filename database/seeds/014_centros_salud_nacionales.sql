-- ==============================================================================
-- Semilla 014: Centros de Salud y Hospitales Nacionales (Cobertura Nicaragua)
-- Proyecto: Biomark AI
-- SILAIS: Chinandega (Corinto, El Realejo, Chinandega, El Viejo, Chichigalpa),
--         León, Masaya, Granada, Carazo, Rivas, Estelí, Matagalpa
-- ==============================================================================

BEGIN;

-- Ajuste de función centros_en_bbox para visualización fluida de puestos y centros
DROP FUNCTION IF EXISTS public.centros_en_bbox(double precision, double precision, double precision, double precision, smallint, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox(float8, float8, float8, float8, smallint, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox(float8, float8, float8, float8) CASCADE;
DROP FUNCTION IF EXISTS public.centros_en_bbox CASCADE;

CREATE OR REPLACE FUNCTION public.centros_en_bbox(
  p_min_lon float8,
  p_min_lat float8,
  p_max_lon float8,
  p_max_lat float8,
  p_nivel_min smallint DEFAULT 1,
  p_zoom numeric DEFAULT 15
)
RETURNS TABLE (
  id uuid,
  nombre text,
  lat numeric,
  lon numeric,
  nivel smallint,
  ubicacion_aproximada boolean
)
LANGUAGE sql STABLE
AS $$
  SELECT
    c.id,
    c.nombre,
    c.latitud,
    c.longitud,
    c.nivel_atencion,
    (c.fuente_coordenada = 'aproximada') AS ubicacion_aproximada
  FROM public.centros_salud c
  WHERE c.activo
    AND c.geog IS NOT NULL
    AND c.nivel_atencion >= GREATEST(
      p_nivel_min,
      CASE
        WHEN p_zoom < 10 THEN 3
        WHEN p_zoom < 12.5 THEN 2
        ELSE 1
      END
    )
    AND c.geog && st_makeenvelope(p_min_lon, p_min_lat, p_max_lon, p_max_lat, 4326)::geography
  ORDER BY c.nivel_atencion DESC, c.nombre;
$$;

-- Inserción de centros de salud con coordenadas PostGIS verificadas
INSERT INTO public.centros_salud (
  id,
  nombre,
  tipo,
  latitud,
  longitud,
  geog,
  direccion,
  telefono,
  tipo_unidad,
  silais,
  municipio,
  zona,
  especialidades,
  nivel_atencion,
  atiende_emergencia,
  coordenadas_verificadas,
  fuente_coordenada,
  horario,
  activo,
  nombre_normalizado
) VALUES
  -- --------------------------------------------------------------------------
  -- CORINTO, CHINANDEGA
  -- --------------------------------------------------------------------------
  (
    '7b1e8430-6819-4b6e-b3d1-120000000001',
    'Hospital Primario Santa Teresa de Corinto',
    'HOSPITAL',
    12.4812000,
    -87.1735000,
    st_setsrid(st_makepoint(-87.1735000, 12.4812000), 4326)::geography,
    'Costado norte del Parque Central, frente al muelle, Corinto, Chinandega',
    '2342-2220',
    'Hospital Primario',
    'CHINANDEGA',
    'Corinto',
    'Urbano',
    ARRAY['Urgencias 24/7', 'Medicina General', 'Pediatría', 'Gineco-obstetricia', 'Hospitalización Básica', 'Laboratorio'],
    2,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'hospital primario santa teresa de corinto'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000002',
    'Puesto de Salud San Martín - El Playón',
    'PUESTO_MEDICO',
    12.4880000,
    -87.1690000,
    st_setsrid(st_makepoint(-87.1690000, 12.4880000), 4326)::geography,
    'Barrio San Martín, sector El Playón, Corinto',
    NULL,
    'Puesto de Salud',
    'CHINANDEGA',
    'Corinto',
    'Urbano',
    ARRAY['Atención General Básica', 'Vacunación', 'Curaciones', 'Control Prenatal'],
    1,
    false,
    true,
    'osm',
    '{"consulta": "Lunes a Viernes 8:00 AM - 3:00 PM"}'::jsonb,
    true,
    'puesto de salud san martin - el playon'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000003',
    'Puesto de Salud Barrio Camilo Ortega',
    'PUESTO_MEDICO',
    12.4760000,
    -87.1780000,
    st_setsrid(st_makepoint(-87.1780000, 12.4760000), 4326)::geography,
    'Barrio Camilo Ortega, Corinto, Chinandega',
    NULL,
    'Puesto de Salud',
    'CHINANDEGA',
    'Corinto',
    'Urbano',
    ARRAY['Atención Primaria', 'Vacunación Infantil', 'Entrega de Tratamientos'],
    1,
    false,
    true,
    'aproximada',
    '{"consulta": "Lunes a Viernes 8:00 AM - 2:00 PM"}'::jsonb,
    true,
    'puesto de salud barrio camilo ortega'
  ),

  -- --------------------------------------------------------------------------
  -- CHINANDEGA CABECERA Y MUNICIPIOS CERCANOS
  -- --------------------------------------------------------------------------
  (
    '7b1e8430-6819-4b6e-b3d1-120000000004',
    'Hospital Departamental Dr. Mauricio Abdalah (Nuevo Chinandega)',
    'HOSPITAL',
    12.5785000,
    -87.1352000,
    st_setsrid(st_makepoint(-87.1352000, 12.5785000), 4326)::geography,
    'Carretera Chinandega - Corinto Km 133, El Realejo',
    '2341-9000',
    'Hospital Departamental Referencia',
    'CHINANDEGA',
    'Chinandega',
    'Urbano',
    ARRAY['Emergencia 24/7', 'Cirugía General', 'Medicina Interna', 'Pediatría', 'Ginecología', 'Traumatología', 'Cuidados Intensivos', 'Tomografía', 'Hemodiálisis'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 5:00 PM"}'::jsonb,
    true,
    'hospital departamental dr. mauricio abdalah'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000005',
    'Hospital España de Chinandega',
    'HOSPITAL',
    12.6341000,
    -87.1310000,
    st_setsrid(st_makepoint(-87.1310000, 12.6341000), 4326)::geography,
    'Avenida Central, Costado Este del Cementerio Municipal, Chinandega',
    '2341-2550',
    'Hospital Departamental',
    'CHINANDEGA',
    'Chinandega',
    'Urbano',
    ARRAY['Emergencias', 'Medicina Interna', 'Cirugía', 'Neonatología', 'Banco de Sangre'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'hospital espana de chinandega'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000006',
    'Centro de Salud Roberto Alvarado',
    'CENTRO_SALUD',
    12.6280000,
    -87.1270000,
    st_setsrid(st_makepoint(-87.1270000, 12.6280000), 4326)::geography,
    'Del Parque de las Rosas 2c al Norte, Chinandega',
    '2341-1122',
    'Centro de Salud con Camas',
    'CHINANDEGA',
    'Chinandega',
    'Urbano',
    ARRAY['Atención General', 'Maternidad', 'Vacunación', 'Laboratorio Clínico'],
    2,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'centro de salud roberto alvarado'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000007',
    'Hospital Primario Teodoro King (El Viejo)',
    'HOSPITAL',
    12.6640000,
    -87.1680000,
    st_setsrid(st_makepoint(-87.1680000, 12.6640000), 4326)::geography,
    'Entrada principal a El Viejo 3c al Oeste, El Viejo, Chinandega',
    '2344-2200',
    'Hospital Primario',
    'CHINANDEGA',
    'El Viejo',
    'Urbano',
    ARRAY['Urgencias 24 Horas', 'Medicina General', 'Partos', 'Pediatría', 'Farmacia'],
    2,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'hospital primario teodoro king el viejo'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000008',
    'Hospital Primario de Chichigalpa',
    'HOSPITAL',
    12.5720000,
    -87.0280000,
    st_setsrid(st_makepoint(-87.0280000, 12.5720000), 4326)::geography,
    'Costado Sur de la Estación del Tren, Chichigalpa',
    '2343-2311',
    'Hospital Primario',
    'CHINANDEGA',
    'Chichigalpa',
    'Urbano',
    ARRAY['Emergencia 24h', 'Atención Renal y Metabólica', 'Medicina General', 'Pediatría'],
    2,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'hospital primario de chichigalpa'
  ),

  -- --------------------------------------------------------------------------
  -- LEÓN (HOSPITAL ESCUELA DE OCCIDENTE Y CENTROS)
  -- --------------------------------------------------------------------------
  (
    '7b1e8430-6819-4b6e-b3d1-120000000009',
    'Hospital Escuela Oscar Danilo Rosales Argüello (HEODRA)',
    'HOSPITAL',
    12.4355000,
    -86.8850000,
    st_setsrid(st_makepoint(-86.8850000, 12.4355000), 4326)::geography,
    'Costado Oeste de la Iglesia San Juan de Dios, León',
    '2311-2222',
    'Hospital Escuela Referencia Nacional',
    'LEON',
    'León',
    'Urbano',
    ARRAY['Emergencias 24/7', 'Traumatología de Alta Complejidad', 'Neurocirugía', 'Oncología', 'Cardiología', 'UCI Adulto y Pediátrico', 'Cirugía Mayor'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 5:00 PM"}'::jsonb,
    true,
    'hospital escuela oscar danilo rosales arguello heodra'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000010',
    'Centro de Salud Perla María Norori',
    'CENTRO_SALUD',
    12.4310000,
    -86.8780000,
    st_setsrid(st_makepoint(-86.8780000, 12.4310000), 4326)::geography,
    'Barrio El Laborío, frente a la Casa Comunal, León',
    '2311-4500',
    'Centro de Salud',
    'LEON',
    'León',
    'Urbano',
    ARRAY['Atención Integral Familiar', 'Vacunación', 'Salud Reproductiva', 'Odontología'],
    2,
    true,
    true,
    'osm',
    '{"consulta": "Lunes a Sábado 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'centro de salud perla maria norori'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000011',
    'Hospital Primario San Francisco Javier (Nagarote)',
    'HOSPITAL',
    12.2660000,
    -86.5650000,
    st_setsrid(st_makepoint(-86.5650000, 12.2660000), 4326)::geography,
    'Carretera Nueva a León Km 42, Nagarote, León',
    '2313-2211',
    'Hospital Primario',
    'LEON',
    'Nagarote',
    'Urbano',
    ARRAY['Emergencias Viales 24h', 'Medicina General', 'Maternidad', 'Laboratorio'],
    2,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas", "consulta": "Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
    true,
    'hospital primario san francisco javier nagarote'
  ),

  -- --------------------------------------------------------------------------
  -- REGIONALES CLAVE (MASAYA, GRANADA, CARAZO, RIVAS, ESTELÍ, MATAGALPA)
  -- --------------------------------------------------------------------------
  (
    '7b1e8430-6819-4b6e-b3d1-120000000012',
    'Hospital Departamental Dr. Humberto Alvarado Vásquez',
    'HOSPITAL',
    11.9660000,
    -86.0950000,
    st_setsrid(st_makepoint(-86.0950000, 11.9660000), 4326)::geography,
    'Costado Este de la Fortaleza Coyotepe, Masaya',
    '2522-2255',
    'Hospital Departamental',
    'MASAYA',
    'Masaya',
    'Urbano',
    ARRAY['Emergencias 24h', 'Cirugía General', 'Medicina Interna', 'Pediatría', 'Maternidad'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital departamental dr humberto alvarado vasquez'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000013',
    'Hospital Amistad Japón Nicaragua',
    'HOSPITAL',
    11.9320000,
    -85.9610000,
    st_setsrid(st_makepoint(-85.9610000, 11.9320000), 4326)::geography,
    'Entrada a Granada por el Cementerio 1 km al Lago, Granada',
    '2552-2500',
    'Hospital Departamental',
    'GRANADA',
    'Granada',
    'Urbano',
    ARRAY['Emergencias 24h', 'Especialidades Clínicas', 'Pediatría', 'Cirugía'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital amistad japon nicaragua'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000014',
    'Hospital Regional Santiago de Jinotepe',
    'HOSPITAL',
    11.8490000,
    -86.2050000,
    st_setsrid(st_makepoint(-86.2050000, 11.8490000), 4326)::geography,
    'Barrio San José, Jinotepe, Carazo',
    '2532-2233',
    'Hospital Regional',
    'CARAZO',
    'Jinotepe',
    'Urbano',
    ARRAY['Emergencias 24h', 'Medicina Interna', 'Gineco-obstetricia', 'Trauma'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital regional santiago de jinotepe'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000015',
    'Hospital Gaspar García Laviana',
    'HOSPITAL',
    11.4390000,
    -85.8320000,
    st_setsrid(st_makepoint(-85.8320000, 11.4390000), 4326)::geography,
    'Carretera Panamericana Sur Km 112, Rivas',
    '2563-3344',
    'Hospital Departamental',
    'RIVAS',
    'Rivas',
    'Urbano',
    ARRAY['Emergencias 24h', 'Cirugía', 'Pediatría', 'Maternidad'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital gaspar garcia laviana'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000016',
    'Hospital Escuela San Juan de Dios (Estelí)',
    'HOSPITAL',
    13.0920000,
    -86.3560000,
    st_setsrid(st_makepoint(-86.3560000, 13.0920000), 4326)::geography,
    'Salida Norte Carretera Panamericana, Estelí',
    '2713-2211',
    'Hospital Escuela Regional',
    'ESTELI',
    'Estelí',
    'Urbano',
    ARRAY['Emergencias 24/7', 'Traumatología', 'Cirugía Laparoscópica', 'Pediatría', 'UCI'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital escuela san juan de dios esteli'
  ),
  (
    '7b1e8430-6819-4b6e-b3d1-120000000017',
    'Hospital Regional César Amador Molina (Matagalpa)',
    'HOSPITAL',
    12.9240000,
    -85.9180000,
    st_setsrid(st_makepoint(-85.9180000, 12.9240000), 4326)::geography,
    'Salida a Managua, Frente al Complejo Judicial, Matagalpa',
    '2772-2244',
    'Hospital Regional',
    'MATAGALPA',
    'Matagalpa',
    'Urbano',
    ARRAY['Emergencias 24/7', 'Referencia Norte', 'Ginecología', 'Pediatría', 'Cirugía General'],
    3,
    true,
    true,
    'osm',
    '{"emergencia": "24 horas"}'::jsonb,
    true,
    'hospital regional cesar amador molina matagalpa'
  )
ON CONFLICT (id) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  tipo = EXCLUDED.tipo,
  latitud = EXCLUDED.latitud,
  longitud = EXCLUDED.longitud,
  geog = EXCLUDED.geog,
  direccion = EXCLUDED.direccion,
  telefono = EXCLUDED.telefono,
  silais = EXCLUDED.silais,
  municipio = EXCLUDED.municipio,
  especialidades = EXCLUDED.especialidades,
  nivel_atencion = EXCLUDED.nivel_atencion,
  atiende_emergencia = EXCLUDED.atiende_emergencia,
  activo = EXCLUDED.activo,
  nombre_normalizado = EXCLUDED.nombre_normalizado;

-- Asegurar que cualquier centro previo con latitud/longitud tenga geog poblado
UPDATE public.centros_salud
SET geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
WHERE geog IS NULL AND latitud IS NOT NULL AND longitud IS NOT NULL;

COMMIT;
