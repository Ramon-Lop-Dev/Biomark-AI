-- Biomark AI GIS: contrato espacial del mapa y capas relacionadas.
-- Ejecutar despues de rebuild_gis_02_finalize.sql.

begin;

alter table public.centros_salud
  add column if not exists nombre_normalizado text;

update public.centros_salud
set nombre_normalizado = lower(unaccent(nombre))
where nombre_normalizado is null;

create table if not exists public.centro_horarios (
  id uuid primary key default uuid_generate_v4(),
  centro_id uuid not null references public.centros_salud(id) on delete cascade,
  dia_semana smallint not null check (dia_semana between 0 and 6),
  hora_apertura time,
  hora_cierre time,
  cerrado boolean not null default false,
  constraint centro_horarios_horas_check check (
    cerrado or (hora_apertura is not null and hora_cierre is not null)
  ),
  unique (centro_id, dia_semana, hora_apertura, hora_cierre)
);

create table if not exists public.centro_fuentes (
  id uuid primary key default uuid_generate_v4(),
  centro_id uuid not null references public.centros_salud(id) on delete cascade,
  fuente text not null check (fuente in ('manual', 'osm', 'gps', 'aproximada')),
  referencia text,
  confianza numeric check (confianza is null or (confianza >= 0 and confianza <= 1)),
  verificado_por uuid references public.usuarios(id),
  fecha_verificacion timestamptz not null default now()
);

alter table public.eventos_comunitarios
  add column if not exists geog geography(Point, 4326),
  add column if not exists activo boolean not null default true,
  add column if not exists fecha_fin timestamptz;

alter table public.zonas_riesgo
  add column if not exists geog geography(Point, 4326),
  add column if not exists activo boolean not null default true;

alter table public.reportes_comunitarios
  add column if not exists geog geography(Point, 4326),
  add column if not exists ubicacion_aproximada boolean not null default true;

update public.eventos_comunitarios
set geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
where geog is null and latitud is not null and longitud is not null;

update public.zonas_riesgo
set geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
where geog is null;

update public.reportes_comunitarios
set geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
where geog is null;

create index if not exists idx_eventos_comunitarios_geog
  on public.eventos_comunitarios using gist (geog);
create index if not exists idx_eventos_comunitarios_activo_fecha
  on public.eventos_comunitarios (activo, fecha_evento);
create index if not exists idx_zonas_riesgo_geog
  on public.zonas_riesgo using gist (geog);
create index if not exists idx_zonas_riesgo_activo
  on public.zonas_riesgo (activo);
create index if not exists idx_reportes_comunitarios_geog
  on public.reportes_comunitarios using gist (geog);
create index if not exists idx_centro_horarios_centro_dia
  on public.centro_horarios (centro_id, dia_semana);
create index if not exists idx_centro_fuentes_centro_fecha
  on public.centro_fuentes (centro_id, fecha_verificacion desc);

create or replace function public.centros_en_bbox(
  p_min_lon float8,
  p_min_lat float8,
  p_max_lon float8,
  p_max_lat float8,
  p_nivel_min smallint default 1,
  p_zoom numeric default 15
)
returns table (
  id uuid,
  nombre text,
  lat numeric,
  lon numeric,
  nivel smallint,
  ubicacion_aproximada boolean
)
language sql stable
as $$
  select
    c.id,
    c.nombre,
    c.latitud,
    c.longitud,
    c.nivel_atencion,
    (c.fuente_coordenada = 'aproximada') as ubicacion_aproximada
  from public.centros_salud c
  where c.activo
    and c.geog is not null
    and c.nivel_atencion >= greatest(
      p_nivel_min,
      case when p_zoom < 13 then 3 when p_zoom < 14.5 then 2 else 1 end
    )
    and c.geog && st_makeenvelope(p_min_lon, p_min_lat, p_max_lon, p_max_lat, 4326)::geography
  order by c.nivel_atencion desc, c.nombre;
$$;

create or replace function public.eventos_en_bbox(
  p_min_lon float8,
  p_min_lat float8,
  p_max_lon float8,
  p_max_lat float8
)
returns table (
  id uuid,
  titulo text,
  descripcion text,
  fecha_evento timestamptz,
  fecha_fin timestamptz,
  ubicacion text,
  lat numeric,
  lon numeric
)
language sql stable
as $$
  select e.id, e.titulo, e.descripcion, e.fecha_evento, e.fecha_fin,
         e.ubicacion, e.latitud, e.longitud
  from public.eventos_comunitarios e
  where e.activo
    and e.geog is not null
    and e.geog && st_makeenvelope(p_min_lon, p_min_lat, p_max_lon, p_max_lat, 4326)::geography
    and coalesce(e.fecha_fin, e.fecha_evento) >= now();
$$;

alter table public.centros_salud enable row level security;
alter table public.centro_horarios enable row level security;
alter table public.eventos_comunitarios enable row level security;
alter table public.zonas_riesgo enable row level security;

-- El backend usa service_role; estas policies permiten tambien lectura autenticada
-- directa sin exponer escritura a los clientes.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'centros_salud' and policyname = 'gis_centros_select_authenticated') then
    create policy gis_centros_select_authenticated on public.centros_salud for select to authenticated using (activo);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'centro_horarios' and policyname = 'gis_horarios_select_authenticated') then
    create policy gis_horarios_select_authenticated on public.centro_horarios for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'eventos_comunitarios' and policyname = 'gis_eventos_select_authenticated') then
    create policy gis_eventos_select_authenticated on public.eventos_comunitarios for select to authenticated using (activo);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'zonas_riesgo' and policyname = 'gis_zonas_select_authenticated') then
    create policy gis_zonas_select_authenticated on public.zonas_riesgo for select to authenticated using (activo);
  end if;
end;
$$;

grant execute on function public.centros_cercanos(float8, float8, text, smallint, smallint, int, int) to authenticated, service_role;
grant execute on function public.centros_en_bbox(float8, float8, float8, float8, smallint, numeric) to authenticated, service_role;
grant execute on function public.eventos_en_bbox(float8, float8, float8, float8) to authenticated, service_role;

commit;
