-- Biomark AI GIS: validacion posterior a la reconstruccion.
-- Ejecutar en Supabase SQL Editor y guardar los resultados.

-- 1. Conteos principales.
select 'centros_salud' as objeto, count(*) as total
from public.centros_salud
union all
select 'centros_con_geog', count(*)
from public.centros_salud
where geog is not null
union all
select 'centros_activos', count(*)
from public.centros_salud
where activo
union all
select 'centro_servicios', count(*)
from public.centro_servicios
union all
select 'catalogo_servicios', count(*)
from public.catalogo_servicios;

-- 2. Centros sin datos espaciales o de clasificación.
select id, nombre, latitud, longitud, tipo_unidad, nivel_atencion, fuente_coordenada
from public.centros_salud
where geog is null
   or nivel_atencion is null
   or latitud not between -90 and 90
   or longitud not between -180 and 180
order by nombre;

-- 3. Duplicados por nombre.
select lower(trim(nombre)) as nombre_normalizado, count(*) as total,
       array_agg(id order by nombre) as ids
from public.centros_salud
where activo
 group by lower(trim(nombre))
having count(*) > 1
order by total desc, nombre_normalizado;

-- 4. Coordenadas compartidas por varios centros.
select latitud, longitud, count(*) as total,
       array_agg(nombre order by nombre) as centros
from public.centros_salud
where activo
group by latitud, longitud
having count(*) > 1
order by total desc;

-- 5. Valores antiguos que todavía no fueron relacionados a un servicio.
select distinct raw.servicio as especialidad_sin_mapeo
from public.centros_salud c
cross join lateral unnest(coalesce(c.especialidades, '{}'::text[])) raw(servicio)
where not exists (
  select 1
  from public.centro_servicios cs
  join public.catalogo_servicios cat on cat.codigo = cs.codigo
  where cs.centro_id = c.id
    and (
      lower(unaccent(raw.servicio)) = lower(unaccent(cat.etiqueta))
      or lower(unaccent(raw.servicio)) = any (
        select lower(unaccent(sinonimo))
        from unnest(cat.sinonimos) sinonimo
      )
    )
)
order by especialidad_sin_mapeo;

-- 6. Extensiones GIS requeridas.
select extname
from pg_extension
where extname in ('postgis', 'pg_trgm', 'unaccent')
order by extname;

-- 7. Funciones requeridas.
select n.nspname as esquema, p.proname as funcion,
       pg_get_function_identity_arguments(p.oid) as argumentos
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('centros_cercanos', 'centros_en_bbox', 'eventos_en_bbox')
order by p.proname;

-- 8. RLS y policies GIS.
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('centros_salud', 'centro_horarios', 'eventos_comunitarios', 'zonas_riesgo')
order by tablename;

select schemaname, tablename, policyname, roles, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('centros_salud', 'centro_horarios', 'eventos_comunitarios', 'zonas_riesgo')
order by tablename, policyname;

-- 9. Prueba funcional de cercanía en Managua.
select *
from public.centros_cercanos(
  12.1364::float8,
  -86.2514::float8,
  null::text,
  null::smallint,
  1::smallint,
  15000::int,
  10::int
);

-- 10. Prueba funcional de viewport.
select *
from public.centros_en_bbox(
  -86.35::float8,
  12.08::float8,
  -86.20::float8,
  12.20::float8,
  1::smallint,
  15::numeric
);
