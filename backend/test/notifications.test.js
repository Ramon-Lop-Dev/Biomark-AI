const test = require('node:test');
const assert = require('node:assert/strict');
const { TIPOS_NOTIFICACION } = require('../src/modules/notifications/notifications.service');

test('Notifications: tipos de notificación permitidos según arquitectura', () => {
  assert.equal(TIPOS_NOTIFICACION.includes('RECORDATORIO'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('ALERTA_EPIDEMIOLOGICA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('SISTEMA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('INVALIDA'), false);
});

test('Notifications: getNotifications devuelve lista limpia sin semillas ni datos falsos precargados', async () => {
  const { getNotifications } = require('../src/modules/notifications/notifications.service');
  // Se consulta con un usuario inexistente o sin base de datos mockeada
  const result = await getNotifications('00000000-0000-0000-0000-000000000000');
  assert.ok(Array.isArray(result.notificaciones));
  // Debe ser una lista real, nunca debe tener identificadores de semillas 'seed-notif-'
  const tieneSemillasFalsas = result.notificaciones.some((n) => String(n.id).startsWith('seed-notif-'));
  assert.equal(tieneSemillasFalsas, false, 'No deben existir notificaciones mock con prefijo seed-notif-');
  assert.equal(typeof result.total, 'number');
  assert.equal(typeof result.no_leidas, 'number');
});
