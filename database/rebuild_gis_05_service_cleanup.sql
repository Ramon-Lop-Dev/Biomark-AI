-- Biomark AI GIS: completa el mapeo de servicios heredados.
-- Ejecutar sobre una base ya reconstruida.

begin;

insert into public.catalogo_servicios (codigo, etiqueta, sinonimos) values
  ('cuidados_paliativos', 'Cuidados paliativos', array['paliativos']),
  ('medicina_interna', 'Medicina interna', array['medicina de adultos']),
  ('salud_hombre', 'Salud del hombre', array['urologia masculina']),
  ('multiespecialidad', 'Multiespecialidad', array['atencion especializada'])
on conflict (codigo) do update
set etiqueta = excluded.etiqueta,
    sinonimos = excluded.sinonimos;

insert into public.centro_servicios (centro_id, codigo)
select distinct c.id,
  case lower(unaccent(raw.servicio))
    when 'cuidados paliativos' then 'cuidados_paliativos'
    when 'medicina interna' then 'medicina_interna'
    when 'salud del hombre' then 'salud_hombre'
    when 'multiespecialidad' then 'multiespecialidad'
  end
from public.centros_salud c
cross join lateral unnest(coalesce(c.especialidades, '{}'::text[])) raw(servicio)
where c.activo
  and lower(unaccent(raw.servicio)) in (
    'cuidados paliativos',
    'medicina interna',
    'salud del hombre',
    'multiespecialidad'
  )
on conflict (centro_id, codigo) do nothing;

commit;

-- Debe devolver cero filas:
-- select distinct raw.servicio as especialidad_sin_mapeo
-- from public.centros_salud c
-- cross join lateral unnest(coalesce(c.especialidades, '{}'::text[])) raw(servicio)
-- where c.activo
-- and not exists (
--   select 1
--   from public.centro_servicios cs
--   join public.catalogo_servicios cat on cat.codigo = cs.codigo
--   where cs.centro_id = c.id
--   and (
--     lower(unaccent(raw.servicio)) = lower(unaccent(cat.etiqueta))
--     or lower(unaccent(raw.servicio)) = any (
--       select lower(unaccent(sinonimo))
--       from unnest(cat.sinonimos) sinonimo
--     )
--   )
-- );
