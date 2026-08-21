const supabase = require('../../config/supabase');

const registerUser = async (email, password, fullName) => {
    // 1. Supabase Auth maneja la creación segura del usuario y el hashing de la contraseña
    const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            data: { full_name: fullName } // Metadatos que luego pueden alimentar la tabla 'perfiles' vía Triggers de Supabase
        }
    });

    if (error) {
        throw new Error(error.message);
    }
    
    // Devolvemos lo que exige la documentación para una respuesta 201
    return {
        user_id: data.user.id,
        token: data.session?.access_token || null
    };
};

const loginUser = async (email, password) => {
    // Autenticar al usuario ya existente
    const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
    });

    if (error) {
        
       
        console.error("Error real de Supabase en login:", error); 
        throw new Error("Credenciales inválidas");
    }

    // Devolvemos lo que exige la documentación para una respuesta 200
    return {
        token: data.session.access_token,
        expires_in: data.session.expires_in || 3600
    };
};

module.exports = { registerUser, loginUser };