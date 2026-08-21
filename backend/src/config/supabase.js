const { createClient } = require('@supabase/supabase-js');

// Según la documentación, el backend usa la Service Role Key para operaciones administrativas
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; 

if (!supabaseUrl || !supabaseKey) {
    console.warn("[Advertencia] Faltan las variables SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en el archivo .env");
}

// Inicializar el cliente de Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

module.exports = supabase;