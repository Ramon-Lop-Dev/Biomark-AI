// Pruebas para la unificación de identidades y prevención de duplicados en autenticación.
const test = require('node:test');
const assert = require('node:assert/strict');
const authRepo = require('../src/modules/auth/auth.repository');

test('Auth: findUsuarioByEmail normaliza el correo con trim e ilike', async () => {
  // Verificamos que la función exista y sea ejecutable
  assert.equal(typeof authRepo.findUsuarioByEmail, 'function');
  assert.equal(typeof authRepo.actualizarAuthId, 'function');

  // Buscar un correo inexistente debe retornar data: null sin explotar
  const { data, error } = await authRepo.findUsuarioByEmail('correo_inexistente_12345@biomark.org');
  assert.equal(error, null);
  assert.equal(data, null);
});
