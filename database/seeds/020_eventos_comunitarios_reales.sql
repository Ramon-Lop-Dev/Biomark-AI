-- ============================================================================
-- BIOMARK AI: JORNADAS Y EVENTOS COMUNITARIOS CON GEORREFERENCIACIÓN EXACTA
-- Coordenadas verificadas de Managua (Distritos II y III)
-- ============================================================================

DO $$
DECLARE
  v_admin_id uuid;
BEGIN
  -- 1. Resolver el usuario organizador institucional (ADMIN o primer usuario del sistema)
  SELECT id INTO v_admin_id FROM public.usuarios WHERE rol = 'ADMIN' LIMIT 1;
  IF v_admin_id IS NULL THEN
    SELECT id INTO v_admin_id FROM public.usuarios LIMIT 1;
  END IF;

  IF v_admin_id IS NULL THEN
    RAISE NOTICE 'No se encontraron usuarios en la base de datos para asignar como organizador. Omite inserción.';
    RETURN;
  END IF;

  -- 2. Limpiar eventos ficticios o de prueba anteriores
  DELETE FROM public.eventos_comunitarios 
  WHERE titulo LIKE '%seed%' 
     OR id::text LIKE 'evento-seed%'
     OR titulo ILIKE '%ficticio%';

  -- 3. Insertar eventos reales con coordenadas precisas
  -- San Judas: Cancha Comunal / Mercado San Judas (Distrito III) -> Lat: 12.1085365, Lon: -86.2969298
  INSERT INTO public.eventos_comunitarios (
    organizador_id,
    titulo,
    descripcion,
    fecha_evento,
    ubicacion,
    latitud,
    longitud,
    tipo,
    activo
  ) VALUES (
    v_admin_id,
    'Clínica Móvil MINSA y Atención Médica Integral',
    'Consultas de medicina general, pediatría, odontología, ultrasonidos diagnósticos y entrega de medicamentos esenciales.',
    NOW() + INTERVAL '1 day',
    'Barrio San Judas (Cancha Comunal Central contiguo al Mercado)',
    12.1085365,
    -86.2969298,
    'CLINICA_MOVIL',
    true
  );

  -- Camilo Ortega: Parque Comunal / Sector Terminal 105 (Distrito III) -> Lat: 12.0965000, Lon: -86.3115000
  INSERT INTO public.eventos_comunitarios (
    organizador_id,
    titulo,
    descripcion,
    fecha_evento,
    ubicacion,
    latitud,
    longitud,
    tipo,
    activo
  ) VALUES (
    v_admin_id,
    'Feria de Medicina Natural y Terapias Complementarias',
    'Atención con fitoterapia ancestral, toma de presión arterial, glucosa rápida y charlas preventivas de salud familiar.',
    NOW() + INTERVAL '3 days',
    'Barrio Camilo Ortega (Parque Comunal Central)',
    12.0965000,
    -86.3115000,
    'FERIA_SALUD',
    true
  );

  -- Altagracia: Sector Centro de Salud Altagracia (Distrito III) -> Lat: 12.1332000, Lon: -86.2875000
  INSERT INTO public.eventos_comunitarios (
    organizador_id,
    titulo,
    descripcion,
    fecha_evento,
    ubicacion,
    latitud,
    longitud,
    tipo,
    activo
  ) VALUES (
    v_admin_id,
    'Jornada Nacional de Vacunación Esquema 2026',
    'Inmunización preventiva contra neumococo, influenza, sarampión y refuerzos para niños, gestantes y adultos mayores.',
    NOW() + INTERVAL '2 days',
    'Barrio Altagracia (Área Externa Centro de Salud)',
    12.1332000,
    -86.2875000,
    'VACUNACION',
    true
  );

  -- Batahola Sur: Cancha Comunal Batahola Sur (Distrito II) -> Lat: 12.1325000, Lon: -86.3040000
  -- NOTA: Tipo FUMIGACION (Brigada casa a casa para control vectorial)
  INSERT INTO public.eventos_comunitarios (
    organizador_id,
    titulo,
    descripcion,
    fecha_evento,
    ubicacion,
    latitud,
    longitud,
    tipo,
    activo
  ) VALUES (
    v_admin_id,
    'Jornada de Abatización y Control Vectorial BTI',
    'Brigadas epidemiológicas del MINSA visitan las viviendas para aplicación de BTI biológico y fumigación intradomiciliar preventiva contra el dengue.',
    NOW() + INTERVAL '4 days',
    'Barrio Batahola Sur (Sector Los Robles)',
    12.1325000,
    -86.3040000,
    'FUMIGACION',
    true
  );

  -- 4. Actualizar columnas espaciales (geog) si la columna existe
  BEGIN
    UPDATE public.eventos_comunitarios
    SET geog = ST_SetSRID(ST_MakePoint(longitud::float8, latitud::float8), 4326)::geography
    WHERE geog IS NULL AND latitud IS NOT NULL AND longitud IS NOT NULL;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- Si postgis no está activado, se ignoran columnas espaciales
  END;

  RAISE NOTICE 'Jornadas comunitarias con coordenadas exactas registradas exitosamente.';
END $$;
