const test = require('node:test');
const assert = require('node:assert/strict');
const {
  bboxSchema,
  centersNearbySchema,
  centerIdSchema
} = require('../src/modules/gis/gis.validator');

test('valida un bbox y aplica defaults GIS', () => {
  const result = bboxSchema.safeParse({
    min_lon: '-86.35',
    min_lat: '12.08',
    max_lon: '-86.20',
    max_lat: '12.20'
  });

  assert.equal(result.success, true);
  assert.equal(result.data.nivel_min, 1);
  assert.equal(result.data.zoom, 15);
  assert.equal(typeof result.data.min_lon, 'number');
});

test('rechaza un bbox invertido', () => {
  const result = bboxSchema.safeParse({
    min_lon: '-86.20',
    min_lat: '12.20',
    max_lon: '-86.35',
    max_lat: '12.08'
  });

  assert.equal(result.success, false);
});

test('valida parámetros clínicos de cercanía', () => {
  const result = centersNearbySchema.safeParse({
    lat: '12.1364',
    lon: '-86.2514',
    servicio: 'dermatologia',
    edad: '34'
  });

  assert.equal(result.success, true);
  assert.equal(result.data.radio_m, 5000);
  assert.equal(result.data.limite, 10);
});

test('valida UUID de detalle de centro', () => {
  assert.equal(
    centerIdSchema.safeParse({ id: '628e0138-ee46-4c38-a116-0162564532f9' }).success,
    true
  );
  assert.equal(centerIdSchema.safeParse({ id: 'centro-invalido' }).success, false);
});
