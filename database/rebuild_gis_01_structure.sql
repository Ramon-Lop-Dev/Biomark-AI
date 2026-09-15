-- Biomark AI GIS: reconstruccion de estructura.
-- Ejecutar en Supabase antes de database/centros_salud_rows.sql.
-- Este script conserva un respaldo y falla si existen FK externas sobre centros_salud.

begin;

create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists unaccent;

create table if not exists public.centros_salud_backup_20260914 as
select * from public.centros_salud;

drop table if exists public.centro_servicios;
drop table if exists public.catalogo_servicios;
drop table public.centros_salud;

create table public.centros_salud (
  id uuid primary key default uuid_generate_v4(),
  nombre text not null,
  tipo tipo_centro_salud not null,
  latitud numeric not null,
  longitud numeric not null,
  direccion text,
  telefono text,
  fecha_creacion timestamptz not null default now(),
  tipo_unidad text,
  silais text,
  distrito text,
  municipio text,
  localidad text,
  zona text,
  especialidades text[],
  coordenadas_verificadas boolean not null default false,
  geog geography(Point, 4326),
  nivel_atencion smallint,
  atiende_emergencia boolean not null default false,
  horario jsonb not null default '{}'::jsonb,
  osm_id bigint,
  activo boolean not null default true,
  fuente_coordenada text not null default 'aproximada',
  fecha_verificacion timestamptz,
  constraint centros_salud_nivel_check check (nivel_atencion is null or nivel_atencion between 1 and 3),
  constraint centros_salud_fuente_check check (fuente_coordenada in ('manual', 'osm', 'gps', 'aproximada'))
);

create table public.catalogo_servicios (
  codigo text primary key,
  etiqueta text not null,
  sinonimos text[] not null default '{}'
);

create table public.centro_servicios (
  centro_id uuid not null references public.centros_salud(id) on delete cascade,
  codigo text not null references public.catalogo_servicios(codigo),
  edad_min smallint,
  edad_max smallint,
  primary key (centro_id, codigo),
  constraint centro_servicios_edad_check check (
    edad_min is null or edad_max is null or edad_min <= edad_max
  )
);

insert into public.catalogo_servicios (codigo, etiqueta, sinonimos) values
  ('atencion_general', 'Atencion general', array['atencion general', 'atencion general basica', 'medicina general']),
  ('pediatria', 'Pediatria', array['pediatrica', 'infantil', 'ninos', 'niños']),
  ('neonatologia', 'Neonatologia', array['recien nacido', 'neonatal']),
  ('cirugia', 'Cirugia', array['quirurgica']),
  ('cirugia_pediatrica', 'Cirugia pediatrica', array['cirugia infantil']),
  ('gineco_obstetricia', 'Gineco-obstetricia', array['ginecologia', 'obstetricia']),
  ('salud_mujer', 'Salud de la mujer', array['maternidad']),
  ('cardiologia', 'Cardiologia', array['cardiologia pediatrica', 'cardiocirugia', 'hemodinamia']),
  ('dermatologia', 'Dermatologia', array['piel']),
  ('oftalmologia', 'Oftalmologia', array['cirugia ocular']),
  ('audiologia', 'Audiologia', array['audicion']),
  ('logopedia', 'Logopedia', array['habla']),
  ('salud_mental', 'Salud mental', array['psiquiatria']),
  ('adicciones', 'Adicciones', array['adiccion']),
  ('endocrinologia', 'Endocrinologia', array['diabetes', 'tiroides']),
  ('oncologia', 'Oncologia', array['quimioterapia', 'radioterapia']),
  ('cuidados_paliativos', 'Cuidados paliativos', array['paliativos']),
  ('medicina_interna', 'Medicina interna', array['medicina de adultos']),
  ('salud_hombre', 'Salud del hombre', array['urologia masculina']),
  ('multiespecialidad', 'Multiespecialidad', array['atencion especializada']),
  ('gastroenterologia', 'Gastroenterologia', array['endoscopia']),
  ('urologia', 'Urologia', array['urinaria']),
  ('neurologia', 'Neurologia', array['migraña', 'convulsiones']),
  ('rehabilitacion', 'Rehabilitacion', array['rehabilitacion fisica', 'medicina fisica', 'fisioterapia']),
  ('gerontologia', 'Gerontologia', array['adulto mayor']),
  ('vacunacion', 'Vacunacion', array['vacunas']),
  ('curaciones', 'Curaciones', array['curacion']),
  ('diagnostico_imagen', 'Diagnostico por imagen', array['alta tecnologia', 'radiologia', 'tomografia', 'resonancia magnetica']),
  ('laboratorio', 'Laboratorio', array['citologia', 'patologia'])
on conflict (codigo) do update set etiqueta = excluded.etiqueta, sinonimos = excluded.sinonimos;

commit;

-- Carga los datos completos despues de este archivo:
-- database/centros_salud_rows.sql
