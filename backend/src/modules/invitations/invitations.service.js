const crypto = require('crypto');
const invitationsRepo = require('./invitations.repository');
const authRepo = require('../auth/auth.repository');
const auditService = require('../audit/audit.service');
const AppError = require('../../utils/AppError');
const supabase = require('../../config/supabase');
const { publicarEvento } = require('../../config/n8nClient');

const generarCodigoInvitacion = () => {
  const randomBytes = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `BM-${randomBytes}`;
};

const inviteHealthWorker = async (adminId, { contacto = 'ENTREGA_DIRECTA', centro_salud_id, expira_dias = 7 }) => {
  const contactoEfectivo = contacto?.trim() || 'ENTREGA_DIRECTA';
  // Validar existencia del centro de salud
  const { data: centro, error: centroError } = await supabase
    .from('centros_salud')
    .select('id, nombre, municipio')
    .eq('id', centro_salud_id)
    .single();

  if (centroError || !centro) {
    throw new AppError('El centro de salud especificado no existe', 404);
  }

  const token = generarCodigoInvitacion();
  const expira_en = new Date(Date.now() + expira_dias * 24 * 60 * 60 * 1000).toISOString();

  const { data: invitacion, error } = await invitationsRepo.crearInvitacion({
    token,
    contacto: contactoEfectivo,
    rol_destino: 'TRABAJADOR_SALUD',
    centro_salud_id,
    creado_por: adminId,
    expira_en
  });

  if (error) {
    throw new AppError('No se pudo generar la invitación para el trabajador de salud', 500);
  }

  // Auditoría Sanitaria SILAIS
  await auditService.registrar({
    usuarioId: adminId,
    tipoEntidad: 'invitaciones',
    idEntidad: invitacion.id,
    accion: 'INVITACION_TRABAJADOR_CREADA',
    detalle: {
      contacto: contactoEfectivo,
      centro_salud_id,
      centro_nombre: centro.nombre,
      rol: 'TRABAJADOR_SALUD',
      descripcion: `Acreditación emitida por Administrador SILAIS para ${contactoEfectivo} en ${centro.nombre}`
    }
  });

  // Entrega automática n8n / SMS (opcional, no bloqueante)
  try {
    await publicarEvento('acreditacion_sanitaria.creada', {
      token,
      contacto: contactoEfectivo,
      rol_destino: 'TRABAJADOR_SALUD',
      centro_salud_id,
      centro_nombre: centro.nombre,
      municipio: centro.municipio,
      expira_en,
      emitido_por: adminId,
      tipo_acreditacion: 'PERSONAL_MEDICO_SILAIS',
      url_registro: `biomark://registro?codigo=${token}`
    });
  } catch (err) {
    console.error('[Invitations] No se pudo despachar evento n8n para trabajador de salud:', err.message);
  }

  return invitacion;
};

const invitePromoter = async (workerId, workerCentroSaludId, { contacto = 'ENTREGA_DIRECTA', centro_salud_id, expira_dias = 7 }) => {
  const contactoEfectivo = contacto?.trim() || 'ENTREGA_DIRECTA';
  const centroId = workerCentroSaludId || centro_salud_id;
  if (!centroId) {
    throw new AppError('El promotor debe estar adscrito a un centro de salud', 400);
  }

  const { data: centro } = await supabase
    .from('centros_salud')
    .select('id, nombre')
    .eq('id', centroId)
    .maybeSingle();

  if (!centro) {
    throw new AppError('El centro de salud especificado no existe', 404);
  }

  const token = generarCodigoInvitacion();
  const expira_en = new Date(Date.now() + expira_dias * 24 * 60 * 60 * 1000).toISOString();

  const { data: invitacion, error } = await invitationsRepo.crearInvitacion({
    token,
    contacto: contactoEfectivo,
    rol_destino: 'PROMOTOR',
    centro_salud_id: centroId,
    creado_por: workerId,
    expira_en
  });

  if (error) {
    throw new AppError('No se pudo generar la invitación para el promotor', 500);
  }

  // Auditoría Sanitaria SILAIS
  await auditService.registrar({
    usuarioId: workerId,
    tipoEntidad: 'invitaciones',
    idEntidad: invitacion.id,
    accion: 'INVITACION_PROMOTOR_CREADA',
    detalle: {
      contacto: contactoEfectivo,
      centro_salud_id: centroId,
      centro_nombre: centro.nombre,
      rol: 'PROMOTOR',
      descripcion: `Acreditación emitida para promotor comunitario ${contactoEfectivo} en ${centro.nombre}`
    }
  });

  // Entrega automática n8n / SMS (opcional, no bloqueante)
  try {
    await publicarEvento('acreditacion_sanitaria.creada', {
      token,
      contacto: contactoEfectivo,
      rol_destino: 'PROMOTOR',
      centro_salud_id: centroId,
      centro_nombre: centro.nombre,
      expira_en,
      emitido_por: workerId,
      tipo_acreditacion: 'BRIGADISTA_COMUNITARIO_MINSA',
      url_registro: `biomark://registro?codigo=${token}`
    });
  } catch (err) {
    console.error('[Invitations] No se pudo despachar evento n8n para promotor:', err.message);
  }

  return invitacion;
};

const verifyInvitation = async (token) => {
  const { data: inv, error } = await invitationsRepo.buscarInvitacionPorToken(token.trim().toUpperCase());

  if (error || !inv) {
    throw new AppError('Código o token de invitación no encontrado', 404);
  }

  if (inv.usado_en) {
    throw new AppError('Esta invitación ya fue utilizada previamente', 410);
  }

  if (new Date(inv.expira_en) < new Date()) {
    throw new AppError('Esta invitación ha expirado. Solicita un nuevo enlace o código.', 410);
  }

  return {
    valido: true,
    token: inv.token,
    contacto: inv.contacto,
    rol_destino: inv.rol_destino,
    centro_salud: inv.centros_salud ? {
      id: inv.centro_salud_id,
      nombre: inv.centros_salud.nombre,
      municipio: inv.centros_salud.municipio,
      distrito: inv.centros_salud.distrito
    } : null,
    expira_en: inv.expira_en
  };
};

const acceptInvitation = async ({ token, email, password, full_name }) => {
  const verificacion = await verifyInvitation(token);
  const tokenLimpio = token.trim().toUpperCase();

  // 0. Seguridad de rol MINSA: Evitar suplantación de identidad
  const contactoDestino = (verificacion.contacto || '').trim().toLowerCase();
  const emailIngresado = (email || '').trim().toLowerCase();

  if (contactoDestino.includes('@') && contactoDestino !== emailIngresado) {
    throw new AppError(
      `Seguridad de rol: Este código de activación fue emitido exclusivamente para "${verificacion.contacto}". No se puede canjear con un correo diferente ("${email}").`,
      403
    );
  }

  // 1. Verificar si ya existe en Supabase Auth o crearlo
  let authUserId = null;
  let session = null;

  const { data: signUpData, error: signUpError } = await authRepo.signUpWithPassword(email, password, full_name);

  if (signUpError) {
    if (signUpError.message?.toLowerCase().includes('already registered')) {
      // Iniciar sesión para obtener el usuario
      const { data: signInData, error: signInError } = await authRepo.signInWithPassword(email, password);
      if (signInError || !signInData.user) {
        throw new AppError('Ya existe una cuenta con este correo. Las credenciales proporcionadas no coinciden.', 401);
      }
      authUserId = signInData.user.id;
      session = signInData.session;
    } else {
      throw new AppError(`Error en el registro: ${signUpError.message}`, 400);
    }
  } else {
    authUserId = signUpData.user.id;
    session = signUpData.session;
  }

  // 2. Resolver o aprovisionar el usuario de dominio
  let { data: usuario } = await authRepo.findUsuarioByAuthId(authUserId);

  if (!usuario) {
    const { data: nuevoUsuario, error: createError } = await authRepo.createUsuario(authUserId, email);
    if (createError) throw new AppError('Error al crear usuario de dominio', 500);
    usuario = nuevoUsuario;
    await authRepo.createPerfil(usuario.id, full_name);
  }

  // Si el contacto fue un teléfono, asociarlo al perfil del usuario
  if (!contactoDestino.includes('@') && contactoDestino.length >= 7 && !contactoDestino.includes('entrega')) {
    try {
      await supabase
        .from('perfiles')
        .update({ telefono: verificacion.contacto })
        .eq('usuario_id', usuario.id);
    } catch (_) {}
  }

  // 3. Asignar rol y centro de salud de forma atómica e irreversible
  const { data: inv } = await invitationsRepo.buscarInvitacionPorToken(tokenLimpio);

  const { data: usuarioActualizado, error: updateError } = await invitationsRepo.asignarRolYCentro(
    usuario.id,
    inv.rol_destino,
    inv.centro_salud_id,
    inv.creado_por
  );

  if (updateError) {
    throw new AppError('No se pudo asignar el rol y centro de salud a la cuenta', 500);
  }

  // 4. Marcar invitación como utilizada
  await invitationsRepo.marcarInvitacionUsada(inv.id, usuario.id);

  // 5. Auditoría Sanitaria SILAIS
  await auditService.registrar({
    usuarioId: usuario.id,
    tipoEntidad: 'invitaciones',
    idEntidad: inv.id,
    accion: 'INVITACION_CANJEADA',
    detalle: {
      contacto: inv.contacto,
      email_usuario: email,
      rol_asignado: inv.rol_destino,
      centro_salud_id: inv.centro_salud_id,
      centro_nombre: inv.centros_salud?.nombre,
      invitado_por: inv.creado_por,
      descripcion: `El usuario ${email} canjeó exitosamente la acreditación emitida para ${inv.contacto} en ${inv.centros_salud?.nombre || inv.centro_salud_id}`
    }
  });

  // Notificación automática a n8n
  try {
    await publicarEvento('acreditacion_sanitaria.canjeada', {
      token: tokenLimpio,
      usuario_id: usuario.id,
      email,
      nombre_completo: full_name,
      rol_asignado: inv.rol_destino,
      centro_salud_id: inv.centro_salud_id,
      centro_nombre: inv.centros_salud?.nombre
    });
  } catch (err) {
    console.error('[Invitations] No se pudo publicar canje en n8n:', err.message);
  }

  return {
    mensaje: `Bienvenido a la Red de Salud. Tu cuenta ha sido activada con rol ${inv.rol_destino}.`,
    token: session?.access_token || null,
    refresh_token: session?.refresh_token || null,
    rol: inv.rol_destino,
    centro_salud_id: inv.centro_salud_id,
    centro_salud_nombre: inv.centros_salud?.nombre || null,
    nombre_completo: full_name,
    email
  };
};

const listMyPromoters = async (centroSaludId) => {
  const [promotoresRes, invitacionesRes] = await Promise.all([
    invitationsRepo.listarPromotoresPorCentro(centroSaludId),
    invitationsRepo.listarInvitacionesPorCentro(centroSaludId)
  ]);

  return {
    promotores: promotoresRes.data || [],
    invitaciones: invitacionesRes.data || []
  };
};

const updatePromoterStatus = async (workerId, centroSaludId, promoterId, estado) => {
  const { data: promotor, error } = await invitationsRepo.actualizarEstadoCuentaPromotor(
    promoterId,
    centroSaludId,
    estado
  );

  if (error || !promotor) {
    throw new AppError('Promotor no encontrado en este centro de salud', 404);
  }

  await auditService.registrar({
    usuarioId: workerId,
    tipoEntidad: 'usuarios',
    idEntidad: promoterId,
    accion: estado === 'SUSPENDIDO' ? 'PROMOTOR_SUSPENDIDO' : 'PROMOTOR_REACTIVADO',
    detalle: { centro_salud_id: centroSaludId, nuevo_estado: estado }
  });

  return promotor;
};

const redeemInvitation = async (usuarioId, token) => {
  const verificacion = await verifyInvitation(token);
  const tokenLimpio = token.trim().toUpperCase();

  // 1. Obtener datos del usuario actual
  const { data: usuario, error: userErr } = await supabase
    .from('usuarios')
    .select('id, correo, rol, perfiles(nombre_completo)')
    .eq('id', usuarioId)
    .single();

  if (userErr || !usuario) {
    throw new AppError('Usuario no encontrado en el sistema', 404);
  }

  // 2. Seguridad de rol: Evitar suplantación de identidad si el token fue nominal por correo
  const contactoDestino = (verificacion.contacto || '').trim().toLowerCase();
  const userEmail = (usuario.correo || '').trim().toLowerCase();

  if (contactoDestino.includes('@') && contactoDestino !== userEmail) {
    throw new AppError(
      `Seguridad de rol: Este código de activación fue emitido exclusivamente para "${verificacion.contacto}". Tu cuenta actual ("${usuario.correo}") no coincide.`,
      403
    );
  }

  // 3. Buscar invitación
  const { data: inv } = await invitationsRepo.buscarInvitacionPorToken(tokenLimpio);

  // 4. Asignar rol y centro de salud de forma atómica e irreversible
  const { error: updateError } = await invitationsRepo.asignarRolYCentro(
    usuario.id,
    inv.rol_destino,
    inv.centro_salud_id,
    inv.creado_por
  );

  if (updateError) {
    throw new AppError('No se pudo asignar el rol y centro de salud a la cuenta', 500);
  }

  // 5. Marcar invitación como utilizada
  await invitationsRepo.marcarInvitacionUsada(inv.id, usuario.id);

  // 6. Auditoría Sanitaria SILAIS
  await auditService.registrar({
    usuarioId: usuario.id,
    tipoEntidad: 'invitaciones',
    idEntidad: inv.id,
    accion: 'INVITACION_CANJEADA',
    detalle: {
      contacto: inv.contacto,
      email_usuario: usuario.correo,
      rol_asignado: inv.rol_destino,
      centro_salud_id: inv.centro_salud_id,
      centro_nombre: inv.centros_salud?.nombre,
      invitado_por: inv.creado_por,
      descripcion: `El usuario ${usuario.correo} canjeó exitosamente la acreditación emitida para ${inv.contacto} en ${inv.centros_salud?.nombre || inv.centro_salud_id}`
    }
  });

  // Notificación automática a n8n
  try {
    await publicarEvento('acreditacion_sanitaria.canjeada', {
      token: tokenLimpio,
      usuario_id: usuario.id,
      email: usuario.correo,
      nombre_completo: usuario.perfiles?.nombre_completo || 'Usuario',
      rol_asignado: inv.rol_destino,
      centro_salud_id: inv.centro_salud_id,
      centro_nombre: inv.centros_salud?.nombre
    });
  } catch (err) {
    console.error('[Invitations] No se pudo publicar canje en n8n:', err.message);
  }

  return {
    mensaje: `¡Acreditación confirmada! Tu cuenta ha sido activada con rol ${inv.rol_destino}.`,
    rol: inv.rol_destino,
    centro_salud_id: inv.centro_salud_id,
    centro_salud_nombre: inv.centros_salud?.nombre || null
  };
};

module.exports = {
  generarCodigoInvitacion,
  inviteHealthWorker,
  invitePromoter,
  verifyInvitation,
  acceptInvitation,
  redeemInvitation,
  listMyPromoters,
  updatePromoterStatus
};
