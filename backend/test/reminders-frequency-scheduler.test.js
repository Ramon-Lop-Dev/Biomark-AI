const test = require('node:test');
const assert = require('node:assert/strict');
const { addReminderSchema, FRECUENCIAS_RECORDATORIO } = require('../src/modules/reminders/reminders.validator');
const { calcularSiguienteFecha } = require('../src/modules/reminders/reminders.service');

test('valida frecuencia de recordatorio y aplica default UNA_VEZ', () => {
  assert.deepEqual(FRECUENCIAS_RECORDATORIO, ['UNA_VEZ', 'DIARIA', 'SEMANAL', 'MENSUAL']);

  const base = {
    titulo: 'Control de glucosa',
    fecha_programada: '2026-09-20T08:00:00.000Z',
    tipo: 'CONTROL'
  };

  const conDefault = addReminderSchema.parse(base);
  assert.equal(conDefault.frecuencia, 'UNA_VEZ');

  const conFrecuencia = addReminderSchema.parse({ ...base, frecuencia: 'DIARIA' });
  assert.equal(conFrecuencia.frecuencia, 'DIARIA');

  assert.throws(() => {
    addReminderSchema.parse({ ...base, frecuencia: 'CADA_HORA' });
  });
});

test('calcularSiguienteFecha proyecta la fecha según la frecuencia', () => {
  const baseIso = '2026-09-20T08:00:00.000Z';

  const diaria = calcularSiguienteFecha(baseIso, 'DIARIA');
  assert.equal(diaria, '2026-09-21T08:00:00.000Z');

  const semanal = calcularSiguienteFecha(baseIso, 'SEMANAL');
  assert.equal(semanal, '2026-09-27T08:00:00.000Z');

  const mensual = calcularSiguienteFecha(baseIso, 'MENSUAL');
  assert.equal(mensual, '2026-10-20T08:00:00.000Z');

  const unaVez = calcularSiguienteFecha(baseIso, 'UNA_VEZ');
  assert.equal(unaVez, null);
});
