const supabase = require('../../config/supabase');       // service_role: solo para tablas
const supabaseAuth = require('../../config/supabaseAuth'); // anon: solo para signUp/signIn

const registerUser = async (email, password, fullName) => {
    // 1. Supabase Auth maneja la creación segura del usuario y el hashing de la contraseña.
    // Usamos supabaseAuth (anon key) para esto — así el cliente "supabase" (service_role)
    // nunca se ve afectado por el cambio de sesión que provoca signUp().
    const { data, error } = await supabaseAuth.auth.signUp({
        email,
        password,
        options: {
            data: { full_name: fullName }
        }
    });

    if (error) {
        throw new Error(error.message);
    }

    const authId = data.user.id;

    // 2. Crear la fila correspondiente en public.usuarios (vinculada por auth_id).
    // Este insert usa "supabase" (service_role), que NUNCA cambia de identidad
    // porque nunca se usa para signUp/signIn.
    const { data: usuario, error: usuarioError } = await supabase
        .from('usuarios')
        .insert({ auth_id: authId, correo: email })
        .select()
        .single();

    if (usuarioError) {
        throw new Error(`No se pudo crear el registro en 'usuarios': ${usuarioError.message}`);
    }

    // 3. Crear la fila correspondiente en public.perfiles
    const { error: perfilError } = await supabase
        .from('perfiles')
        .insert({ usuario_id: usuario.id, nombre_completo: fullName });

    if (perfilError) {
        throw new Error(`No se pudo crear el registro en 'perfiles': ${perfilError.message}`);
    }

    return {
        user_id: usuario.id,
        token: data.session?.access_token || null
    };
};

const loginUser = async (email, password) => {
    // También usamos supabaseAuth (anon key) para login, por consistencia
    // y para no tocar jamás la identidad del cliente service_role.
    const { data, error } = await supabaseAuth.auth.signInWithPassword({
        email,
        password
    });

    if (error) {
        console.error("Error real de Supabase en login:", error);
        throw new Error("Credenciales inválidas");
    }

    return {
        token: data.session.access_token,
        expires_in: data.session.expires_in || 3600
    };
};

module.exports = { registerUser, loginUser };