// Registra y desactiva tokens push en Supabase.
const supabase = require('../../config/supabase');

const registrar = (usuarioId, { fcm_token, plataforma }) =>
  supabase
    .from('dispositivos_push')
    .upsert({ usuario_id: usuarioId, fcm_token, plataforma, activo: true }, { onConflict: 'fcm_token' })
    .select('id, fcm_token, plataforma, activo')
    .single();

const eliminar = (usuarioId, token) =>
  supabase.from('dispositivos_push').update({ activo: false }).eq('usuario_id', usuarioId).eq('fcm_token', token);

module.exports = { registrar, eliminar };