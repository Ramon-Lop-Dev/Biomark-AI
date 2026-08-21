const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
    console.warn("[Advertencia] Faltan las variables SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env");
}

// Cliente dedicado exclusivamente a signUp / signInWithPassword.
// Usa la anon key a propósito: nunca debe usarse para leer/escribir tablas,
// solo para operaciones de autenticación de usuarios finales.
const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey);

module.exports = supabaseAuth;