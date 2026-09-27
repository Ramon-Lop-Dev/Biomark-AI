const { z } = require('zod');

const passwordSchema = z
  .string()
  .min(8, 'La contraseña debe tener al menos 8 caracteres')
  .regex(/[A-Za-z]/, 'La contraseña debe incluir al menos una letra')
  .regex(/[0-9]/, 'La contraseña debe incluir al menos un número');

const createHealthWorkerInvitationSchema = z.object({
  contacto: z.string().trim().min(3, 'El contacto (correo o teléfono) es obligatorio'),
  centro_salud_id: z.string().uuid('El ID del centro de salud debe ser un UUID válido'),
  expira_dias: z.number().int().min(1).max(30).optional().default(7)
});

const createPromoterInvitationSchema = z.object({
  contacto: z.string().trim().min(3, 'El contacto (correo o teléfono) es obligatorio'),
  centro_salud_id: z.string().uuid('El ID del centro de salud debe ser un UUID válido').optional(),
  expira_dias: z.number().int().min(1).max(30).optional().default(7)
});

const acceptInvitationSchema = z.object({
  token: z.string().trim().min(6, 'Token de invitación inválido'),
  email: z.string().trim().toLowerCase().email('Correo inválido'),
  password: passwordSchema,
  full_name: z.string().trim().min(2, 'El nombre completo es obligatorio')
});

const updatePromoterStatusSchema = z.object({
  estado: z.enum(['ACTIVO', 'SUSPENDIDO'])
});

module.exports = {
  createHealthWorkerInvitationSchema,
  createPromoterInvitationSchema,
  acceptInvitationSchema,
  updatePromoterStatusSchema
};
