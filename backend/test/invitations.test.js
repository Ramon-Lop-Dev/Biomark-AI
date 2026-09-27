const test = require('node:test');
const assert = require('node:assert/strict');

const {
  createHealthWorkerInvitationSchema,
  createPromoterInvitationSchema,
  acceptInvitationSchema,
  updatePromoterStatusSchema,
  redeemInvitationSchema
} = require('../src/modules/invitations/invitations.validator');
const { requireScope } = require('../src/middleware/requireScope.middleware');
const { clasificarCCM } = require('../src/modules/community/community.service');
const AppError = require('../src/utils/AppError');

test('Validadores de Invitaciones: Zod schemas aplican reglas estrictas de payload', () => {
  // 1. createHealthWorkerInvitationSchema requiere UUID de centro_salud_id
  const validHW = createHealthWorkerInvitationSchema.safeParse({
    contacto: 'medico.lang@minsa.gob.ni',
    centro_salud_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  });
  assert.equal(validHW.success, true);

  const invalidHW = createHealthWorkerInvitationSchema.safeParse({
    contacto: 'medico@minsa.gob.ni',
    centro_salud_id: 'no-es-uuid'
  });
  assert.equal(invalidHW.success, false);

  // 2. createPromoterInvitationSchema requiere contacto y permite centro_salud_id opcional (asignación por ADMIN)
  const validPromoter = createPromoterInvitationSchema.safeParse({
    contacto: '+505 8888-1234'
  });
  assert.equal(validPromoter.success, true);

  const validPromoterWithCenter = createPromoterInvitationSchema.safeParse({
    contacto: '+505 8888-1234',
    centro_salud_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
  });
  assert.equal(validPromoterWithCenter.success, true);

  // 3. acceptInvitationSchema valida email, formato de contraseña y presencia de token
  const validAccept = acceptInvitationSchema.safeParse({
    token: 'BM-A1B2C3',
    email: 'dra.perez@minsa.gob.ni',
    password: 'Password123!',
    full_name: 'Dra. María Pérez'
  });
  assert.equal(validAccept.success, true);

  const shortPassword = acceptInvitationSchema.safeParse({
    token: 'BM-A1B2C3',
    email: 'dra.perez@minsa.gob.ni',
    password: '123',
    full_name: 'Dra. María Pérez'
  });
  assert.equal(shortPassword.success, false);

  // 4. updatePromoterStatusSchema solo permite ACTIVO o SUSPENDIDO
  const validStatus = updatePromoterStatusSchema.safeParse({ estado: 'SUSPENDIDO' });
  assert.equal(validStatus.success, true);

  const invalidStatus = updatePromoterStatusSchema.safeParse({ estado: 'ELIMINADO' });
  assert.equal(invalidStatus.success, false);

  // 5. redeemInvitationSchema valida presencia de token válido
  const validRedeem = redeemInvitationSchema.safeParse({ token: 'BM-7A3F9C' });
  assert.equal(validRedeem.success, true);

  const invalidRedeem = redeemInvitationSchema.safeParse({ token: '12' });
  assert.equal(invalidRedeem.success, false);
});

test('Middleware requireScope: Restringe acceso territorial por centro_salud_id', () => {
  // 1. ADMIN tiene acceso irrestricto (scope null)
  const reqAdmin = { usuarioRol: 'ADMIN' };
  let adminNextCalled = false;
  requireScope(reqAdmin, {}, (err) => {
    assert.equal(err, undefined);
    assert.equal(reqAdmin.scopeCentroSaludId, null);
    adminNextCalled = true;
  });
  assert.equal(adminNextCalled, true);

  // 2. TRABAJADOR_SALUD con centro asignado inyecta su centro_salud_id
  const testCenterId = 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22';
  const reqHW = {
    usuarioRol: 'TRABAJADOR_SALUD',
    centroSaludId: testCenterId
  };
  let hwNextCalled = false;
  requireScope(reqHW, {}, (err) => {
    assert.equal(err, undefined);
    assert.equal(reqHW.scopeCentroSaludId, testCenterId);
    hwNextCalled = true;
  });
  assert.equal(hwNextCalled, true);

  // 3. PROMOTOR sin centro asignado es rechazado con HTTP 403
  const reqUnassigned = {
    usuarioRol: 'PROMOTOR',
    centroSaludId: null
  };
  let errorReturned = null;
  requireScope(reqUnassigned, {}, (err) => {
    errorReturned = err;
  });
  assert.ok(errorReturned instanceof AppError);
  assert.equal(errorReturned.statusCode, 403);

  // 4. Usuario sin rol determinado es rechazado con HTTP 401
  const reqNoRole = {};
  let noRoleError = null;
  requireScope(reqNoRole, {}, (err) => {
    noRoleError = err;
  });
  assert.ok(noRoleError instanceof AppError);
  assert.equal(noRoleError.statusCode, 401);
});

test('Triaje CCM: Clasifica correctamente la severidad clínica y signos de alarma', () => {
  // Signos de peligro -> ROJO (dificultad respiratoria, sangrado, convulsiones, letargia)
  const reporteGrave1 = clasificarCCM({
    description: 'Paciente con sangrado de encías y fiebre muy alta',
    tipo_enfermedad: 'Dengue'
  });
  assert.equal(reporteGrave1, 'ROJO');

  const reporteGrave2 = clasificarCCM({
    description: 'Niño con dificultad respiratoria y tiraje intercostal',
    tipo_enfermedad: 'IRA'
  });
  assert.equal(reporteGrave2, 'ROJO');

  const reporteGrave3 = clasificarCCM({
    description: 'Vómitos frecuentes e intolerancia oral completa',
    signos_peligro: ['deshidratacion grave']
  });
  assert.equal(reporteGrave3, 'ROJO');

  // Principio Fail-Safe: si viene marcado VERDE pero describe convulsión, escala a ROJO
  const reporteFailSafe = clasificarCCM({
    description: 'Presentó convulsiones durante la noche',
    clasificacion_ccm: 'VERDE'
  });
  assert.equal(reporteFailSafe, 'ROJO');

  // Síntomas moderados -> AMARILLO (fiebre, rash, mialgia, cefalea)
  const reporteModerado = clasificarCCM({
    description: 'Tiene fiebre desde ayer y dolor de cuerpo generalizado',
    tipo_enfermedad: 'Dengue'
  });
  assert.equal(reporteModerado, 'AMARILLO');

  const reporteRash = clasificarCCM({
    description: 'Manchas rojas en la piel y dolor en articulaciones',
    tipo_enfermedad: 'Chikungunya'
  });
  assert.equal(reporteRash, 'AMARILLO');

  // Preventivo / ambiental -> VERDE (fumigación, criaderos de zancudos, basura)
  const reportePreventivo = clasificarCCM({
    description: 'Hay muchos charcos con criaderos de zancudos en el patio comunal',
    tipo_enfermedad: 'Otro'
  });
  assert.equal(reportePreventivo, 'VERDE');

  const reporteLimpio = clasificarCCM({
    description: 'Solicitud comunitaria de abatización para el barrio',
    tipo_enfermedad: 'Otro'
  });
  assert.equal(reporteLimpio, 'VERDE');
});

test('Seguridad de Rol: acceptInvitation rechaza suplantación cuando el correo no coincide con el contacto destino', async () => {
  const invitationsService = require('../src/modules/invitations/invitations.service');
  const invitationsRepo = require('../src/modules/invitations/invitations.repository');

  const mockToken = 'BM-SEC123';
  const originalBuscar = invitationsRepo.buscarInvitacionPorToken;
  invitationsRepo.buscarInvitacionPorToken = async () => ({
    data: {
      id: 'mock-inv-id',
      token: mockToken,
      contacto: 'dr.pedro@minsa.gob.ni',
      rol_destino: 'TRABAJADOR_SALUD',
      centro_salud_id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      expira_en: new Date(Date.now() + 86400000).toISOString(),
      usado_en: null,
      centros_salud: { nombre: 'Centro de Salud Edgar Lang', municipio: 'Managua' }
    },
    error: null
  });

  try {
    await assert.rejects(
      async () => {
        await invitationsService.acceptInvitation({
          token: mockToken,
          email: 'impostor@gmail.com',
          password: 'Password123!',
          full_name: 'Usuario No Autorizado'
        });
      },
      (err) => {
        assert.ok(err instanceof AppError);
        assert.equal(err.statusCode, 403);
        assert.ok(err.message.includes('Seguridad de rol'));
        return true;
      }
    );
  } finally {
    invitationsRepo.buscarInvitacionPorToken = originalBuscar;
  }
});

