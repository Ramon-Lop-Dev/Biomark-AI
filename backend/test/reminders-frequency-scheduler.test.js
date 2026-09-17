const test = require('node:test');
const assert = require('node:assert/strict');
const { addReminderSchema, FRECUENCIAS_RECORDATORIO, AVISOS_PREVIOS } = require('../src/modules/reminders/reminders.validator');
const { calcularSiguienteFecha, calcularFechaNotificacion } = require('../src/modules/reminders/reminders.service');

test('valida frecuencia de recordatorio y aplica default UNA_VEZ', () => {
  assert.deepEqual(FRECUENCIAS_RECORDATORIO, ['UNA_VEZ', 'HORARIA', 'DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL']);

  const base = {
    titulo: 'Control de glucosa',
    fecha_programada: '2026-09-20T08:00:00.000Z',
    tipo: 'CONTROL'
  };

  const conDefault = addReminderSchema.parse(base);
  assert.equal(conDefault.frecuencia, 'UNA_VEZ');
  assert.equal(conDefault.aviso_previo, 'AL_MOMENTO');

  const conHoraria = addReminderSchema.parse({ ...base, frecuencia: 'HORARIA' });
  assert.equal(conHoraria.frecuencia, 'HORARIA');

  const conQuincenal = addReminderSchema.parse({ ...base, frecuencia: 'QUINCENAL' });
  assert.equal(conQuincenal.frecuencia, 'QUINCENAL');

  assert.throws(() => {
    addReminderSchema.parse({ ...base, frecuencia: 'FRECUENCIA_INVALIDA' });
  });
});

test('valida opciones de aviso_previo (anticipación)', () => {
  assert.deepEqual(AVISOS_PREVIOS, ['AL_MOMENTO', '1_HORA_ANTES', '1_DIA_ANTES', '2_DIAS_ANTES']);

  const base = {
    titulo: 'Cita con cardiólogo',
    fecha_programada: '2026-09-25T10:00:00.000Z',
    tipo: 'CITA'
  };

  const unaHora = addReminderSchema.parse({ ...base, aviso_previo: '1_HORA_ANTES' });
  assert.equal(unaHora.aviso_previo, '1_HORA_ANTES');

  const unDia = addReminderSchema.parse({ ...base, aviso_previo: '1_DIA_ANTES' });
  assert.equal(unDia.aviso_previo, '1_DIA_ANTES');

  const dosDias = addReminderSchema.parse({ ...base, aviso_previo: '2_DIAS_ANTES' });
  assert.equal(dosDias.aviso_previo, '2_DIAS_ANTES');

  assert.throws(() => {
    addReminderSchema.parse({ ...base, aviso_previo: '3_SEMANAS_ANTES' });
  });
});

test('calcularFechaNotificacion calcula la fecha anticipada correctamente', () => {
  const eventoIso = '2026-09-25T10:00:00.000Z';

  const alMomento = calcularFechaNotificacion(eventoIso, 'AL_MOMENTO');
  assert.equal(alMomento, '2026-09-25T10:00:00.000Z');

  const unaHora = calcularFechaNotificacion(eventoIso, '1_HORA_ANTES');
  assert.equal(unaHora, '2026-09-25T09:00:00.000Z');

  const unDia = calcularFechaNotificacion(eventoIso, '1_DIA_ANTES');
  assert.equal(unDia, '2026-09-24T10:00:00.000Z');

  const dosDias = calcularFechaNotificacion(eventoIso, '2_DIAS_ANTES');
  assert.equal(dosDias, '2026-09-23T10:00:00.000Z');
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
