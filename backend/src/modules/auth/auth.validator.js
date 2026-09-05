// Define las reglas de entrada para operaciones de autenticación.
const { z } = require('zod');

// Política de contraseña (antes solo pedía 6 caracteres, sin más
// requisitos). Se comparte entre registro y reset de contraseña para no
// tener dos reglas distintas de "qué es una contraseña válida".
const passwordSchema = z
  .string()
  .min(8, 'La contraseña debe tener al menos 8 caracteres')
  .regex(/[A-Za-z]/, 'La contraseña debe incluir al menos una letra')
  .regex(/[0-9]/, 'La contraseña debe incluir al menos un número');

const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email('Correo inválido'),
  password: passwordSchema,
  full_name: z.string().trim().min(1, 'El nombre completo es obligatorio'),
  tipo_cuenta: z.enum(['PERSONAL', 'PROMOTOR']).default('PERSONAL')
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

// POST /auth/refresh — el cliente manda el refresh_token que recibió al
// hacer login, para obtener un access_token nuevo sin pedir password de
// nuevo.
const refreshSchema = z.object({
  refresh_token: z.string().min(1, 'refresh_token es obligatorio')
});

const forgotPasswordSchema = z.object({
  email: z.string().trim().toLowerCase().email('Correo inválido'),
  redirect_to: z.enum(['biomarkai://reset-password', 'https://biomark-api.duckdns.org/reset-password'])
});

// POST /auth/reset-password — el cliente llega aquí con el access_token
// del enlace de recuperación que Supabase le mandó por correo (Flutter lo
// captura vía deep link) y la nueva contraseña.
const resetPasswordSchema = z.object({
  access_token: z.string().min(1, 'access_token es obligatorio'),
  new_password: passwordSchema
});

module.exports = {
  registerSchema,
  loginSchema,
  googleAuthSchema,
  refreshSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  passwordSchema
};
