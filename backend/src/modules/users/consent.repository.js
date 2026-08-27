// Persiste consentimientos asociados al usuario autenticado.
const supabase = require('../../config/supabase');

const listar = (usuarioId) =>
  supabase.from('consentimientos').select('id, tipo_consentimiento, otorgado').eq('usuario_id', usuarioId);

const buscar = (usuarioId, tipo) =>
  supabase.from('consentimientos').select('id, tipo_consentimiento, otorgado').eq('usuario_id', usuarioId).eq('tipo_consentimiento', tipo).maybeSingle();

const actualizar = (id, otorgado) =>
  supabase.from('consentimientos').update({ otorgado }).eq('id', id).select('id, tipo_consentimiento, otorgado').single();

const crear = (usuarioId, tipo, otorgado) =>
  supabase.from('consentimientos').insert({ usuario_id: usuarioId, tipo_consentimiento: tipo, otorgado }).select('id, tipo_consentimiento, otorgado').single();

module.exports = { listar, buscar, actualizar, crear };