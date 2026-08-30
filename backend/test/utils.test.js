const test = require('node:test');
const assert = require('node:assert/strict');
const { distanciaKm } = require('../src/utils/geo');
const { mapearNivelRiesgo } = require('../src/utils/nivelRiesgo');

test('calcula distancia cero y distancia conocida', () => {
  assert.equal(distanciaKm(0, 0, 0, 0), 0);
  assert.ok(Math.abs(distanciaKm(0, 0, 0, 1) - 111.2) < 0.5);
});

test('mapea niveles del contrato AI al enum PostgreSQL', () => {
  assert.equal(mapearNivelRiesgo('CRITICAL'), 'CRITICO');
  assert.equal(mapearNivelRiesgo('moderate'), 'MODERADO');
  assert.equal(mapearNivelRiesgo('desconocido'), 'BAJO');
  assert.equal(mapearNivelRiesgo(null), null);
});
