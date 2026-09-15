-- Biomark AI GIS: finalizacion despues de cargar centros_salud_rows.sql.
-- Ejecutar en Supabase despues de database/rebuild_gis_01_structure.sql
-- y despues del export completo de centros_salud.

begin;

update public.centros_salud
set nivel_atencion = case
  when lower(coalesce(tipo_unidad, '')) = 'puesto de salud' then 1
  when lower(coalesce(tipo_unidad, '')) in ('centro de salud', 'centro especializado', 'clinica previsional') then 2
  when lower(coalesce(tipo_unidad, '')) in ('hospital departamental', 'hospital referencia nacional') then 3
  when tipo::text = 'PUESTO_MEDICO' then 1
  when tipo::text = 'HOSPITAL' then 3
  else 2
end,
fuente_coordenada = case
  when coordenadas_verificadas then 'manual'
  else 'aproximada'
end
where nivel_atencion is null;

update public.centros_salud
set geog = st_setsrid(st_makepoint(longitud::float8, latitud::float8), 4326)::geography
where geog is null;

insert into public.centro_servicios (centro_id, codigo)
select distinct c.id, s.codigo
from public.centros_salud c
cross join lateral unnest(coalesce(c.especialidades, '{}'::text[])) raw(servicio)
join lateral (
  select cs.codigo
  from public.catalogo_servicios cs
  where lower(unaccent(raw.servicio)) = any (
    select lower(unaccent(value))
    from unnest(array_append(cs.sinonimos, cs.etiqueta)) value
  )
  order by case when lower(unaccent(raw.servicio)) = lower(unaccent(cs.etiqueta)) then 0 else 1 end
  limit 1
) s on true
on conflict (centro_id, codigo) do nothing;

-- Reglas explicitas para los valores que requieren normalizacion semantica.
insert into public.centro_servicios (centro_id, codigo)
select distinct c.id, mapping.codigo
from public.centros_salud c
cross join lateral unnest(coalesce(c.especialidades, '{}'::text[])) raw(servicio)
join (values
  ('atencion general basica', 'atencion_general'),
  ('atencion general', 'atencion_general'),
  ('diabetes', 'endocrinologia'),
  ('alta tecnologia', 'diagnostico_imagen'),
  ('multiespecialidad', 'atencion_general')
) mapping(nombre, codigo)
  on lower(unaccent(raw.servicio)) = mapping.nombre
on conflict (centro_id, codigo) do nothing;

create index if not exists idx_centros_salud_geog
  on public.centros_salud using gist (geog);
create index if not exists idx_centros_salud_nombre_trgm
  on public.centros_salud using gin (nombre gin_trgm_ops);
create index if not exists idx_centros_salud_nivel_activo
  on public.centros_salud (nivel_atencion, activo);
create index if not exists idx_centros_salud_municipio
  on public.centros_salud (municipio);
create index if not exists idx_centro_servicios_codigo
  on public.centro_servicios (codigo);

create or replace function public.centros_cercanos(
  p_lat float8,
  p_lon float8,
  p_servicio text default null,
  p_edad smallint default null,
  p_nivel_min smallint default 1,
  p_radio_m int default 5000,
  p_limite int default 10
)
returns table (
  id uuid,
  nombre text,
  nivel_atencion smallint,
  latitud numeric,
  longitud numeric,
  direccion text,
  telefono text,
  fuente_coordenada text,
  metros int
)
language sql stable
as $$
  select
    c.id,
    c.nombre,
    c.nivel_atencion,
    c.latitud,
    c.longitud,
    c.direccion,
    c.telefono,
    c.fuente_coordenada,
    round(st_distance(c.geog, st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography))::int
  from public.centros_salud c
  where c.activo
    and c.geog is not null
    and c.nivel_atencion >= p_nivel_min
    and st_dwithin(c.geog, st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography, p_radio_m)
    and (
      p_servicio is null
      or exists (
        select 1
        from public.centro_servicios cs
        where cs.centro_id = c.id
          and cs.codigo = p_servicio
          and (cs.edad_min is null or p_edad is null or p_edad >= cs.edad_min)
          and (cs.edad_max is null or p_edad is null or p_edad <= cs.edad_max)
      )
    )
  order by c.geog <-> st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography
  limit greatest(1, least(p_limite, 100));
$$;

commit;

-- Verificaciones recomendadas:
-- select count(*) from public.centros_salud;
-- select count(*) from public.centros_salud where geog is null;
-- select nombre, count(*) from public.centros_salud group by nombre having count(*) > 1;
-- select count(*) from public.centro_servicios;
