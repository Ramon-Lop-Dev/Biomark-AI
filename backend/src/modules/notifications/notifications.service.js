const notificationsRepo = require('./notifications.repository');
const AppError = require('../../utils/AppError');
const supabase = require('../../config/supabase');
const admin = require('../../config/firebase');
const { N8N_WEBHOOK_URL, publicarEvento } = require('../../config/n8nClient');

const TIPOS_NOTIFICACION = ['RECORDATORIO', 'ALERTA_EPIDEMIOLOGICA', 'SISTEMA'];

/**
 * Envía notificaciones Push directas a través de Firebase Cloud Messaging (FCM).
 * Utiliza las credenciales de servicio configuradas en el backend sin depender obligatoriamente de n8n.
 */
const enviarPushDirecto = async ({ tokens = [], titulo, mensaje, datosAdicionales = {} }) => {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0 };

  if (!admin.apps.length) {
    console.warn('[Push Directo] Firebase Admin no está inicializado. Se omite envío FCM.');
    return { successCount: 0, failureCount: 0 };
  }

  // FCM data solo acepta valores tipo string
  const dataStringMap = {};
  for (const [k, v] of Object.entries(datosAdicionales)) {
    dataStringMap[k] = typeof v === 'string' ? v : JSON.stringify(v);
  }

  try {
    const payload = {
      tokens,
      notification: {
        title: titulo || 'Biomark AI',
        body: mensaje || ''
      },
      data: dataStringMap,
      android: {
        priority: 'high',
        notification: {
          channelId: 'biomark_notifications',
          sound: 'default'
        }
      }
    };

    const response = await admin.messaging().sendEachForMulticast(payload);
    console.log(`[Push Directo] FCM enviado: ${response.successCount} exitosos, ${response.failureCount} fallidos.`);

    // Si hay tokens no registrados, desactivarlos en segundo plano
    if (response.failureCount > 0) {
      const tokensAEliminar = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token'
          ) {
            tokensAEliminar.push(tokens[idx]);
          }
        }
      });

      if (tokensAEliminar.length > 0) {
        try {
          await supabase
            .from('dispositivos_push')
            .update({ activo: false })
            .in('fcm_token', tokensAEliminar);
          console.log(`[Push Directo] Se desactivaron ${tokensAEliminar.length} tokens FCM obsoletos.`);
        } catch (_) {}
      }
    }

    return response;
  } catch (error) {
    console.error('[Push Directo] Error al enviar FCM multicast:', error.message);
    return { successCount: 0, failureCount: tokens.length, error: error.message };
  }
};

/**
 * Obtiene los tokens FCM activos desde Supabase.
 * Si se especifica usuarioId, devuelve solo los de ese usuario; de lo contrario, devuelve todos los activos.
 */
const obtenerTokensActivos = async (usuarioId = null) => {
  try {
    let query = supabase
      .from('dispositivos_push')
      .select('fcm_token')
      .eq('activo', true);

    if (usuarioId) {
      query = query.eq('usuario_id', usuarioId);
    }

    const { data, error } = await query;
    if (error || !data) return [];
    return data.map((d) => d.fcm_token).filter(Boolean);
  } catch (err) {
    console.error('[Notifications] Error al obtener tokens push:', err.message);
    return [];
  }
};

/**
 * Crea una notificación como hook transversal desde cualquier módulo
 * (ej. alertas de chat, recordatorios médicos o brotes de MINSA).
 */
const notificar = async ({ usuarioId, tipo, mensaje, titulo, datosAdicionales }) => {
  if (!TIPOS_NOTIFICACION.includes(tipo)) {
    console.error(`[Notifications] tipo no reconocido: "${tipo}". No se creó la notificación.`);
    return;
  }

  try {
    const { error } = await notificationsRepo.crear({
      usuarioId,
      tipo,
      mensaje,
      titulo,
      datosAdicionales
    });
    if (error) {
      console.error('[Notifications] No se pudo crear la notificación:', error.message);
    }
  } catch (err) {
    console.error('[Notifications] Error inesperado al notificar:', err.message);
  }

  // Envío Push directo a los dispositivos del usuario
  try {
    const tokens = await obtenerTokensActivos(usuarioId);
    if (tokens.length > 0) {
      await enviarPushDirecto({
        tokens,
        titulo: titulo || 'Biomark AI',
        mensaje,
        datosAdicionales: { ...datosAdicionales, tipo }
      });
    }
  } catch (err) {
    console.warn('[Notifications] Error al enviar push en hook notificar:', err.message);
  }
};

/**
 * Notifica a la comunidad sobre un brote epidemiológico validado por el personal de salud.
 */
const notificarAlertaReporte = async (reporte) => {
  const titulo = `🚨 Alerta Epidemiológica: Brote de ${reporte.tipo_enfermedad || 'Enfermedad'}`;
  const mensaje = `${reporte.descripcion || 'Caso comunitario validado por personal sanitario'}. Sector: ${reporte.direccion_exacta || 'Managua'}. Clasificación: ${reporte.clasificacion_ccm || 'AMARILLO'}`;
  const datosAdicionales = {
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    reporte_id: String(reporte.id || ''),
    clasificacion_ccm: reporte.clasificacion_ccm || 'AMARILLO',
    latitud: String(reporte.latitud || ''),
    longitud: String(reporte.longitud || '')
  };

  // 1. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de alerta epidemiológica:', err.message);
  }

  // 2. Si n8n está configurado, despachar evento en paralelo
  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('reporte_comunitario.validado', { reporte });
    } catch (_) {}
  }
};

/**
 * Notifica a la comunidad sobre una nueva jornada comunitaria (vacunación, fumigación, abatización).
 */
const notificarJornadaSalud = async (evento) => {
  const tipoLabel = evento.tipo ? `[${evento.tipo}] ` : '';
  const titulo = `📅 Jornada de Salud: ${evento.titulo}`;
  const mensaje = `${tipoLabel}${evento.descripcion || 'Nueva jornada comunitaria disponible'}. Fecha: ${evento.fecha_evento || 'Próximamente'} - Lugar: ${evento.ubicacion || 'Managua'}`;
  const datosAdicionales = {
    tipo: 'SISTEMA',
    subtipo: 'JORNADA',
    evento_id: String(evento.id || ''),
    fecha_evento: String(evento.fecha_evento || ''),
    ubicacion: String(evento.ubicacion || '')
  };

  // 1. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de jornada comunitaria:', err.message);
  }

  // 2. Si n8n está configurado, despachar evento en paralelo
  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('evento_comunitario.creado', { evento_comunitario: evento });
    } catch (_) {}
  }
};

/**
 * Notifica a la comunidad sobre una nueva pauta, recomendación o aviso oficial del MINSA.
 */
const notificarPautaMinsa = async (rec) => {
  const titulo = `📋 Aviso Oficial MINSA: ${rec.titulo}`;
  const mensaje = `${rec.resumen || rec.detalle_clinico || 'Nueva directriz preventiva oficial.'} ${rec.normativa_minsa ? 'Normativa: ' + rec.normativa_minsa : ''}`.trim();
  const datosAdicionales = {
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    subtipo: 'PAUTA_MINSA',
    recomendacion_id: String(rec.id || ''),
    categoria: String(rec.categoria || '')
  };

  // 1. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de pauta MINSA:', err.message);
  }
};

/**
 * Notifica una alerta sanitaria formal emitida por epidemiología.
 */
const notificarAlertaSanitaria = async (alerta) => {
  const titulo = `⚠️ Alerta Sanitaria MINSA (${alerta.nivel_alerta || 'GENERAL'})`;
  const mensaje = alerta.mensaje || 'Aviso de vigilancia epidemiológica.';
  const datosAdicionales = {
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    alerta_id: String(alerta.id || ''),
    nivel_alerta: String(alerta.nivel_alerta || '')
  };

  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de alerta sanitaria:', err.message);
  }

  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('alerta.epidemiologica.creada', { alerta });
    } catch (_) {}
  }
};

/**
 * Consulta y unifica la bandeja de notificaciones in-app del usuario,
 * agregando en tiempo real:
 * - Notificaciones directas
 * - Recordatorios médicos y de citas
 * - Reportes comunitarios validados (brotes de dengue, malaria, etc.)
 * - Alertas epidemiológicas activas
 * - Pautas y recomendaciones oficiales del MINSA
 * - Jornadas de salud comunitaria
 */
const getNotifications = async (usuarioId, { limit = 30, offset = 0, soloNoLeidas = false } = {}) => {
  try {
    const [{ data: directNotifs, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
      notificationsRepo.listarPorUsuario(usuarioId, { limit: 50, offset: 0, soloNoLeidas }),
      notificationsRepo.contarNoLeidas(usuarioId)
    ]);

    // 1. Recordatorios del usuario
    let reminderItems = [];
    try {
      const { data: reminders } = await supabase
        .from('recordatorios')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('fecha_programada', { ascending: false })
        .limit(20);

      if (reminders && reminders.length > 0) {
        reminderItems = reminders.map((r) => {
          const isDone = r.estado === 'COMPLETADO' || r.estado === 'CANCELADO';
          const labelEstado = r.estado === 'COMPLETADO' ? 'Completado' : r.estado === 'CANCELADO' ? 'Cancelado' : 'Pendiente';
          return {
            id: `rem_${r.id}`,
            usuario_id: usuarioId,
            tipo: 'RECORDATORIO',
            titulo: `${r.titulo} (${labelEstado})`,
            mensaje: r.descripcion
              ? `${r.descripcion}. Estado: ${r.estado}`
              : `Recordatorio de ${r.tipo ? r.tipo.toLowerCase() : 'salud'} programado para ${r.fecha_programada}. Estado: ${r.estado}`,
            fecha_creacion: r.fecha_creacion || r.fecha_programada,
            fecha_lectura: isDone ? (r.fecha_creacion || new Date().toISOString()) : null,
            leida: isDone,
            datos_adicionales: { reminder_id: r.id, estado: r.estado, tipo_recordatorio: r.tipo }
          };
        });
      }
    } catch (_) {}

    // 2. Reportes comunitarios validados (Brotes epidémicos territoriales)
    let brotesItems = [];
    try {
      const { data: brotes } = await supabase
        .from('reportes_comunitarios')
        .select('id, tipo_enfermedad, descripcion, direccion_exacta, clasificacion_ccm, fecha_creacion')
        .eq('estado', 'VALIDADO')
        .order('fecha_creacion', { ascending: false })
        .limit(10);

      if (brotes && brotes.length > 0) {
        brotesItems = brotes.map((b) => ({
          id: `rep_${b.id}`,
          usuario_id: usuarioId,
          tipo: 'ALERTA_EPIDEMIOLOGICA',
          titulo: `Brote Detectado: ${b.tipo_enfermedad || 'Enfermedad Vigilada'}`,
          mensaje: `${b.descripcion || 'Caso verificado por brigadistas de salud'}. Sector: ${b.direccion_exacta || 'Managua'} (Nivel: ${b.clasificacion_ccm || 'ALERTA'})`,
          fecha_creacion: b.fecha_creacion,
          fecha_lectura: null,
          leida: false,
          datos_adicionales: { reporte_id: b.id, tipo_enfermedad: b.tipo_enfermedad }
        }));
      }
    } catch (_) {}

    // 3. Alertas epidemiológicas activas
    let alertasItems = [];
    try {
      const { data: alertas } = await supabase
        .from('alertas_epidemiologicas')
        .select('id, nivel_alerta, mensaje, fecha_creacion, fecha_expiracion')
        .or(`fecha_expiracion.is.null,fecha_expiracion.gte.${new Date().toISOString()}`)
        .order('fecha_creacion', { ascending: false })
        .limit(10);

      if (alertas && alertas.length > 0) {
        alertasItems = alertas.map((a) => ({
          id: `alerta_${a.id}`,
          usuario_id: usuarioId,
          tipo: 'ALERTA_EPIDEMIOLOGICA',
          titulo: `Alerta Sanitaria MINSA (${a.nivel_alerta || 'GENERAL'})`,
          mensaje: a.mensaje || 'Vigilancia epidemiológica activa en la región.',
          fecha_creacion: a.fecha_creacion,
          fecha_lectura: null,
          leida: false,
          datos_adicionales: { alerta_id: a.id, nivel_alerta: a.nivel_alerta }
        }));
      }
    } catch (_) {}

    // 4. Pautas y Recomendaciones Oficiales MINSA publicadas
    let pautasItems = [];
    try {
      const { data: pautas } = await supabase
        .from('recomendaciones_salud')
        .select('id, titulo, resumen, categoria, normativa_minsa, fecha_creacion')
        .eq('estado', 'PUBLICADO')
        .order('fecha_creacion', { ascending: false })
        .limit(10);

      if (pautas && pautas.length > 0) {
        pautasItems = pautas.map((p) => {
          const esAlerta = p.categoria === 'dengue' || p.categoria === 'minsaNotice';
          return {
            id: `rec_${p.id}`,
            usuario_id: usuarioId,
            tipo: esAlerta ? 'ALERTA_EPIDEMIOLOGICA' : 'SISTEMA',
            titulo: `Aviso MINSA: ${p.titulo}`,
            mensaje: `${p.resumen}. ${p.normativa_minsa ? '[' + p.normativa_minsa + ']' : ''}`.trim(),
            fecha_creacion: p.fecha_creacion,
            fecha_lectura: null,
            leida: false,
            datos_adicionales: { recomendacion_id: p.id, categoria: p.categoria }
          };
        });
      }
    } catch (_) {}

    // 5. Jornadas Comunitarias activas (vacunación, fumigación, ferias)
    let jornadasItems = [];
    try {
      const { data: jornadas } = await supabase
        .from('eventos_comunitarios')
        .select('id, titulo, descripcion, tipo, fecha_evento, ubicacion')
        .order('fecha_evento', { ascending: false })
        .limit(10);

      if (jornadas && jornadas.length > 0) {
        jornadasItems = jornadas.map((j) => ({
          id: `ev_${j.id}`,
          usuario_id: usuarioId,
          tipo: 'SISTEMA',
          titulo: `Jornada: ${j.titulo}`,
          mensaje: `${j.tipo ? '[' + j.tipo + '] ' : ''}${j.descripcion || 'Atención y prevención en tu barrio'}. Fecha: ${j.fecha_evento || 'Vigente'} · Lugar: ${j.ubicacion || 'Managua'}`,
          fecha_creacion: j.fecha_evento || new Date().toISOString(),
          fecha_lectura: null,
          leida: false,
          datos_adicionales: { evento_id: j.id, subtipo: 'JORNADA' }
        }));
      }
    } catch (_) {}

    // Notificaciones directas
    const directos = (directNotifs || []).map((n) => ({
      ...n,
      leida: Boolean(n.fecha_lectura || n.leida)
    }));

    // Deduplicar recordatorios que ya tengan notificación directa
    const idsDirectosReminder = new Set(
      directos.map((d) => d.datos_adicionales?.reminder_id).filter(Boolean)
    );
    const remindersFiltrados = reminderItems.filter(
      (r) => !idsDirectosReminder.has(r.datos_adicionales?.reminder_id)
    );

    let todos = [
      ...directos,
      ...remindersFiltrados,
      ...brotesItems,
      ...alertasItems,
      ...pautasItems,
      ...jornadasItems
    ];

    if (soloNoLeidas) {
      todos = todos.filter((n) => !n.leida);
    }

    // Ordenar cronológicamente descendente
    todos.sort((a, b) => new Date(b.fecha_creacion || 0).getTime() - new Date(a.fecha_creacion || 0).getTime());

    const total = todos.length;
    const paginados = todos.slice(offset, offset + limit);
    const noLeidas = todos.filter((n) => !n.leida).length;

    return {
      notificaciones: paginados,
      total,
      no_leidas: noLeidas
    };
  } catch (err) {
    console.error('[Notifications] Error al consultar notificaciones en Supabase:', err.message);
  }

  // Fallback seguro sin semillas falsas
  return {
    notificaciones: [],
    total: 0,
    no_leidas: 0
  };
};

const markAsRead = async (usuarioId, notificacionId) => {
  try {
    const { data, error } = await notificationsRepo.marcarLeida(usuarioId, notificacionId);
    if (!error && data) {
      return { ...data, leida: true };
    }
  } catch (_) {}
  return { id: notificacionId, leida: true, fecha_lectura: new Date().toISOString() };
};

const markAllAsRead = async (usuarioId) => {
  try {
    await notificationsRepo.marcarTodasLeidas(usuarioId);
  } catch (_) {}
  return { success: true };
};

module.exports = {
  notificar,
  notificarAlertaReporte,
  notificarJornadaSalud,
  notificarPautaMinsa,
  notificarAlertaSanitaria,
  enviarPushDirecto,
  obtenerTokensActivos,
  getNotifications,
  markAsRead,
  markAllAsRead,
  TIPOS_NOTIFICACION
};
