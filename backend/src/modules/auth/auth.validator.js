const { z } = require('zod');

const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email('Correo inválido'),
  password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres'),
  full_name: z.string().trim().min(1, 'El nombre completo es obligatorio')
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Correo inválido'),
  password: z.string().min(1, 'La contraseña es obligatoria')
});

// Flujo pensado para apps móviles (Flutter): el cliente usa el SDK nativo
// de Google (google_sign_in) para obtener un ID Token y lo manda aquí.
// Supabase se encarga de verificar ese token directamente contra Google
// (requiere tener el proveedor "Google" habilitado en el proyecto de
// Supabase Auth, con el Client ID de la app configurado ahí).
const googleAuthSchema = z.object({
  id_token: z.string().min(1, 'id_token es obligatorio'),
  access_token: z.string().optional(),
  // Solo se usa como fallback si Google no provee un nombre en el id_token
  // y es la primera vez que este usuario inicia sesión (aprovisionamiento).
  full_name: z.string().trim().optional()
});

module.exports = { registerSchema, loginSchema, googleAuthSchema };
