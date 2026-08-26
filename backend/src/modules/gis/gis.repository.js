const supabase = require('../../config/supabase');

const listarCentrosSalud = () =>
  supabase
    .from('centros_salud')
    .select('*')
    .order('nombre', { ascending: true });

module.exports = { listarCentrosSalud };
