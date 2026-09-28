process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  TIPOS_NOTIFICACION,
  formatearNotifJornada,
  formatearNotifBrote,
  formatearNotifPauta,
  formatearNotifAlertaSanitaria
} = require('../src/modules/notifications/notifications.service');

test('Notifications: tipos de notificación permitidos según arquitectura', () => {
  assert.equal(TIPOS_NOTIFICACION.includes('RECORDATORIO'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('ALERTA_EPIDEMIOLOGICA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('SISTEMA'), true);
  assert.equal(TIPOS_NOTIFICACION.includes('INVALIDA'), false);
});

test('Notifications: formateadores generan información clara, humana y con recomendaciones preventivas', () => {
  const jornada = formatearNotifJornada({
    titulo: 'Campaña Canina y Felina',
    tipo: 'VACUNACION',
    fecha_evento: '2026-10-01T08:00:00Z',
    ubicacion: 'Parque Los Robles',
    descripcion: 'Vacunación antirrábica gratuita'
  });
  assert.ok(jornada.titulo.includes('💉'));
  assert.ok(jornada.titulo.includes('Vacunación'));
  assert.ok(jornada.mensaje.includes('Parque Los Robles'));
  assert.ok(jornada.mensaje.includes('tarjeta de vacunación'));

  const brote = formatearNotifBrote({
    tipo_enfermedad: 'Dengue',
    direccion_exacta: 'Barrio Santa Ana',
    descripcion: 'Sospecha comunitaria'
  });
  assert.ok(brote.titulo.includes('🚨'));
  assert.ok(brote.titulo.includes('Dengue'));
  assert.ok(brote.mensaje.includes('Barrio Santa Ana'));
  assert.ok(brote.mensaje.includes('agua estancada'));

  const pauta = formatearNotifPauta({
    titulo: 'Control del Aedes aegypti',
    resumen: 'Lava pilas y barriles',
    normativa_minsa: 'Normativa 004'
  });
  assert.ok(pauta.titulo.includes('📋'));
  assert.ok(pauta.mensaje.includes('Normativa 004'));
  assert.ok(pauta.mensaje.includes('Lava pilas'));
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

test('Notifications: enviarPushDirecto maneja arrays vacíos o nulos de forma segura', async () => {
  const { enviarPushDirecto } = require('../src/modules/notifications/notifications.service');
  const resEmpty = await enviarPushDirecto({ tokens: [], titulo: 'Test', mensaje: 'Mensaje' });
  assert.equal(resEmpty.successCount, 0);
  assert.equal(resEmpty.failureCount, 0);
});

test('Notifications: hooks de alerta, jornada y pauta MINSA se ejecutan de manera resiliente', async () => {
  const {
    notificarAlertaReporte,
    notificarJornadaSalud,
    notificarPautaMinsa,
    notificarAlertaSanitaria
  } = require('../src/modules/notifications/notifications.service');

  // Ninguno de estos hooks debe lanzar excepciones no controladas
  await assert.doesNotReject(async () => {
    await notificarAlertaReporte({
      id: '00000000-0000-0000-0000-000000000001',
      tipo_enfermedad: 'Dengue',
      descripcion: 'Brote sospechoso en prueba',
      direccion_exacta: 'Barrio Altagracia'
    });
  });

  await assert.doesNotReject(async () => {
    await notificarJornadaSalud({
      id: '00000000-0000-0000-0000-000000000002',
      titulo: 'Jornada de Vacunación Canina',
      descripcion: 'Puesto móvil en parque',
      fecha_evento: '2026-10-01',
      ubicacion: 'Distrito II',
      tipo: 'VACUNACION'
    });
  });

  await assert.doesNotReject(async () => {
    await notificarPautaMinsa({
      id: '00000000-0000-0000-0000-000000000003',
      titulo: 'Prevención Dengue',
      resumen: 'Eliminar criaderos',
      categoria: 'dengue',
      normativa_minsa: 'Normativa 004'
    });
  });

  await assert.doesNotReject(async () => {
    await notificarAlertaSanitaria({
      id: '00000000-0000-0000-0000-000000000004',
      nivel_alerta: 'ROJO',
      mensaje: 'Alerta sanitaria regional'
    });
  });
});
