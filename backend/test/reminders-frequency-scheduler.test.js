const test = require('node:test');
const assert = require('node:assert/strict');
const { addReminderSchema, FRECUENCIAS_RECORDATORIO } = require('../src/modules/reminders/reminders.validator');
const { calcularSiguienteFecha } = require('../src/modules/reminders/reminders.service');

test('valida frecuencia de recordatorio y aplica default UNA_VEZ', () => {
  assert.deepEqual(FRECUENCIAS_RECORDATORIO, ['UNA_VEZ', 'HORARIA', 'DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL']);

  const base = {
    titulo: 'Control de glucosa',
    fecha_programada: '2026-09-20T08:00:00.000Z',
    tipo: 'CONTROL'
  };

  const conDefault = addReminderSchema.parse(base);
  assert.equal(conDefault.frecuencia, 'UNA_VEZ');

  const conHoraria = addReminderSchema.parse({ ...base, frecuencia: 'HORARIA' });
  assert.equal(conHoraria.frecuencia, 'HORARIA');

  const conQuincenal = addReminderSchema.parse({ ...base, frecuencia: 'QUINCENAL' });
  assert.equal(conQuincenal.frecuencia, 'QUINCENAL');

  assert.throws(() => {
    addReminderSchema.parse({ ...base, frecuencia: 'FRECUENCIA_INVALIDA' });
  });
});

test('calcularSiguienteFecha proyecta la fecha según la frecuencia', () => {
  const baseIso = '2026-09-20T08:00:00.000Z';

  const horaria = calcularSiguienteFecha(baseIso, 'HORARIA');
  assert.equal(horaria, '2026-09-20T09:00:00.000Z');

  const diaria = calcularSiguienteFecha(baseIso, 'DIARIA');
  assert.equal(diaria, '2026-09-21T08:00:00.000Z');

  const semanal = calcularSiguienteFecha(baseIso, 'SEMANAL');
  assert.equal(semanal, '2026-09-27T08:00:00.000Z');

  const quincenal = calcularSiguienteFecha(baseIso, 'QUINCENAL');
  assert.equal(quincenal, '2026-10-05T08:00:00.000Z');

  const mensual = calcularSiguienteFecha(baseIso, 'MENSUAL');
  assert.equal(mensual, '2026-10-20T08:00:00.000Z');

  const unaVez = calcularSiguienteFecha(baseIso, 'UNA_VEZ');
  assert.equal(unaVez, null);
});
