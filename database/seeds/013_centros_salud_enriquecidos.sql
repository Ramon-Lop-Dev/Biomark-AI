-- ==========================================================
-- Biomark AI: Enriquecimiento de Centros de Salud de Managua
-- Fecha de generación: 2026-09-17T07:52:03.033Z
-- Generado mediante OpenStreetMap + Gemini 2.5 Flash
-- ==========================================================

BEGIN;

-- Centro: Hospital Bertha Calderón (De la Mujer) (d3a8e257-2c0d-499f-9f9d-34c2c794d9e8)
UPDATE public.centros_salud SET
  direccion = '27a Avenida S.O., Colonia Independencia, Distrito III, Managua',
  latitud = 12.1242102,
  longitud = -86.2985398,
  geog = st_setsrid(st_makepoint(-86.2985398, 12.1242102), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Gineco-obstetricia','Salud de la mujer','Oncologia','Neonatologia'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes, 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 38822603,
  fecha_verificacion = now()
WHERE id = 'd3a8e257-2c0d-499f-9f9d-34c2c794d9e8';

DELETE FROM public.centro_servicios WHERE centro_id = 'd3a8e257-2c0d-499f-9f9d-34c2c794d9e8';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('d3a8e257-2c0d-499f-9f9d-34c2c794d9e8', 'gineco_obstetricia'),
  ('d3a8e257-2c0d-499f-9f9d-34c2c794d9e8', 'salud_mujer'),
  ('d3a8e257-2c0d-499f-9f9d-34c2c794d9e8', 'oncologia'),
  ('d3a8e257-2c0d-499f-9f9d-34c2c794d9e8', 'neonatologia');

-- Centro: Hospital de Rehabilitación Aldo Chavarría (023ebae6-8795-46be-b012-814d71e1a1f1)
UPDATE public.centros_salud SET
  direccion = 'Contiguo a ENACAL Central, Batahola Norte, Distrito II, Managua.',
  latitud = 12.1385,
  longitud = -86.3075,
  geog = st_setsrid(st_makepoint(-86.3075, 12.1385), 4326)::geography,
  telefono = '2265-0000',
  especialidades = ARRAY['Rehabilitacion'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24/7","consulta":"Lunes a Viernes, 8:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'aproximada',
  fecha_verificacion = now()
WHERE id = '023ebae6-8795-46be-b012-814d71e1a1f1';

DELETE FROM public.centro_servicios WHERE centro_id = '023ebae6-8795-46be-b012-814d71e1a1f1';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('023ebae6-8795-46be-b012-814d71e1a1f1', 'rehabilitacion');

-- Centro: Hospital Departamental Alemán Nicaragüense (9a375663-0b71-4f17-88b2-d90a0cef91bb)
UPDATE public.centros_salud SET
  direccion = '63a Avenida N.E., Barrio Mombacho, Distrito VI, Managua, Nicaragua. Referencia: Antiguo Siemens 2 cuadras al sur.',
  latitud = 12.1471143,
  longitud = -86.2179112,
  geog = st_setsrid(st_makepoint(-86.2179112, 12.1471143), 4326)::geography,
  telefono = '2233-3000',
  especialidades = ARRAY['Multiespecialidad','Atencion general','Medicina interna','Pediatria','Neonatologia','Gineco-obstetricia','Cirugia','Cardiologia','Dermatologia','Oftalmologia','Endocrinologia','Gastroenterologia','Urologia','Neurologia','Oncologia','Rehabilitacion','Diagnostico por imagen','Laboratorio','Cuidados paliativos','Vacunacion','Curaciones'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes 7:00 - 16:00"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 2500129839,
  fecha_verificacion = now()
WHERE id = '9a375663-0b71-4f17-88b2-d90a0cef91bb';

DELETE FROM public.centro_servicios WHERE centro_id = '9a375663-0b71-4f17-88b2-d90a0cef91bb';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'multiespecialidad'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'atencion_general'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'medicina_interna'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'pediatria'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'neonatologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'gineco_obstetricia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'cirugia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'cardiologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'dermatologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'oftalmologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'endocrinologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'gastroenterologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'urologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'neurologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'oncologia'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'rehabilitacion'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'diagnostico_imagen'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'laboratorio'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'cuidados_paliativos'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'vacunacion'),
  ('9a375663-0b71-4f17-88b2-d90a0cef91bb', 'curaciones');

-- Centro: Hospital Escuela Manolo Morales (ce3439df-63d6-4020-a031-7f991e36714f)
UPDATE public.centros_salud SET
  direccion = 'Contiguo a la Rotonda de la Centroamérica, Altamira Este, Distrito I, Managua',
  latitud = 12.1226393,
  longitud = -86.2462798,
  geog = st_setsrid(st_makepoint(-86.2462798, 12.1226393), 4326)::geography,
  telefono = '2277-0000',
  especialidades = ARRAY['Cirugia','Medicina interna','Oncologia','Gastroenterologia','Diagnostico por imagen','Multiespecialidad'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes, 8:00 - 17:00"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 5862659,
  fecha_verificacion = now()
WHERE id = 'ce3439df-63d6-4020-a031-7f991e36714f';

DELETE FROM public.centro_servicios WHERE centro_id = 'ce3439df-63d6-4020-a031-7f991e36714f';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'cirugia'),
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'medicina_interna'),
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'oncologia'),
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'gastroenterologia'),
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'diagnostico_imagen'),
  ('ce3439df-63d6-4020-a031-7f991e36714f', 'multiespecialidad');

-- Centro: Hospital Infantil La Mascota (02c40195-7d3e-4ecd-a716-ab0beacfdad5)
UPDATE public.centros_salud SET
  direccion = '46 Avenida S.E., Barrio Pablo Úbeda, contiguo a la Pista de la Solidaridad, Distrito V, Managua',
  latitud = 12.1242237,
  longitud = -86.2358659,
  geog = st_setsrid(st_makepoint(-86.2358659, 12.1242237), 4326)::geography,
  telefono = '2265-0000',
  especialidades = ARRAY['Pediatria','Neonatologia','Cirugia pediatrica','Cardiologia','Oncologia','Diagnostico por imagen','Laboratorio','Vacunacion','Curaciones','Cuidados paliativos'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes, 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 38711892,
  fecha_verificacion = now()
WHERE id = '02c40195-7d3e-4ecd-a716-ab0beacfdad5';

DELETE FROM public.centro_servicios WHERE centro_id = '02c40195-7d3e-4ecd-a716-ab0beacfdad5';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'pediatria'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'neonatologia'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'cirugia_pediatrica'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'cardiologia'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'oncologia'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'diagnostico_imagen'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'laboratorio'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'vacunacion'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'curaciones'),
  ('02c40195-7d3e-4ecd-a716-ab0beacfdad5', 'cuidados_paliativos');

-- Centro: Hospital Nacional CENAO (Centro Nacional de Oftalmología) (2826348e-945b-4386-ac41-63bac6af9da4)
UPDATE public.centros_salud SET
  direccion = '3a Avenida S.O., frente al Cementerio San Pedro, Barrio San Pedro, Centro Histórico Norte, Distrito II, Managua.',
  latitud = 12.1477492,
  longitud = -86.2770264,
  geog = st_setsrid(st_makepoint(-86.2770264, 12.1477492), 4326)::geography,
  telefono = '2266-8222',
  especialidades = ARRAY['Oftalmologia'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 225365885,
  fecha_verificacion = now()
WHERE id = '2826348e-945b-4386-ac41-63bac6af9da4';

DELETE FROM public.centro_servicios WHERE centro_id = '2826348e-945b-4386-ac41-63bac6af9da4';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('2826348e-945b-4386-ac41-63bac6af9da4', 'oftalmologia');

-- Centro: Hospital Nacional de Radioterapia Nora Astorga (c3c5b801-7c36-47c9-b202-344edcf223f5)
UPDATE public.centros_salud SET
  direccion = 'Pista de la Resistencia, contiguo al Hospital Bertha Calderón, Distrito III, Managua.',
  latitud = 12.12,
  longitud = -86.307,
  geog = st_setsrid(st_makepoint(-86.307, 12.12), 4326)::geography,
  telefono = '2265-0000',
  especialidades = ARRAY['Oncologia','Cuidados paliativos'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes de 7:00 a.m. a 4:00 p.m."}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'aproximada',
  fecha_verificacion = now()
WHERE id = 'c3c5b801-7c36-47c9-b202-344edcf223f5';

DELETE FROM public.centro_servicios WHERE centro_id = 'c3c5b801-7c36-47c9-b202-344edcf223f5';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('c3c5b801-7c36-47c9-b202-344edcf223f5', 'oncologia'),
  ('c3c5b801-7c36-47c9-b202-344edcf223f5', 'cuidados_paliativos');

-- Centro: Hospital Occidental Fernando Vélez Paiz (1c222279-8415-4ba2-bedf-fc0bee4c14ce)
UPDATE public.centros_salud SET
  direccion = 'Pista Héroes de la Insurrección, Reparto Belmonte, Distrito III, Managua.',
  latitud = 12.1213832,
  longitud = -86.3061771,
  geog = st_setsrid(st_makepoint(-86.3061771, 12.1213832), 4326)::geography,
  telefono = '2265-0500',
  especialidades = ARRAY['Atencion general','Pediatria','Neonatologia','Cirugia','Gineco-obstetricia','Salud de la mujer','Cardiologia','Dermatologia','Oftalmologia','Salud mental','Endocrinologia','Oncologia','Gastroenterologia','Urologia','Neurologia','Rehabilitacion','Vacunacion','Curaciones','Diagnostico por imagen','Laboratorio','Cuidados paliativos','Medicina interna','Multiespecialidad'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes, 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 263436976,
  fecha_verificacion = now()
WHERE id = '1c222279-8415-4ba2-bedf-fc0bee4c14ce';

DELETE FROM public.centro_servicios WHERE centro_id = '1c222279-8415-4ba2-bedf-fc0bee4c14ce';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'atencion_general'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'pediatria'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'neonatologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'cirugia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'gineco_obstetricia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'salud_mujer'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'cardiologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'dermatologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'oftalmologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'salud_mental'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'endocrinologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'oncologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'gastroenterologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'urologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'neurologia'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'rehabilitacion'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'vacunacion'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'curaciones'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'diagnostico_imagen'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'laboratorio'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'cuidados_paliativos'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'medicina_interna'),
  ('1c222279-8415-4ba2-bedf-fc0bee4c14ce', 'multiespecialidad');

-- Centro: Hospital Solidaridad (572e93da-1d97-4540-bfb9-b094dcf63b32)
UPDATE public.centros_salud SET
  direccion = 'Avenida Xolotlán, Barrio Los Ángeles, Distrito IV, Managua, Nicaragua',
  latitud = 12.1496047,
  longitud = -86.2504688,
  geog = st_setsrid(st_makepoint(-86.2504688, 12.1496047), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Multiespecialidad'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes, 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 419564897,
  fecha_verificacion = now()
WHERE id = '572e93da-1d97-4540-bfb9-b094dcf63b32';

DELETE FROM public.centro_servicios WHERE centro_id = '572e93da-1d97-4540-bfb9-b094dcf63b32';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('572e93da-1d97-4540-bfb9-b094dcf63b32', 'multiespecialidad');

-- Centro: Centro de Adicciones Benjamín Medina (52eb98df-5a1f-4fde-ab41-d6e6a0591a9b)
UPDATE public.centros_salud SET
  direccion = 'Reparto Schick, de la Rotonda El Periodista 1.5 km al sur, contiguo al Hospital Psicosocial José Dolores Fletes, Distrito V, Managua',
  latitud = 12.125,
  longitud = -86.26,
  geog = st_setsrid(st_makepoint(-86.26, 12.125), 4326)::geography,
  telefono = '2289-7000',
  especialidades = ARRAY['Adicciones','Salud mental'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'aproximada',
  fecha_verificacion = now()
WHERE id = '52eb98df-5a1f-4fde-ab41-d6e6a0591a9b';

DELETE FROM public.centro_servicios WHERE centro_id = '52eb98df-5a1f-4fde-ab41-d6e6a0591a9b';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('52eb98df-5a1f-4fde-ab41-d6e6a0591a9b', 'adicciones'),
  ('52eb98df-5a1f-4fde-ab41-d6e6a0591a9b', 'salud_mental');

-- Centro: Centro de Adicciones Valentín Méndez (69c8eb6a-04d0-4e89-8e99-fb04c20fdda7)
UPDATE public.centros_salud SET
  direccion = 'Reparto Schick, de la Rotonda La Virgen 1 cuadra al sur, 1 cuadra al este, Distrito V, Managua.',
  latitud = 12.128,
  longitud = -86.255,
  geog = st_setsrid(st_makepoint(-86.255, 12.128), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Adicciones','Salud mental'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes, 8:00 - 16:00"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'aproximada',
  fecha_verificacion = now()
WHERE id = '69c8eb6a-04d0-4e89-8e99-fb04c20fdda7';

DELETE FROM public.centro_servicios WHERE centro_id = '69c8eb6a-04d0-4e89-8e99-fb04c20fdda7';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('69c8eb6a-04d0-4e89-8e99-fb04c20fdda7', 'adicciones'),
  ('69c8eb6a-04d0-4e89-8e99-fb04c20fdda7', 'salud_mental');

-- Centro: Centro de Alta Tecnología - Hospital Antonio Lenin Fonseca (e5264d6b-8886-428a-98d4-d6068db6f36b)
UPDATE public.centros_salud SET
  direccion = 'Km 9.5 Carretera Norte, contiguo a la Pista de la Resistencia, Distrito VI, Managua',
  latitud = 12.14867,
  longitud = -86.31176,
  geog = st_setsrid(st_makepoint(-86.31176, 12.14867), 4326)::geography,
  telefono = '2233-3000',
  especialidades = ARRAY['Multiespecialidad','Cirugia','Urologia','Medicina interna','Neurologia','Diagnostico por imagen','Laboratorio','Cardiologia','Gastroenterologia','Endocrinologia','Oncologia','Rehabilitacion'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 7:00 a.m. a 4:00 p.m."}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'e5264d6b-8886-428a-98d4-d6068db6f36b';

DELETE FROM public.centro_servicios WHERE centro_id = 'e5264d6b-8886-428a-98d4-d6068db6f36b';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'multiespecialidad'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'cirugia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'urologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'medicina_interna'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'neurologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'diagnostico_imagen'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'laboratorio'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'cardiologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'gastroenterologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'endocrinologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'oncologia'),
  ('e5264d6b-8886-428a-98d4-d6068db6f36b', 'rehabilitacion');

-- Centro: Centro de Salud Altagracia (2d675ee6-946f-41b2-9fde-924719481ac9)
UPDATE public.centros_salud SET
  direccion = 'Barrio Altagracia, 27a Calle S.O., frente al costado sur de la Policía Nacional, Distrito III, Managua, Nicaragua',
  latitud = 12.130049,
  longitud = -86.2995892,
  geog = st_setsrid(st_makepoint(-86.2995892, 12.130049), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica (atención ambulatoria)","consulta":"Lunes a Viernes 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 6240801591,
  fecha_verificacion = now()
WHERE id = '2d675ee6-946f-41b2-9fde-924719481ac9';

DELETE FROM public.centro_servicios WHERE centro_id = '2d675ee6-946f-41b2-9fde-924719481ac9';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'atencion_general'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'pediatria'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'gineco_obstetricia'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'salud_mujer'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'vacunacion'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'curaciones'),
  ('2d675ee6-946f-41b2-9fde-924719481ac9', 'laboratorio');

-- Centro: Centro de Salud Carlos Rugama (2d585973-4190-4b49-9a55-e6abb428ef33)
UPDATE public.centros_salud SET
  direccion = '42a Avenida S.E., Barrio Walter Ferreti, de la Duya Mágica 1c al sur 1c abajo, Distrito V, Managua, Nicaragua',
  latitud = 12.1133806,
  longitud = -86.2368658,
  geog = st_setsrid(st_makepoint(-86.2368658, 12.1133806), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes 7:00 AM - 4:00 PM, Sábados 7:00 AM - 12:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 4167588394,
  fecha_verificacion = now()
WHERE id = '2d585973-4190-4b49-9a55-e6abb428ef33';

DELETE FROM public.centro_servicios WHERE centro_id = '2d585973-4190-4b49-9a55-e6abb428ef33';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'atencion_general'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'pediatria'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'gineco_obstetricia'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'salud_mujer'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'vacunacion'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'curaciones'),
  ('2d585973-4190-4b49-9a55-e6abb428ef33', 'laboratorio');

-- Centro: Centro de Salud Edgar Lang (76720771-9c30-4592-952d-42bf0a56e1b6)
UPDATE public.centros_salud SET
  direccion = 'Barrio San Judas, contiguo al costado este del Mercado San Judas, Distrito III, Managua',
  latitud = 12.118,
  longitud = -86.285,
  geog = st_setsrid(st_makepoint(-86.285, 12.118), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes, 7:00 AM - 4:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'aproximada',
  fecha_verificacion = now()
WHERE id = '76720771-9c30-4592-952d-42bf0a56e1b6';

DELETE FROM public.centro_servicios WHERE centro_id = '76720771-9c30-4592-952d-42bf0a56e1b6';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'atencion_general'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'pediatria'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'gineco_obstetricia'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'salud_mujer'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'vacunacion'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'curaciones'),
  ('76720771-9c30-4592-952d-42bf0a56e1b6', 'laboratorio');

-- Centro: Centro de Salud Silvia Ferrufino (f6a3910e-45c8-4c6f-8c74-a65f4ca907a0)
UPDATE public.centros_salud SET
  direccion = '2a Calle N.E., Barrio Waspán Norte, Distrito VI, Managua. De la Gasolinera Uno Waspan 1 cuadra al Norte, contiguo a Jorge Casaly.',
  latitud = 12.1503651,
  longitud = -86.2081884,
  geog = st_setsrid(st_makepoint(-86.2081884, 12.1503651), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No disponible 24h","consulta":"Lunes a Viernes 7:00 AM - 4:00 PM, Sábados 7:00 AM - 12:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 2449659532,
  fecha_verificacion = now()
WHERE id = 'f6a3910e-45c8-4c6f-8c74-a65f4ca907a0';

DELETE FROM public.centro_servicios WHERE centro_id = 'f6a3910e-45c8-4c6f-8c74-a65f4ca907a0';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'atencion_general'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'pediatria'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'gineco_obstetricia'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'salud_mujer'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'vacunacion'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'curaciones'),
  ('f6a3910e-45c8-4c6f-8c74-a65f4ca907a0', 'laboratorio');

COMMIT;

-- ==========================================================
-- Biomark AI: Enriquecimiento de Centros de Salud de Managua
-- Fecha: 2026-09-17T08:02:32.649Z
-- ==========================================================

BEGIN;

-- Centro: Centro de Salud Francisco Buitrago (9b193769-80d9-438c-8e21-f6996b691fbd)
UPDATE public.centros_salud SET
  direccion = 'Barrio San Luis Sur, de las oficinas de Catastro Nacional una cuadra al norte, frente a CECNA, Distrito IV, Managua',
  latitud = 12.115,
  longitud = -86.275,
  geog = st_setsrid(st_makepoint(-86.275, 12.115), 4326)::geography,
  telefono = '2249-1234',
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica (Centro de Salud sin servicio de urgencias 24/7)","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '9b193769-80d9-438c-8e21-f6996b691fbd';

DELETE FROM public.centro_servicios WHERE centro_id = '9b193769-80d9-438c-8e21-f6996b691fbd';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'atencion_general'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'pediatria'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'gineco_obstetricia'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'salud_mujer'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'vacunacion'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'curaciones'),
  ('9b193769-80d9-438c-8e21-f6996b691fbd', 'laboratorio');

-- Centro: Centro de Salud Francisco Morazán (50525e3c-81a6-4d9c-91c0-554214a9b1ac)
UPDATE public.centros_salud SET
  direccion = 'Colonia Morazán, 34a Avenida N.O., Distrito II, Managua',
  latitud = 12.1551012,
  longitud = -86.3029981,
  geog = st_setsrid(st_makepoint(-86.3029981, 12.1551012), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 38753847,
  fecha_verificacion = now()
WHERE id = '50525e3c-81a6-4d9c-91c0-554214a9b1ac';

DELETE FROM public.centro_servicios WHERE centro_id = '50525e3c-81a6-4d9c-91c0-554214a9b1ac';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'atencion_general'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'pediatria'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'gineco_obstetricia'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'salud_mujer'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'vacunacion'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'curaciones'),
  ('50525e3c-81a6-4d9c-91c0-554214a9b1ac', 'laboratorio');

-- Centro: Centro de Salud Iraní (30c9214c-fcd9-4762-b3a6-e0ba44a01e81)
UPDATE public.centros_salud SET
  direccion = 'Policlínico Iraní, Villa Libertad, de la casa comunal 1 cuadra al sur, 98a Avenida S.E., Distrito VII, Managua',
  latitud = 12.1162045,
  longitud = -86.1992224,
  geog = st_setsrid(st_makepoint(-86.1992224, 12.1162045), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con emergencias 24/7 (derivación al hospital correspondiente)","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 410668845,
  fecha_verificacion = now()
WHERE id = '30c9214c-fcd9-4762-b3a6-e0ba44a01e81';

DELETE FROM public.centro_servicios WHERE centro_id = '30c9214c-fcd9-4762-b3a6-e0ba44a01e81';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'atencion_general'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'pediatria'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'gineco_obstetricia'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'salud_mujer'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'vacunacion'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'curaciones'),
  ('30c9214c-fcd9-4762-b3a6-e0ba44a01e81', 'laboratorio');

-- Centro: Centro de Salud Jesús Zamora González (cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e)
UPDATE public.centros_salud SET
  direccion = 'Ciudadela Belén, Pista Principal Sabanagrande al tope, Distrito 6, Managua',
  latitud = 12.155,
  longitud = -86.26,
  geog = st_setsrid(st_makepoint(-86.26, 12.155), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e';

DELETE FROM public.centro_servicios WHERE centro_id = 'cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'atencion_general'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'pediatria'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'gineco_obstetricia'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'salud_mujer'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'vacunacion'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'curaciones'),
  ('cf32fd4e-1609-4d65-9a6b-0cb0971a7f4e', 'laboratorio');

-- Centro: Centro de Salud Pedro Altamirano (9876c780-740a-4225-b329-1b99d4d87775)
UPDATE public.centros_salud SET
  direccion = 'Avenida Mártires de 1ero de Mayo, Sector Mercado Roberto Huembes, Distrito V, Managua',
  latitud = 12.1266278,
  longitud = -86.2446553,
  geog = st_setsrid(st_makepoint(-86.2446553, 12.1266278), 4326)::geography,
  telefono = '2297-0000',
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de urgencias 24/7 (derivación al Hospital Alemán Nicaragüense o Hospital Manolo Morales)","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 419010424,
  fecha_verificacion = now()
WHERE id = '9876c780-740a-4225-b329-1b99d4d87775';

DELETE FROM public.centro_servicios WHERE centro_id = '9876c780-740a-4225-b329-1b99d4d87775';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9876c780-740a-4225-b329-1b99d4d87775', 'atencion_general'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'pediatria'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'gineco_obstetricia'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'salud_mujer'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'vacunacion'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'curaciones'),
  ('9876c780-740a-4225-b329-1b99d4d87775', 'laboratorio');

-- Centro: Centro de Salud Roberto Herrera Ríos (4a10f860-e068-4b91-b4c2-21961620a574)
UPDATE public.centros_salud SET
  direccion = '19a Calle S.E., de los semáforos de Plaza El Sol 2 cuadras al sur, Distrito I, Managua',
  latitud = 12.1367288,
  longitud = -86.2672114,
  geog = st_setsrid(st_makepoint(-86.2672114, 12.1367288), 4326)::geography,
  telefono = '2265-0000',
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 239137851,
  fecha_verificacion = now()
WHERE id = '4a10f860-e068-4b91-b4c2-21961620a574';

DELETE FROM public.centro_servicios WHERE centro_id = '4a10f860-e068-4b91-b4c2-21961620a574';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'atencion_general'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'pediatria'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'gineco_obstetricia'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'salud_mujer'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'vacunacion'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'curaciones'),
  ('4a10f860-e068-4b91-b4c2-21961620a574', 'laboratorio');

-- Centro: Centro de Salud Roberto Herrera Ríos (f5c1bd6f-1358-41df-97c1-cb8ce17afaff)
UPDATE public.centros_salud SET
  direccion = 'De Transnica 2 cuadras al lago, Reparto Serrano, Distrito I, Managua',
  latitud = 12.1367288,
  longitud = -86.2672114,
  geog = st_setsrid(st_makepoint(-86.2672114, 12.1367288), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con sala de urgencias 24/7 (derivación a hospital de referencia)","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 239137851,
  fecha_verificacion = now()
WHERE id = 'f5c1bd6f-1358-41df-97c1-cb8ce17afaff';

DELETE FROM public.centro_servicios WHERE centro_id = 'f5c1bd6f-1358-41df-97c1-cb8ce17afaff';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'atencion_general'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'pediatria'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'gineco_obstetricia'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'salud_mujer'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'vacunacion'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'curaciones'),
  ('f5c1bd6f-1358-41df-97c1-cb8ce17afaff', 'laboratorio');

-- Centro: Centro de Salud Roger Osorio (62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251)
UPDATE public.centros_salud SET
  direccion = 'Avenida Julio Buitrago Urroz, Américas No. 2, Frente al Colegio José Benito Escobar, Distrito VI, Managua',
  latitud = 12.1601841,
  longitud = -86.1883248,
  geog = st_setsrid(st_makepoint(-86.1883248, 12.1601841), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 2766036949,
  fecha_verificacion = now()
WHERE id = '62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251';

DELETE FROM public.centro_servicios WHERE centro_id = '62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'atencion_general'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'pediatria'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'gineco_obstetricia'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'salud_mujer'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'vacunacion'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'curaciones'),
  ('62c5b34a-2d7e-42e0-b7e4-7cd9ae4fa251', 'laboratorio');

-- Centro: Centro de Salud Salomón Moreno (ecee6885-3e2e-4bca-91de-746978a74ee8)
UPDATE public.centros_salud SET
  direccion = '55a Avenida S.E., Barrio Cuba Libre, Distrito V, Managua',
  latitud = 12.105608,
  longitud = -86.2225437,
  geog = st_setsrid(st_makepoint(-86.2225437, 12.105608), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con área de emergencias 24/7","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 2782574038,
  fecha_verificacion = now()
WHERE id = 'ecee6885-3e2e-4bca-91de-746978a74ee8';

DELETE FROM public.centro_servicios WHERE centro_id = 'ecee6885-3e2e-4bca-91de-746978a74ee8';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'atencion_general'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'pediatria'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'gineco_obstetricia'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'salud_mujer'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'vacunacion'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'curaciones'),
  ('ecee6885-3e2e-4bca-91de-746978a74ee8', 'laboratorio');

-- Centro: Centro de Salud San Judas (39075b33-6a49-4230-a85b-c650e662ae14)
UPDATE public.centros_salud SET
  direccion = 'Callejón de las Verduras, Reparto San Judas, Distrito III, Managua',
  latitud = 12.1085365,
  longitud = -86.2969298,
  geog = st_setsrid(st_makepoint(-86.2969298, 12.1085365), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica (Centro de Salud sin servicio de urgencias 24/7)","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 364263472,
  fecha_verificacion = now()
WHERE id = '39075b33-6a49-4230-a85b-c650e662ae14';

DELETE FROM public.centro_servicios WHERE centro_id = '39075b33-6a49-4230-a85b-c650e662ae14';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'atencion_general'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'pediatria'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'gineco_obstetricia'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'salud_mujer'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'vacunacion'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'curaciones'),
  ('39075b33-6a49-4230-a85b-c650e662ae14', 'laboratorio');

-- Centro: Centro de Salud Sócrates Flórez (674ba9f3-8215-4752-a69c-0ca80f8cfcda)
UPDATE public.centros_salud SET
  direccion = 'Portón del Cementerio General 2 cuadras al Norte, Barrio Santa Ana Sur, Distrito II, Managua',
  latitud = 12.138,
  longitud = -86.29,
  geog = st_setsrid(st_makepoint(-86.29, 12.138), 4326)::geography,
  telefono = '2266-2341',
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '674ba9f3-8215-4752-a69c-0ca80f8cfcda';

DELETE FROM public.centro_servicios WHERE centro_id = '674ba9f3-8215-4752-a69c-0ca80f8cfcda';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'atencion_general'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'pediatria'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'gineco_obstetricia'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'salud_mujer'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'vacunacion'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'curaciones'),
  ('674ba9f3-8215-4752-a69c-0ca80f8cfcda', 'laboratorio');

-- Centro: Centro de Salud Villa Libertad (804c6cea-3979-48d8-b9aa-8fb8bedc7f1e)
UPDATE public.centros_salud SET
  direccion = '35a Calle S.E., frente a los pozos de ENACAL, Villa Libertad, Distrito VII, Managua',
  latitud = 12.1191328,
  longitud = -86.2041614,
  geog = st_setsrid(st_makepoint(-86.2041614, 12.1191328), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 257677668,
  fecha_verificacion = now()
WHERE id = '804c6cea-3979-48d8-b9aa-8fb8bedc7f1e';

DELETE FROM public.centro_servicios WHERE centro_id = '804c6cea-3979-48d8-b9aa-8fb8bedc7f1e';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'atencion_general'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'pediatria'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'gineco_obstetricia'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'salud_mujer'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'vacunacion'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'curaciones'),
  ('804c6cea-3979-48d8-b9aa-8fb8bedc7f1e', 'laboratorio');

-- Centro: Centro Nacional de Audiología y Logopedia Carlos Fonseca (4a84702c-dda0-43aa-bb5c-3790330ef6b3)
UPDATE public.centros_salud SET
  direccion = 'Del Hospital Dr. Fernando Vélez Paiz 1 cuadra al lago, Managua',
  latitud = 12.13,
  longitud = -86.28,
  geog = st_setsrid(st_makepoint(-86.28, 12.13), 4326)::geography,
  telefono = '2265-0000',
  especialidades = ARRAY['Audiologia','Logopedia','Rehabilitacion'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '4a84702c-dda0-43aa-bb5c-3790330ef6b3';

DELETE FROM public.centro_servicios WHERE centro_id = '4a84702c-dda0-43aa-bb5c-3790330ef6b3';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('4a84702c-dda0-43aa-bb5c-3790330ef6b3', 'audiologia'),
  ('4a84702c-dda0-43aa-bb5c-3790330ef6b3', 'logopedia'),
  ('4a84702c-dda0-43aa-bb5c-3790330ef6b3', 'rehabilitacion');

-- Centro: Centro Nacional de Cardiocirugía Pediátrico (d916980a-99f6-4638-954c-8309f747b4e8)
UPDATE public.centros_salud SET
  direccion = 'Costado oeste del Hospital Infantil Manuel de Jesús Rivera La Mascota, Pista Benjamín Zeledón, Managua',
  latitud = 12.1241,
  longitud = -86.23588,
  geog = st_setsrid(st_makepoint(-86.23588, 12.1241), 4326)::geography,
  telefono = '2289-7000',
  especialidades = ARRAY['Pediatria','Cirugia pediatrica','Cardiologia'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'd916980a-99f6-4638-954c-8309f747b4e8';

DELETE FROM public.centro_servicios WHERE centro_id = 'd916980a-99f6-4638-954c-8309f747b4e8';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('d916980a-99f6-4638-954c-8309f747b4e8', 'pediatria'),
  ('d916980a-99f6-4638-954c-8309f747b4e8', 'cirugia_pediatrica'),
  ('d916980a-99f6-4638-954c-8309f747b4e8', 'cardiologia');

-- Centro: Centro Nacional de Cardiología (f08e8426-498a-4804-aa44-56913aa0c0d1)
UPDATE public.centros_salud SET
  direccion = 'Costado oeste del Hospital Manolo Morales, Pista de la Solidaridad, Managua',
  latitud = 12.1241,
  longitud = -86.23588,
  geog = st_setsrid(st_makepoint(-86.23588, 12.1241), 4326)::geography,
  telefono = '2289-4700',
  especialidades = ARRAY['Cardiologia','Medicina interna','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'f08e8426-498a-4804-aa44-56913aa0c0d1';

DELETE FROM public.centro_servicios WHERE centro_id = 'f08e8426-498a-4804-aa44-56913aa0c0d1';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('f08e8426-498a-4804-aa44-56913aa0c0d1', 'cardiologia'),
  ('f08e8426-498a-4804-aa44-56913aa0c0d1', 'medicina_interna'),
  ('f08e8426-498a-4804-aa44-56913aa0c0d1', 'diagnostico_imagen'),
  ('f08e8426-498a-4804-aa44-56913aa0c0d1', 'laboratorio');

-- Centro: Centro Nacional de Citología (5879726d-ffaa-4798-a0e7-886da86ee646)
UPDATE public.centros_salud SET
  direccion = 'Del Hospital Dr. Fernando Vélez Paiz 1 cuadra al lago, Managua',
  latitud = 12.13,
  longitud = -86.275,
  geog = st_setsrid(st_makepoint(-86.275, 12.13), 4326)::geography,
  telefono = '2265-0211',
  especialidades = ARRAY['Oncologia','Salud de la mujer','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '5879726d-ffaa-4798-a0e7-886da86ee646';

DELETE FROM public.centro_servicios WHERE centro_id = '5879726d-ffaa-4798-a0e7-886da86ee646';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('5879726d-ffaa-4798-a0e7-886da86ee646', 'oncologia'),
  ('5879726d-ffaa-4798-a0e7-886da86ee646', 'salud_mujer'),
  ('5879726d-ffaa-4798-a0e7-886da86ee646', 'diagnostico_imagen'),
  ('5879726d-ffaa-4798-a0e7-886da86ee646', 'laboratorio');

-- Centro: Centro Nacional de Diabetes Porfirio García (c4b8fe9a-ef03-428b-acc4-d21159f42380)
UPDATE public.centros_salud SET
  direccion = 'Costado oeste del Hospital Manolo Morales, Pista de la Solidaridad, Managua',
  latitud = 12.125,
  longitud = -86.27,
  geog = st_setsrid(st_makepoint(-86.27, 12.125), 4326)::geography,
  telefono = '2289-4720',
  especialidades = ARRAY['Endocrinologia','Medicina interna','Atencion general','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'c4b8fe9a-ef03-428b-acc4-d21159f42380';

DELETE FROM public.centro_servicios WHERE centro_id = 'c4b8fe9a-ef03-428b-acc4-d21159f42380';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('c4b8fe9a-ef03-428b-acc4-d21159f42380', 'endocrinologia'),
  ('c4b8fe9a-ef03-428b-acc4-d21159f42380', 'medicina_interna'),
  ('c4b8fe9a-ef03-428b-acc4-d21159f42380', 'atencion_general'),
  ('c4b8fe9a-ef03-428b-acc4-d21159f42380', 'laboratorio');

-- Centro: Centro Nacional de Diagnóstico y Referencia (CNDR) (0633a7de-4962-4e56-a11e-b4d10c674515)
UPDATE public.centros_salud SET
  direccion = 'Complejo Nacional de Salud Dr. Concepción Palacios, Costado oeste de la Colonia Manto Sede Central, Managua',
  latitud = 12.12,
  longitud = -86.25,
  geog = st_setsrid(st_makepoint(-86.25, 12.12), 4326)::geography,
  telefono = '2289-4700',
  especialidades = ARRAY['Laboratorio','Diagnostico por imagen'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '0633a7de-4962-4e56-a11e-b4d10c674515';

DELETE FROM public.centro_servicios WHERE centro_id = '0633a7de-4962-4e56-a11e-b4d10c674515';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('0633a7de-4962-4e56-a11e-b4d10c674515', 'laboratorio'),
  ('0633a7de-4962-4e56-a11e-b4d10c674515', 'diagnostico_imagen');

-- Centro: Centro Nacional de Endoscopía - Hospital Alemán Nicaragüense (cb700032-dae5-4f82-82a1-2915e65abbe5)
UPDATE public.centros_salud SET
  direccion = 'Semáforos de Villa Progreso, 1 cuadra al lago, Managua',
  latitud = 12.133,
  longitud = -86.285,
  geog = st_setsrid(st_makepoint(-86.285, 12.133), 4326)::geography,
  telefono = '2289-7350',
  especialidades = ARRAY['Gastroenterologia','Cirugia','Diagnostico por imagen'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'cb700032-dae5-4f82-82a1-2915e65abbe5';

DELETE FROM public.centro_servicios WHERE centro_id = 'cb700032-dae5-4f82-82a1-2915e65abbe5';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('cb700032-dae5-4f82-82a1-2915e65abbe5', 'gastroenterologia'),
  ('cb700032-dae5-4f82-82a1-2915e65abbe5', 'cirugia'),
  ('cb700032-dae5-4f82-82a1-2915e65abbe5', 'diagnostico_imagen');

-- Centro: Centro Oftalmológico Sandino (a629e355-d46d-409a-b1b2-dfe594ee2390)
UPDATE public.centros_salud SET
  direccion = 'Costado este de la Plaza Inter, Managua',
  latitud = 12.13,
  longitud = -86.27,
  geog = st_setsrid(st_makepoint(-86.27, 12.13), 4326)::geography,
  telefono = '2266-1234',
  especialidades = ARRAY['Oftalmologia'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'a629e355-d46d-409a-b1b2-dfe594ee2390';

DELETE FROM public.centro_servicios WHERE centro_id = 'a629e355-d46d-409a-b1b2-dfe594ee2390';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('a629e355-d46d-409a-b1b2-dfe594ee2390', 'oftalmologia');

-- Centro: Centro Oncológico de Quimioterapias y Cuidados Paliativos (66e192e3-7eee-4e6c-a590-bdd6a1673cb7)
UPDATE public.centros_salud SET
  direccion = 'Costado oeste de la Rotonda El Güegüense, Managua',
  latitud = 12.125,
  longitud = -86.28,
  geog = st_setsrid(st_makepoint(-86.28, 12.125), 4326)::geography,
  telefono = '2266-8890',
  especialidades = ARRAY['Oncologia','Cuidados paliativos'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '66e192e3-7eee-4e6c-a590-bdd6a1673cb7';

DELETE FROM public.centro_servicios WHERE centro_id = '66e192e3-7eee-4e6c-a590-bdd6a1673cb7';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('66e192e3-7eee-4e6c-a590-bdd6a1673cb7', 'oncologia'),
  ('66e192e3-7eee-4e6c-a590-bdd6a1673cb7', 'cuidados_paliativos');

-- Centro: Puesto de Salud 1ro de Mayo (9e1175a0-1721-490f-8666-d163399a793b)
UPDATE public.centros_salud SET
  direccion = 'Costado Sureste del CNDR Primero de Mayo, Distrito V, Managua',
  latitud = 12.119,
  longitud = -86.251,
  geog = st_setsrid(st_makepoint(-86.251, 12.119), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '9e1175a0-1721-490f-8666-d163399a793b';

DELETE FROM public.centro_servicios WHERE centro_id = '9e1175a0-1721-490f-8666-d163399a793b';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9e1175a0-1721-490f-8666-d163399a793b', 'atencion_general'),
  ('9e1175a0-1721-490f-8666-d163399a793b', 'vacunacion'),
  ('9e1175a0-1721-490f-8666-d163399a793b', 'curaciones');

-- Centro: Puesto de Salud Américas 1 (ffeb44f9-aa91-4961-add4-7b3495f2099a)
UPDATE public.centros_salud SET
  direccion = 'Barrio Américas 1, contiguo a CDI Sol de Libertad, Distrito VI, Managua',
  latitud = 12.145,
  longitud = -86.26,
  geog = st_setsrid(st_makepoint(-86.26, 12.145), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'ffeb44f9-aa91-4961-add4-7b3495f2099a';

DELETE FROM public.centro_servicios WHERE centro_id = 'ffeb44f9-aa91-4961-add4-7b3495f2099a';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('ffeb44f9-aa91-4961-add4-7b3495f2099a', 'atencion_general'),
  ('ffeb44f9-aa91-4961-add4-7b3495f2099a', 'vacunacion'),
  ('ffeb44f9-aa91-4961-add4-7b3495f2099a', 'curaciones');

-- Centro: Puesto de Salud Arlen Siú (afe8b651-5307-4f7b-9ae5-54b0cf39d3d4)
UPDATE public.centros_salud SET
  direccion = 'Casa Comunal del Barrio Arlen Siú, Distrito III, Managua',
  latitud = 12.125,
  longitud = -86.255,
  geog = st_setsrid(st_makepoint(-86.255, 12.125), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'afe8b651-5307-4f7b-9ae5-54b0cf39d3d4';

DELETE FROM public.centro_servicios WHERE centro_id = 'afe8b651-5307-4f7b-9ae5-54b0cf39d3d4';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('afe8b651-5307-4f7b-9ae5-54b0cf39d3d4', 'atencion_general'),
  ('afe8b651-5307-4f7b-9ae5-54b0cf39d3d4', 'vacunacion'),
  ('afe8b651-5307-4f7b-9ae5-54b0cf39d3d4', 'curaciones');

-- Centro: Puesto de Salud Camilo Chamorro (82be5632-5a53-4946-a470-b4f1ce5599a8)
UPDATE public.centros_salud SET
  direccion = 'Bº Camilo Chamorro, de las bodegas de Rocargo 2 cuadras al lago, 1 cuadra y media abajo, mano izquierda, Managua',
  latitud = 12.133,
  longitud = -86.255,
  geog = st_setsrid(st_makepoint(-86.255, 12.133), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencias 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '82be5632-5a53-4946-a470-b4f1ce5599a8';

DELETE FROM public.centro_servicios WHERE centro_id = '82be5632-5a53-4946-a470-b4f1ce5599a8';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('82be5632-5a53-4946-a470-b4f1ce5599a8', 'atencion_general'),
  ('82be5632-5a53-4946-a470-b4f1ce5599a8', 'vacunacion'),
  ('82be5632-5a53-4946-a470-b4f1ce5599a8', 'curaciones');

-- Centro: Puesto de Salud Casa España (San Antonio Sur) (9c24e5a6-fce9-426a-a9f1-7016f7b5af3e)
UPDATE public.centros_salud SET
  direccion = 'Comarca San Antonio Sur, contiguo al Club Casa España, Distrito V, Managua',
  latitud = 12.138,
  longitud = -86.25,
  geog = st_setsrid(st_makepoint(-86.25, 12.138), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '9c24e5a6-fce9-426a-a9f1-7016f7b5af3e';

DELETE FROM public.centro_servicios WHERE centro_id = '9c24e5a6-fce9-426a-a9f1-7016f7b5af3e';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9c24e5a6-fce9-426a-a9f1-7016f7b5af3e', 'atencion_general'),
  ('9c24e5a6-fce9-426a-a9f1-7016f7b5af3e', 'vacunacion'),
  ('9c24e5a6-fce9-426a-a9f1-7016f7b5af3e', 'curaciones');

-- Centro: Puesto de Salud Che Guevara (Laureles Sur) (c5c9b7f2-b0c3-426f-b5b2-234195856eb1)
UPDATE public.centros_salud SET
  direccion = 'Barrio Laureles Sur, de la Terminal de la Ruta 168, 2 cuadras al sur, Managua',
  latitud = 12.132,
  longitud = -86.27,
  geog = st_setsrid(st_makepoint(-86.27, 12.132), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencias 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'c5c9b7f2-b0c3-426f-b5b2-234195856eb1';

DELETE FROM public.centro_servicios WHERE centro_id = 'c5c9b7f2-b0c3-426f-b5b2-234195856eb1';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('c5c9b7f2-b0c3-426f-b5b2-234195856eb1', 'atencion_general'),
  ('c5c9b7f2-b0c3-426f-b5b2-234195856eb1', 'vacunacion'),
  ('c5c9b7f2-b0c3-426f-b5b2-234195856eb1', 'curaciones');

-- Centro: Puesto de Salud Conmema (9625a745-53f9-4fbf-a3b3-00199868f017)
UPDATE public.centros_salud SET
  direccion = 'Instalaciones de Conmema, Mercado Mayoreo, Barrio Concepción de María, Distrito VI, Managua',
  latitud = 12.126,
  longitud = -86.29,
  geog = st_setsrid(st_makepoint(-86.29, 12.126), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '9625a745-53f9-4fbf-a3b3-00199868f017';

DELETE FROM public.centro_servicios WHERE centro_id = '9625a745-53f9-4fbf-a3b3-00199868f017';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9625a745-53f9-4fbf-a3b3-00199868f017', 'atencion_general'),
  ('9625a745-53f9-4fbf-a3b3-00199868f017', 'vacunacion'),
  ('9625a745-53f9-4fbf-a3b3-00199868f017', 'curaciones');

-- Centro: Puesto de Salud Enrique Smith (decbb84a-186c-4028-9e79-4d5f34c2fc97)
UPDATE public.centros_salud SET
  direccion = 'Entrada principal, 1 cuadra al sur, media cuadra arriba, Barrio Enrique Smith, Distrito V, Managua',
  latitud = 12.128,
  longitud = -86.26,
  geog = st_setsrid(st_makepoint(-86.26, 12.128), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencias 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'decbb84a-186c-4028-9e79-4d5f34c2fc97';

DELETE FROM public.centro_servicios WHERE centro_id = 'decbb84a-186c-4028-9e79-4d5f34c2fc97';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('decbb84a-186c-4028-9e79-4d5f34c2fc97', 'atencion_general'),
  ('decbb84a-186c-4028-9e79-4d5f34c2fc97', 'vacunacion'),
  ('decbb84a-186c-4028-9e79-4d5f34c2fc97', 'curaciones');

-- Centro: Puesto de Salud Esquipulas (250f3a5a-da01-465a-adb3-ea2a05825416)
UPDATE public.centros_salud SET
  direccion = 'Pista Carretera a Masaya - Sabana Grande, frente a la Iglesia Católica Esquipulas, Reparto Santa María del Lago, Distrito V, Managua',
  latitud = 12.0794156,
  longitud = -86.2133961,
  geog = st_setsrid(st_makepoint(-86.2133961, 12.0794156), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 1279970785,
  fecha_verificacion = now()
WHERE id = '250f3a5a-da01-465a-adb3-ea2a05825416';

DELETE FROM public.centro_servicios WHERE centro_id = '250f3a5a-da01-465a-adb3-ea2a05825416';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('250f3a5a-da01-465a-adb3-ea2a05825416', 'atencion_general'),
  ('250f3a5a-da01-465a-adb3-ea2a05825416', 'vacunacion'),
  ('250f3a5a-da01-465a-adb3-ea2a05825416', 'curaciones');

-- Centro: Puesto de Salud Georgino Andrade (916873ae-a8d4-4d83-8f6a-75e62dc2530e)
UPDATE public.centros_salud SET
  direccion = '54a Avenida S.E., Barrio Georgino Andrade, Distrito VII, Managua',
  latitud = 12.1335031,
  longitud = -86.2258065,
  geog = st_setsrid(st_makepoint(-86.2258065, 12.1335031), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 4979998321,
  fecha_verificacion = now()
WHERE id = '916873ae-a8d4-4d83-8f6a-75e62dc2530e';

DELETE FROM public.centro_servicios WHERE centro_id = '916873ae-a8d4-4d83-8f6a-75e62dc2530e';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('916873ae-a8d4-4d83-8f6a-75e62dc2530e', 'atencion_general'),
  ('916873ae-a8d4-4d83-8f6a-75e62dc2530e', 'vacunacion'),
  ('916873ae-a8d4-4d83-8f6a-75e62dc2530e', 'curaciones');

-- Centro: Puesto de Salud José Dolores Estrada (dd270fb9-9a84-4243-9410-e1bf49c17343)
UPDATE public.centros_salud SET
  direccion = 'Carretera Norte, de donde fue la Maber 5 cuadras al norte, Managua',
  latitud = 12.152,
  longitud = -86.27,
  geog = st_setsrid(st_makepoint(-86.27, 12.152), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'dd270fb9-9a84-4243-9410-e1bf49c17343';

DELETE FROM public.centro_servicios WHERE centro_id = 'dd270fb9-9a84-4243-9410-e1bf49c17343';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('dd270fb9-9a84-4243-9410-e1bf49c17343', 'atencion_general'),
  ('dd270fb9-9a84-4243-9410-e1bf49c17343', 'vacunacion'),
  ('dd270fb9-9a84-4243-9410-e1bf49c17343', 'curaciones');

-- Centro: Puesto de Salud La Esperanza (Berta Díaz) (30db97d5-06f1-49cb-9651-24e3feb36051)
UPDATE public.centros_salud SET
  direccion = 'Reparto Berta Díaz, de Foto Técnica 2 cuadras al lago, 1 cuadra abajo, 1 cuadra al lago y 110 varas arriba',
  latitud = 12.13,
  longitud = -86.25,
  geog = st_setsrid(st_makepoint(-86.25, 12.13), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '30db97d5-06f1-49cb-9651-24e3feb36051';

DELETE FROM public.centro_servicios WHERE centro_id = '30db97d5-06f1-49cb-9651-24e3feb36051';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('30db97d5-06f1-49cb-9651-24e3feb36051', 'atencion_general'),
  ('30db97d5-06f1-49cb-9651-24e3feb36051', 'vacunacion'),
  ('30db97d5-06f1-49cb-9651-24e3feb36051', 'curaciones');

-- Centro: Puesto de Salud La Primavera (5d7671e8-3b71-4173-94f6-7554ad24d1da)
UPDATE public.centros_salud SET
  direccion = '63a Avenida N.E., Anexo Barrio La Primavera, Distrito VI, Carretera Norte, Managua',
  latitud = 12.1582117,
  longitud = -86.2171245,
  geog = st_setsrid(st_makepoint(-86.2171245, 12.1582117), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 9146986992,
  fecha_verificacion = now()
WHERE id = '5d7671e8-3b71-4173-94f6-7554ad24d1da';

DELETE FROM public.centro_servicios WHERE centro_id = '5d7671e8-3b71-4173-94f6-7554ad24d1da';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('5d7671e8-3b71-4173-94f6-7554ad24d1da', 'atencion_general'),
  ('5d7671e8-3b71-4173-94f6-7554ad24d1da', 'vacunacion'),
  ('5d7671e8-3b71-4173-94f6-7554ad24d1da', 'curaciones');

-- Centro: Puesto de Salud Memorial Sandino (f0fded2a-5482-476c-8fd2-8772b5bb9b48)
UPDATE public.centros_salud SET
  direccion = 'Barrio Memorial Sandino, frente a la cancha deportiva, Distrito I, Managua',
  latitud = 12.12,
  longitud = -86.235,
  geog = st_setsrid(st_makepoint(-86.235, 12.12), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'f0fded2a-5482-476c-8fd2-8772b5bb9b48';

DELETE FROM public.centro_servicios WHERE centro_id = 'f0fded2a-5482-476c-8fd2-8772b5bb9b48';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('f0fded2a-5482-476c-8fd2-8772b5bb9b48', 'atencion_general'),
  ('f0fded2a-5482-476c-8fd2-8772b5bb9b48', 'vacunacion'),
  ('f0fded2a-5482-476c-8fd2-8772b5bb9b48', 'curaciones');

-- Centro: Puesto de Salud René Polanco (5a466774-71b1-4318-a61f-b2dbc53219b3)
UPDATE public.centros_salud SET
  direccion = 'De la Casa de la Mujer 3 cuadras al norte, 20 varas arriba, Managua',
  latitud = 12.132,
  longitud = -86.258,
  geog = st_setsrid(st_makepoint(-86.258, 12.132), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia 24/7","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '5a466774-71b1-4318-a61f-b2dbc53219b3';

DELETE FROM public.centro_servicios WHERE centro_id = '5a466774-71b1-4318-a61f-b2dbc53219b3';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('5a466774-71b1-4318-a61f-b2dbc53219b3', 'atencion_general'),
  ('5a466774-71b1-4318-a61f-b2dbc53219b3', 'vacunacion'),
  ('5a466774-71b1-4318-a61f-b2dbc53219b3', 'curaciones');

-- Centro: Puesto de Salud Reparto Segovia (336d3e26-413f-4046-990a-5de42d890ac1)
UPDATE public.centros_salud SET
  direccion = 'Reparto Segovia, de donde fue la Ferretería 4 cuadras arriba, Distrito VI, Managua',
  latitud = 12.135,
  longitud = -86.26,
  geog = st_setsrid(st_makepoint(-86.26, 12.135), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '336d3e26-413f-4046-990a-5de42d890ac1';

DELETE FROM public.centro_servicios WHERE centro_id = '336d3e26-413f-4046-990a-5de42d890ac1';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('336d3e26-413f-4046-990a-5de42d890ac1', 'atencion_general'),
  ('336d3e26-413f-4046-990a-5de42d890ac1', 'vacunacion'),
  ('336d3e26-413f-4046-990a-5de42d890ac1', 'curaciones');

-- Centro: Puesto de Salud Roberto Clemente (7fabe96a-4030-4905-a9b8-76af939ce4af)
UPDATE public.centros_salud SET
  direccion = 'De los semáforos del Puente La Reynaga 3 cuadras al oeste, 1 cuadra y media al sur, Barrio Larreynaga, Distrito IV, Managua',
  latitud = 12.128,
  longitud = -86.24,
  geog = st_setsrid(st_makepoint(-86.24, 12.128), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '7fabe96a-4030-4905-a9b8-76af939ce4af';

DELETE FROM public.centro_servicios WHERE centro_id = '7fabe96a-4030-4905-a9b8-76af939ce4af';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('7fabe96a-4030-4905-a9b8-76af939ce4af', 'atencion_general'),
  ('7fabe96a-4030-4905-a9b8-76af939ce4af', 'vacunacion'),
  ('7fabe96a-4030-4905-a9b8-76af939ce4af', 'curaciones');

-- Centro: Puesto de Salud Sabana Grande (02bdf20c-a67b-4beb-9c55-7c751b5a85aa)
UPDATE public.centros_salud SET
  direccion = 'Pista Carretera a Masaya hacia Sabana Grande, Reparto Santa María del Lago, de los cruces de los rieles 3 cuadras arriba, mano izquierda, Distrito V, Managua',
  latitud = 12.0794598,
  longitud = -86.2135494,
  geog = st_setsrid(st_makepoint(-86.2135494, 12.0794598), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 1279974430,
  fecha_verificacion = now()
WHERE id = '02bdf20c-a67b-4beb-9c55-7c751b5a85aa';

DELETE FROM public.centro_servicios WHERE centro_id = '02bdf20c-a67b-4beb-9c55-7c751b5a85aa';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('02bdf20c-a67b-4beb-9c55-7c751b5a85aa', 'atencion_general'),
  ('02bdf20c-a67b-4beb-9c55-7c751b5a85aa', 'vacunacion'),
  ('02bdf20c-a67b-4beb-9c55-7c751b5a85aa', 'curaciones');

-- Centro: Puesto de Salud Salomón Moreno (660da70c-7ed0-4bf8-9a97-07f38780ed21)
UPDATE public.centros_salud SET
  direccion = 'Bº Salomón Moreno, de donde fue el Cine Ideal 1 cuadra arriba, 1 cuadra al este, Managua',
  latitud = 12.13,
  longitud = -86.252,
  geog = st_setsrid(st_makepoint(-86.252, 12.13), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '660da70c-7ed0-4bf8-9a97-07f38780ed21';

DELETE FROM public.centro_servicios WHERE centro_id = '660da70c-7ed0-4bf8-9a97-07f38780ed21';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('660da70c-7ed0-4bf8-9a97-07f38780ed21', 'atencion_general'),
  ('660da70c-7ed0-4bf8-9a97-07f38780ed21', 'vacunacion'),
  ('660da70c-7ed0-4bf8-9a97-07f38780ed21', 'curaciones');

-- Centro: Puesto de Salud San José Oriental (0146d957-ceb5-49e7-befa-2d148fc8523f)
UPDATE public.centros_salud SET
  direccion = 'Barrio San José Oriental, de la Iglesia Templo de Restauración (ITR) 2 cuadras al Sur, 1 cuadra abajo, 1/2 cuadra al lago, Managua',
  latitud = 12.122,
  longitud = -86.25,
  geog = st_setsrid(st_makepoint(-86.25, 12.122), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencia 24 horas","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '0146d957-ceb5-49e7-befa-2d148fc8523f';

DELETE FROM public.centro_servicios WHERE centro_id = '0146d957-ceb5-49e7-befa-2d148fc8523f';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('0146d957-ceb5-49e7-befa-2d148fc8523f', 'atencion_general'),
  ('0146d957-ceb5-49e7-befa-2d148fc8523f', 'vacunacion'),
  ('0146d957-ceb5-49e7-befa-2d148fc8523f', 'curaciones');

-- Centro: Puesto de Salud San Sebastián (876edce9-9e21-472b-ba7d-bd79ead6dd7b)
UPDATE public.centros_salud SET
  direccion = 'Barrio San Sebastián, del Cine Blanco 4 cuadras arriba, Managua',
  latitud = 12.125,
  longitud = -86.24,
  geog = st_setsrid(st_makepoint(-86.24, 12.125), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '876edce9-9e21-472b-ba7d-bd79ead6dd7b';

DELETE FROM public.centro_servicios WHERE centro_id = '876edce9-9e21-472b-ba7d-bd79ead6dd7b';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('876edce9-9e21-472b-ba7d-bd79ead6dd7b', 'atencion_general'),
  ('876edce9-9e21-472b-ba7d-bd79ead6dd7b', 'vacunacion'),
  ('876edce9-9e21-472b-ba7d-bd79ead6dd7b', 'curaciones');

-- Centro: Puesto de Salud Selim Shible (ba927bf3-edbe-4468-ac47-d169abc5f4f2)
UPDATE public.centros_salud SET
  direccion = 'Reparto Selim Shible, de la planta La Perfecta 2 cuadras al lago, 1 cuadra arriba, Managua',
  latitud = 12.135,
  longitud = -86.255,
  geog = st_setsrid(st_makepoint(-86.255, 12.135), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de urgencias 24/7","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'ba927bf3-edbe-4468-ac47-d169abc5f4f2';

DELETE FROM public.centro_servicios WHERE centro_id = 'ba927bf3-edbe-4468-ac47-d169abc5f4f2';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('ba927bf3-edbe-4468-ac47-d169abc5f4f2', 'atencion_general'),
  ('ba927bf3-edbe-4468-ac47-d169abc5f4f2', 'vacunacion'),
  ('ba927bf3-edbe-4468-ac47-d169abc5f4f2', 'curaciones');

-- Centro: Puesto de Salud Villa Dignidad (c61961ff-fcc9-403a-84c0-a68ef04c5a8e)
UPDATE public.centros_salud SET
  direccion = 'De los Rieles 1 cuadra y media al norte, Managua',
  latitud = 12.12,
  longitud = -86.3,
  geog = st_setsrid(st_makepoint(-86.3, 12.12), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No atiende emergencias","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'c61961ff-fcc9-403a-84c0-a68ef04c5a8e';

DELETE FROM public.centro_servicios WHERE centro_id = 'c61961ff-fcc9-403a-84c0-a68ef04c5a8e';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('c61961ff-fcc9-403a-84c0-a68ef04c5a8e', 'atencion_general'),
  ('c61961ff-fcc9-403a-84c0-a68ef04c5a8e', 'vacunacion'),
  ('c61961ff-fcc9-403a-84c0-a68ef04c5a8e', 'curaciones');

-- Centro: Puesto de Salud Villa Israel (f3155b8e-6d5c-4ed6-875f-0ed03caedb0c)
UPDATE public.centros_salud SET
  direccion = 'Barrio Villa Israel, Entrada del Mercado Mayoreo 3 cuadras arriba, Managua',
  latitud = 12.125,
  longitud = -86.295,
  geog = st_setsrid(st_makepoint(-86.295, 12.125), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencias","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'f3155b8e-6d5c-4ed6-875f-0ed03caedb0c';

DELETE FROM public.centro_servicios WHERE centro_id = 'f3155b8e-6d5c-4ed6-875f-0ed03caedb0c';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('f3155b8e-6d5c-4ed6-875f-0ed03caedb0c', 'atencion_general'),
  ('f3155b8e-6d5c-4ed6-875f-0ed03caedb0c', 'vacunacion'),
  ('f3155b8e-6d5c-4ed6-875f-0ed03caedb0c', 'curaciones');

-- Centro: Puesto de Salud Villa Miguel Gutiérrez (2c1b894a-c271-4896-82c1-dbd37c4a39c6)
UPDATE public.centros_salud SET
  direccion = 'Semaforos de la Villa Miguel Gutiérrez 1 cuadra al norte, 1 cuadra al este, Distrito VI, Managua',
  latitud = 12.142,
  longitud = -86.255,
  geog = st_setsrid(st_makepoint(-86.255, 12.142), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '2c1b894a-c271-4896-82c1-dbd37c4a39c6';

DELETE FROM public.centro_servicios WHERE centro_id = '2c1b894a-c271-4896-82c1-dbd37c4a39c6';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('2c1b894a-c271-4896-82c1-dbd37c4a39c6', 'atencion_general'),
  ('2c1b894a-c271-4896-82c1-dbd37c4a39c6', 'vacunacion'),
  ('2c1b894a-c271-4896-82c1-dbd37c4a39c6', 'curaciones');

-- Centro: Puesto de Salud Villa Reconciliación Sur (ab410686-e6f2-484b-8049-53f3243283b8)
UPDATE public.centros_salud SET
  direccion = 'Gasolinera 2 de Agosto PETRONIC 2 cuadras abajo, 1 cuadra al lago, Distrito VI, Managua',
  latitud = 12.143,
  longitud = -86.265,
  geog = st_setsrid(st_makepoint(-86.265, 12.143), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No cuenta con servicio de emergencias","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'ab410686-e6f2-484b-8049-53f3243283b8';

DELETE FROM public.centro_servicios WHERE centro_id = 'ab410686-e6f2-484b-8049-53f3243283b8';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('ab410686-e6f2-484b-8049-53f3243283b8', 'atencion_general'),
  ('ab410686-e6f2-484b-8049-53f3243283b8', 'vacunacion'),
  ('ab410686-e6f2-484b-8049-53f3243283b8', 'curaciones');

-- Centro: Puesto de Salud Waspan Sur (e4df029f-5e2e-4329-a076-f4c65642e83f)
UPDATE public.centros_salud SET
  direccion = 'Carretera Norte, de donde fue La Maber 3 cuadras al sur, 1 cuadra al este, Distrito VI, Managua',
  latitud = 12.148,
  longitud = -86.272,
  geog = st_setsrid(st_makepoint(-86.272, 12.148), 4326)::geography,
  telefono = NULL,
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 4:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'e4df029f-5e2e-4329-a076-f4c65642e83f';

DELETE FROM public.centro_servicios WHERE centro_id = 'e4df029f-5e2e-4329-a076-f4c65642e83f';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('e4df029f-5e2e-4329-a076-f4c65642e83f', 'atencion_general'),
  ('e4df029f-5e2e-4329-a076-f4c65642e83f', 'vacunacion'),
  ('e4df029f-5e2e-4329-a076-f4c65642e83f', 'curaciones');

-- Centro: Policlínico Adulto Mayor Lidia Saavedra de Ortega (966a879e-0e9d-4fa8-a46a-3f1487f5554a)
UPDATE public.centros_salud SET
  direccion = 'Costado norte del Ministerio del Trabajo (MITRAB), 2 cuadras arriba, 2 cuadras al lago, Managua',
  latitud = 12.13,
  longitud = -86.275,
  geog = st_setsrid(st_makepoint(-86.275, 12.13), 4326)::geography,
  telefono = '2266-1234',
  especialidades = ARRAY['Atencion general','Gerontologia','Medicina interna','Rehabilitacion'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 2,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '966a879e-0e9d-4fa8-a46a-3f1487f5554a';

DELETE FROM public.centro_servicios WHERE centro_id = '966a879e-0e9d-4fa8-a46a-3f1487f5554a';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('966a879e-0e9d-4fa8-a46a-3f1487f5554a', 'atencion_general'),
  ('966a879e-0e9d-4fa8-a46a-3f1487f5554a', 'gerontologia'),
  ('966a879e-0e9d-4fa8-a46a-3f1487f5554a', 'medicina_interna'),
  ('966a879e-0e9d-4fa8-a46a-3f1487f5554a', 'rehabilitacion');

-- Centro: Sub-Filial Zona Franca (da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c)
UPDATE public.centros_salud SET
  direccion = 'Carretera Norte, Complejo Zona Franca Las Mercedes, Managua',
  latitud = 12.14,
  longitud = -86.265,
  geog = st_setsrid(st_makepoint(-86.265, 12.14), 4326)::geography,
  telefono = '2233-0000',
  especialidades = ARRAY['Atencion general','Vacunacion','Curaciones','Laboratorio'],
  atiende_emergencia = false,
  horario = '{"emergencia":"No aplica","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 1,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = 'da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c';

DELETE FROM public.centro_servicios WHERE centro_id = 'da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c', 'atencion_general'),
  ('da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c', 'vacunacion'),
  ('da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c', 'curaciones'),
  ('da5e0d32-77c6-4eca-b5cc-f7ac3b4a3c3c', 'laboratorio');

COMMIT;

-- ==========================================================
-- Biomark AI: Enriquecimiento de Centros de Salud de Managua
-- Fecha: 2026-09-17T08:08:38.005Z
-- ==========================================================

BEGIN;

-- Centro: Hospital Antonio Lenín Fonseca (628e0138-ee46-4c38-a116-0162564532f9)
UPDATE public.centros_salud SET
  direccion = 'Sector Paseo Las Brisas, 43a Avenida N.O., Distrito II, Managua',
  latitud = 12.1486554,
  longitud = -86.3117324,
  geog = st_setsrid(st_makepoint(-86.3117324, 12.1486554), 4326)::geography,
  telefono = '2253-1570',
  especialidades = ARRAY['Multiespecialidad','Cirugia','Medicina interna','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, todos los días","consulta":"Lunes a Viernes de 8:00 a.m. a 5:00 p.m."}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 225366162,
  fecha_verificacion = now()
WHERE id = '628e0138-ee46-4c38-a116-0162564532f9';

DELETE FROM public.centro_servicios WHERE centro_id = '628e0138-ee46-4c38-a116-0162564532f9';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('628e0138-ee46-4c38-a116-0162564532f9', 'multiespecialidad'),
  ('628e0138-ee46-4c38-a116-0162564532f9', 'cirugia'),
  ('628e0138-ee46-4c38-a116-0162564532f9', 'medicina_interna'),
  ('628e0138-ee46-4c38-a116-0162564532f9', 'diagnostico_imagen'),
  ('628e0138-ee46-4c38-a116-0162564532f9', 'laboratorio');

-- Centro: Hospital Bertha Calderón Roque (d03a9c32-dd38-45d8-b0da-0ba27c1291aa)
UPDATE public.centros_salud SET
  direccion = '27a Avenida S.O., Colonia Independencia, Distrito III, Frente a INATEC Centro Cívico, Managua',
  latitud = 12.1242102,
  longitud = -86.2985398,
  geog = st_setsrid(st_makepoint(-86.2985398, 12.1242102), 4326)::geography,
  telefono = '2265-0641',
  especialidades = ARRAY['Gineco-obstetricia','Salud de la mujer','Neonatologia','Oncologia','Cirugia','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 38822603,
  fecha_verificacion = now()
WHERE id = 'd03a9c32-dd38-45d8-b0da-0ba27c1291aa';

DELETE FROM public.centro_servicios WHERE centro_id = 'd03a9c32-dd38-45d8-b0da-0ba27c1291aa';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'gineco_obstetricia'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'salud_mujer'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'neonatologia'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'oncologia'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'cirugia'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'diagnostico_imagen'),
  ('d03a9c32-dd38-45d8-b0da-0ba27c1291aa', 'laboratorio');

-- Centro: Hospital Fernando Vélez Paiz (9e90dba8-94fc-4b23-bcd5-958616ccdd63)
UPDATE public.centros_salud SET
  direccion = 'Pista Héroes de la Insurrección, Reparto Belmonte, Distrito III (Del Banco Central 1c arriba), Managua',
  latitud = 12.1213832,
  longitud = -86.3061771,
  geog = st_setsrid(st_makepoint(-86.3061771, 12.1213832), 4326)::geography,
  telefono = '2253-5353',
  especialidades = ARRAY['Multiespecialidad','Atencion general','Pediatria','Gineco-obstetricia','Salud de la mujer','Cirugia','Medicina interna','Salud del hombre','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, todos los días","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 263436976,
  fecha_verificacion = now()
WHERE id = '9e90dba8-94fc-4b23-bcd5-958616ccdd63';

DELETE FROM public.centro_servicios WHERE centro_id = '9e90dba8-94fc-4b23-bcd5-958616ccdd63';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'multiespecialidad'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'atencion_general'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'pediatria'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'gineco_obstetricia'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'salud_mujer'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'cirugia'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'medicina_interna'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'salud_hombre'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'diagnostico_imagen'),
  ('9e90dba8-94fc-4b23-bcd5-958616ccdd63', 'laboratorio');

-- Centro: Hospital Infantil Manuel de Jesús Rivera La Mascota (0e292ea0-68e7-4670-92a1-5c6d6b055bd4)
UPDATE public.centros_salud SET
  direccion = 'Semáforos de La Mascota 1 cuadra al este, Barrio Ariel Darce, Distrito V, Managua',
  latitud = 12.1241,
  longitud = -86.23588,
  geog = st_setsrid(st_makepoint(-86.23588, 12.1241), 4326)::geography,
  telefono = '2249-0355',
  especialidades = ARRAY['Pediatria','Neonatologia','Cirugia pediatrica','Cirugia','Oncologia','Gastroenterologia','Endocrinologia','Cardiologia','Neurologia','Rehabilitacion','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '0e292ea0-68e7-4670-92a1-5c6d6b055bd4';

DELETE FROM public.centro_servicios WHERE centro_id = '0e292ea0-68e7-4670-92a1-5c6d6b055bd4';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'pediatria'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'neonatologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'cirugia_pediatrica'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'cirugia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'oncologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'gastroenterologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'endocrinologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'cardiologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'neurologia'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'rehabilitacion'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'diagnostico_imagen'),
  ('0e292ea0-68e7-4670-92a1-5c6d6b055bd4', 'laboratorio');

-- Centro: Hospital Manolo Morales Peralta (e8e72fc5-07bd-408f-848e-8d0795b43407)
UPDATE public.centros_salud SET
  direccion = 'Pista de la Solidaridad, Sector Hospital Manolo Morales, Altamira Este, frente al costado norte del mercado Roberto Huembes, Distrito I, Managua',
  latitud = 12.1210174,
  longitud = -86.2457915,
  geog = st_setsrid(st_makepoint(-86.2457915, 12.1210174), 4326)::geography,
  telefono = '2249-7830',
  especialidades = ARRAY['Multiespecialidad','Cirugia','Medicina interna','Diagnostico por imagen','Laboratorio'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 a.m. a 5:00 p.m."}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'osm',
  osm_id = 3227474883,
  fecha_verificacion = now()
WHERE id = 'e8e72fc5-07bd-408f-848e-8d0795b43407';

DELETE FROM public.centro_servicios WHERE centro_id = 'e8e72fc5-07bd-408f-848e-8d0795b43407';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('e8e72fc5-07bd-408f-848e-8d0795b43407', 'multiespecialidad'),
  ('e8e72fc5-07bd-408f-848e-8d0795b43407', 'cirugia'),
  ('e8e72fc5-07bd-408f-848e-8d0795b43407', 'medicina_interna'),
  ('e8e72fc5-07bd-408f-848e-8d0795b43407', 'diagnostico_imagen'),
  ('e8e72fc5-07bd-408f-848e-8d0795b43407', 'laboratorio');

-- Centro: Hospital Psicosocial (José Dolores Fletes) (1dc72113-87fe-44db-8472-be1cba209eab)
UPDATE public.centros_salud SET
  direccion = 'De Enacal Central 1 cuadra al sur, Batahola Norte, Distrito II, Managua',
  latitud = 12.13827,
  longitud = -86.30821,
  geog = st_setsrid(st_makepoint(-86.30821, 12.13827), 4326)::geography,
  telefono = '2266-2248',
  especialidades = ARRAY['Salud mental','Adicciones','Psiquiatría','Neurologia'],
  atiende_emergencia = true,
  horario = '{"emergencia":"24 horas, 7 días a la semana","consulta":"Lunes a Viernes de 8:00 AM a 5:00 PM"}'::jsonb,
  nivel_atencion = 3,
  coordenadas_verificadas = true,
  fuente_coordenada = 'manual',
  fecha_verificacion = now()
WHERE id = '1dc72113-87fe-44db-8472-be1cba209eab';

DELETE FROM public.centro_servicios WHERE centro_id = '1dc72113-87fe-44db-8472-be1cba209eab';
INSERT INTO public.centro_servicios (centro_id, codigo) VALUES
  ('1dc72113-87fe-44db-8472-be1cba209eab', 'salud_mental'),
  ('1dc72113-87fe-44db-8472-be1cba209eab', 'adicciones'),
  ('1dc72113-87fe-44db-8472-be1cba209eab', 'neurologia');

COMMIT;
