const test = require('node:test');
const assert = require('node:assert/strict');
const { TIPOS_NOTIFICACION } = require('../src/modules/notifications/notifications.service');

test('Notifications: tipos de notificación permitidos según arquitectura', () => {
  assert.equal(TIPOS_NOTIFICACION.includes('RECORDATORIO'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('ALERTA_EPIDEMIOLOGICA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('SISTEMA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('INVALIDA'), false);
});
