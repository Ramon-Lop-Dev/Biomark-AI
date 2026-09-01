const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizarHorarios,
  generarPlanRecordatoriosMedicamento
} = require('../src/modules/medical/medical.service');

test('normaliza horarios a formato HH:MM sin vacíos', () => {
  assert.deepEqual(normalizarHorarios(['08:00', ' 20:30 ', '']), ['08:00', '20:30']);
  assert.deepEqual(normalizarHorarios('08:00, 20:30'), ['08:00', '20:30']);
});

test('genera un plan de recordatorios solo cuando hay confirmación del usuario', () => {
  const plan = generarPlanRecordatoriosMedicamento({
    nombreMedicamento: 'Paracetamol',
    frecuencia: 'cada 12 horas',
    horarios: ['08:00', '20:00'],
    fechaInicio: '2026-09-01',
    fechaFin: '2026-09-03',
    confirmadoPorUsuario: true
  });

  assert.equal(plan.length, 6);
  assert.equal(plan[0].titulo, 'Tomar Paracetamol');
  assert.match(plan[0].fecha_programada, /2026-09-01T08:00:00/);
  assert.equal(plan[0].tipo, 'MEDICAMENTO');

  const sinConfirmacion = generarPlanRecordatoriosMedicamento({
    nombreMedicamento: 'Ibuprofeno',
    frecuencia: 'cada 12 horas',
    horarios: ['08:00'],
    fechaInicio: '2026-09-01',
    confirmadoPorUsuario: false
  });

  assert.deepEqual(sinConfirmacion, []);
});
