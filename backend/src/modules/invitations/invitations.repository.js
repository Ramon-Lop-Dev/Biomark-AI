const supabase = require('../../config/supabase');

const crearInvitacion = ({ token, contacto, rol_destino, centro_salud_id, creado_por, expira_en }) =>
  supabase
    .from('invitaciones')
    .insert([{
      token,
      contacto,
      rol_destino,
      centro_salud_id,
      creado_por,
      expira_en
    }])
    .select('*, centros_salud(nombre, municipio, distrito)')
    .single();

const buscarInvitacionPorToken = (token) =>
  supabase
    .from('invitaciones')
    .select('*, centros_salud(nombre, municipio, distrito, tipo)')
    .eq('token', token)
    .maybeSingle();

const marcarInvitacionUsada = (id, usuarioResultanteId) =>
  supabase
    .from('invitaciones')
    .update({
      usado_en: new Date().toISOString(),
      usuario_resultante_id: usuarioResultanteId
    })
    .eq('id', id)
    .select()
    .single();

const listarPromotoresPorCentro = (centroSaludId) => {
  let query = supabase
    .from('usuarios')
    .select('id, correo, rol, activo, estado_cuenta, fecha_creacion, invitado_por, centro_salud_id, centros_salud(nombre), perfiles(nombre_completo, telefono)')
    .in('rol', ['PROMOTOR', 'LIDER_COMUNITARIO'])
    .order('fecha_creacion', { ascending: false });

  if (centroSaludId) {
    query = query.eq('centro_salud_id', centroSaludId);
  }
  return query;
};

const listarInvitacionesPorCentro = (centroSaludId) => {
  let query = supabase
    .from('invitaciones')
    .select('id, token, contacto, rol_destino, expira_en, usado_en, fecha_creacion, creado_por, centro_salud_id, centros_salud(nombre)')
    .order('fecha_creacion', { ascending: false });

  if (centroSaludId) {
    query = query.eq('centro_salud_id', centroSaludId);
  }
  return query;
};

const actualizarEstadoCuentaPromotor = (usuarioId, centroSaludId, estado) => {
  let query = supabase
    .from('usuarios')
    .update({
      estado_cuenta: estado,
      activo: estado === 'ACTIVO',
      fecha_actualizacion: new Date().toISOString()
    })
    .eq('id', usuarioId);

  if (centroSaludId) {
    query = query.eq('centro_salud_id', centroSaludId);
  }

  return query
    .select('id, correo, rol, estado_cuenta, activo')
    .maybeSingle();
};

const asignarRolYCentro = (usuarioId, rol, centroSaludId, invitadoPor) =>
  supabase
    .from('usuarios')
    .update({
      rol,
      centro_salud_id: centroSaludId,
      invitado_por: invitadoPor,
      estado_cuenta: 'ACTIVO',
      fecha_actualizacion: new Date().toISOString()
    })
    .eq('id', usuarioId)
    .select('id, correo, rol, centro_salud_id, estado_cuenta')
    .single();

module.exports = {
  crearInvitacion,
  buscarInvitacionPorToken,
  marcarInvitacionUsada,
  listarPromotoresPorCentro,
  listarInvitacionesPorCentro,
  actualizarEstadoCuentaPromotor,
  asignarRolYCentro
};
