const notificationsRepo = require('./notifications.repository');
const AppError = require('../../utils/AppError');
const supabase = require('../../config/supabase');
const admin = require('../../config/firebase');
const { N8N_WEBHOOK_URL, publicarEvento } = require('../../config/n8nClient');

const TIPOS_NOTIFICACION = ['RECORDATORIO', 'ALERTA_EPIDEMIOLOGICA', 'SISTEMA'];

/**
 * Convierte una fecha ISO a un formato humano en español con hora amigable.
 * Ejemplo: "28 Sep, 08:30 AM" o "1 Oct, 02:00 PM"
 */
const formatearFechaHumana = (fechaIso) => {
  if (!fechaIso) return 'Fecha por confirmar';
  const dt = new Date(fechaIso);
  if (isNaN(dt.getTime())) return fechaIso;
  const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  const h = dt.getHours();
  const period = h >= 12 ? 'PM' : 'AM';
  const hour12 = h % 12 === 0 ? 12 : h % 12;
  const min = String(dt.getMinutes()).padStart(2, '0');
  return `${dt.getDate()} ${meses[dt.getMonth()]}, ${String(hour12).padStart(2, '0')}:${min} ${period}`;
};

/**
 * Formatea el contenido de notificación para una jornada comunitaria.
 */
const formatearNotifJornada = (evento) => {
  const tipoUpper = (evento.tipo || '').toUpperCase();
  let emoji = '📅';
  let categoriaTxt = 'Jornada Comunitaria de Salud';
  let recomendacion = 'Acude con tu cédula o documento de identidad.';

  if (tipoUpper.includes('VACUN')) {
    emoji = '💉';
    categoriaTxt = 'Jornada de Vacunación Comunitaria';
    recomendacion = 'Lleva tu tarjeta de vacunación y tu cédula.';
  } else if (tipoUpper.includes('FUMIG') || tipoUpper.includes('ABATIZ')) {
    emoji = '🦟';
    categoriaTxt = 'Jornada de Fumigación y Control de Vectores';
    recomendacion = 'Facilita el ingreso a los brigadistas del MINSA para proteger tu hogar contra el dengue.';
  } else if (tipoUpper.includes('CONSULTA') || tipoUpper.includes('CLINICA')) {
    emoji = '🩺';
    categoriaTxt = 'Clínica Móvil y Atención Médica Gratuita';
    recomendacion = 'Consulta médica general y entrega de medicamentos sin costo.';
  } else if (tipoUpper.includes('DENGUE')) {
    emoji = '🛡️';
    categoriaTxt = 'Campaña de Prevención contra el Dengue';
    recomendacion = 'Aprende a eliminar criaderos de mosquitos en tu vivienda.';
  }

  const titulo = `${emoji} ${categoriaTxt}: ${evento.titulo || 'Actividad MINSA'}`;
  const fechaStr = formatearFechaHumana(evento.fecha_evento);
  const lugarStr = evento.ubicacion || 'Sector asignado Managua';
  const descStr = evento.descripcion ? `${evento.descripcion}. ` : '';

  const mensaje = `${descStr}Horario: ${fechaStr} · Lugar: ${lugarStr}. ${recomendacion}`.trim();

  return { titulo, mensaje };
};

/**
 * Formatea el contenido de notificación para un brote o reporte epidémico validado.
 */
const formatearNotifBrote = (reporte) => {
  const enf = reporte.tipo_enfermedad || 'Enfermedad Vigilada';
  const sector = reporte.direccion_exacta || 'tu sector comunitario';
  const titulo = `🚨 Alerta Epidemiológica: Brote de ${enf}`;
  const desc = reporte.descripcion ? `${reporte.descripcion}. ` : '';

  const mensaje = `${desc}Personal de salud MINSA ha confirmado un caso en ${sector}. Medidas urgentes: elimina depósitos con agua estancada, usa repelente y acude al centro de salud de inmediato ante fiebre, dolor de cabeza o malestar general.`;

  return { titulo, mensaje };
};

/**
 * Formatea el contenido de notificación para una pauta o recomendación oficial MINSA.
 */
const formatearNotifPauta = (rec) => {
  const titulo = `📋 Directriz Oficial MINSA: ${rec.titulo}`;
  const resumen = rec.resumen || rec.detalle_clinico || 'Medidas sanitarias preventivas para tu comunidad.';
  const normativa = rec.normativa_minsa ? ` (${rec.normativa_minsa})` : '';

  const mensaje = `${resumen}${normativa}. Aplica estas recomendaciones en tu hogar para resguardar la salud familiar.`;

  return { titulo, mensaje };
};

/**
 * Formatea el contenido de notificación para una alerta sanitaria general.
 */
const formatearNotifAlertaSanitaria = (alerta) => {
  const nivel = (alerta.nivel_alerta || 'PREVENTIVA').toUpperCase();
  const titulo = `⚠️ Aviso Sanitario MINSA: Nivel ${nivel}`;
  const mensaje = `${alerta.mensaje || 'Vigilancia epidemiológica intensificada en la región'}. Revisa las medidas preventivas en la app y sigue las indicaciones sanitarias.`;

  return { titulo, mensaje };
};

/**
 * Verifica si una entidad (evento, reporte, pauta, alerta) ya fue notificada previamente.
 * Esto garantiza que una jornada o brote se notifique exactamente una vez (Idempotencia).
 */
const yaNotificado = async (entidadId) => {
  if (!entidadId) return false;
  try {
    const { data, error } = await supabase
      .from('notificaciones')
      .select('id')
      .filter('datos_adicionales->>entidad_id', 'eq', String(entidadId))
      .limit(1);

    if (error || !data) return false;
    return data.length > 0;
  } catch (err) {
    console.warn('[Notifications] Error al verificar deduplicación:', err.message);
    return false;
  }
};

/**
 * Obtiene todos los IDs de usuarios activos en la plataforma para poblar sus bandejas de entrada.
 */
const obtenerTodosUsuariosIds = async () => {
  try {
    const { data, error } = await supabase
      .from('usuarios')
      .select('id');
    if (error || !data) return [];
    return data.map((u) => u.id).filter(Boolean);
  } catch (err) {
    console.error('[Notifications] Error al obtener usuarios para bandeja:', err.message);
    return [];
  }
};

/**
 * Registra una notificación en la base de datos para todos los usuarios activos.
 * Esto asegura que aparezca permanentemente en la Bandeja de Entrada in-app con un ID UUID real.
 */
const registrarNotificacionParaUsuarios = async ({ tipo, titulo, mensaje, datosAdicionales = {} }) => {
  // Aislamiento: no insertar notificaciones de prueba en entorno test
  if (process.env.NODE_ENV === 'test') return;

  try {
    const usuarioIds = await obtenerTodosUsuariosIds();
    if (usuarioIds.length === 0) return;

    const ahora = new Date().toISOString();
    const filas = usuarioIds.map((uid) => ({
      usuario_id: uid,
      tipo,
      titulo,
      mensaje,
      datos_adicionales: datosAdicionales,
      leida: false,
      fecha_creacion: ahora
    }));

    const { error } = await supabase.from('notificaciones').insert(filas);
    if (error) {
      console.warn('[Notifications] Nota al registrar en bandeja de usuarios:', error.message);
    }
  } catch (err) {
    console.error('[Notifications] Error al registrar notificación masiva:', err.message);
  }
};

/**
 * Envía notificaciones Push directas a través de Firebase Cloud Messaging (FCM).
 * Aislado estrictamente durante pruebas unitarias (NODE_ENV=test).
 */
const enviarPushDirecto = async ({ tokens = [], titulo, mensaje, datosAdicionales = {} }) => {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0 };

  // Aislamiento: nunca enviar Push a dispositivos reales en modo test
  if (process.env.NODE_ENV === 'test') {
    return { successCount: tokens.length, failureCount: 0, simulated: true };
  }

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

    // Si hay tokens obsoletos, desactivarlos en segundo plano
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
 * Crea una notificación directa dirigida a un usuario específico (ej. recordatorios de medicación).
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
 * Disparado estrictamente al momento de validación del reporte.
 */
const notificarAlertaReporte = async (reporte) => {
  // Deduplicación: no re-notificar si ya se emitió previamente
  if (await yaNotificado(reporte.id)) {
    console.log(`[Notifications] Brote/Reporte ${reporte.id} ya notificado previamente. Omitiendo duplicados.`);
    return;
  }

  const { titulo, mensaje } = formatearNotifBrote(reporte);
  const datosAdicionales = {
    entidad_id: String(reporte.id || ''),
    entidad_tipo: 'reporte_validado',
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    reporte_id: String(reporte.id || ''),
    clasificacion_ccm: reporte.clasificacion_ccm || 'AMARILLO',
    tipo_enfermedad: reporte.tipo_enfermedad || 'Enfermedad Vigilada',
    latitud: String(reporte.latitud || ''),
    longitud: String(reporte.longitud || '')
  };

  // 1. Guardar en la bandeja de entrada de todos los usuarios
  await registrarNotificacionParaUsuarios({
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    titulo,
    mensaje,
    datosAdicionales
  });

  // 2. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de alerta epidemiológica:', err.message);
  }

  // 3. Difusión en n8n si está configurado
  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('reporte_comunitario.validado', { reporte });
    } catch (_) {}
  }
};

/**
 * Notifica a la comunidad sobre una nueva jornada comunitaria (vacunación, fumigación, clínica móvil).
 * Disparado estrictamente al momento de creación de la jornada.
 */
const notificarJornadaSalud = async (evento) => {
  // Deduplicación: no re-notificar si ya se emitió previamente
  if (await yaNotificado(evento.id)) {
    console.log(`[Notifications] Jornada ${evento.id} ya notificada previamente. Omitiendo duplicados.`);
    return;
  }

  const { titulo, mensaje } = formatearNotifJornada(evento);
  const datosAdicionales = {
    entidad_id: String(evento.id || ''),
    entidad_tipo: 'evento_comunitario',
    tipo: 'SISTEMA',
    subtipo: 'JORNADA',
    evento_id: String(evento.id || ''),
    fecha_evento: String(evento.fecha_evento || ''),
    ubicacion: String(evento.ubicacion || '')
  };

  // 1. Guardar en la bandeja de entrada de todos los usuarios
  await registrarNotificacionParaUsuarios({
    tipo: 'SISTEMA',
    titulo,
    mensaje,
    datosAdicionales
  });

  // 2. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de jornada comunitaria:', err.message);
  }

  // 3. Difusión en n8n si está configurado
  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('evento_comunitario.creado', { evento_comunitario: evento });
    } catch (_) {}
  }
};

/**
 * Notifica a la comunidad sobre una nueva pauta, recomendación o aviso oficial del MINSA.
 * Disparado estrictamente al momento de creación de la recomendación.
 */
const notificarPautaMinsa = async (rec) => {
  // Deduplicación: no re-notificar si ya se emitió previamente
  if (await yaNotificado(rec.id)) {
    console.log(`[Notifications] Pauta MINSA ${rec.id} ya notificada previamente. Omitiendo duplicados.`);
    return;
  }

  const { titulo, mensaje } = formatearNotifPauta(rec);
  const datosAdicionales = {
    entidad_id: String(rec.id || ''),
    entidad_tipo: 'pauta_minsa',
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    subtipo: 'PAUTA_MINSA',
    recomendacion_id: String(rec.id || ''),
    categoria: String(rec.categoria || '')
  };

  // 1. Guardar en la bandeja de entrada de todos los usuarios
  await registrarNotificacionParaUsuarios({
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    titulo,
    mensaje,
    datosAdicionales
  });

  // 2. Envío push multicast a todos los dispositivos activos
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
 * Disparado estrictamente al momento de emisión de la alerta.
 */
const notificarAlertaSanitaria = async (alerta) => {
  // Deduplicación: no re-notificar si ya se emitió previamente
  if (await yaNotificado(alerta.id)) {
    console.log(`[Notifications] Alerta sanitaria ${alerta.id} ya notificada previamente. Omitiendo duplicados.`);
    return;
  }

  const { titulo, mensaje } = formatearNotifAlertaSanitaria(alerta);
  const datosAdicionales = {
    entidad_id: String(alerta.id || ''),
    entidad_tipo: 'alerta_sanitaria',
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    alerta_id: String(alerta.id || ''),
    nivel_alerta: String(alerta.nivel_alerta || '')
  };

  // 1. Guardar en la bandeja de entrada de todos los usuarios
  await registrarNotificacionParaUsuarios({
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    titulo,
    mensaje,
    datosAdicionales
  });

  // 2. Envío push multicast a todos los dispositivos activos
  try {
    const tokens = await obtenerTokensActivos();
    if (tokens.length > 0) {
      await enviarPushDirecto({ tokens, titulo, mensaje, datosAdicionales });
    }
  } catch (err) {
    console.warn('[Notifications] Error al emitir push de alerta sanitaria:', err.message);
  }

  // 3. Difusión en n8n si está configurado
  if (N8N_WEBHOOK_URL) {
    try {
      await publicarEvento('alerta.epidemiologica.creada', { alerta });
    } catch (_) {}
  }
};

/**
 * Sincroniza eventos sanitarios activos en la bandeja del usuario si aún no los tiene registrados.
 * Solo inserta registros faltantes una única vez sin emitir push notificaciones.
 */
const sincronizarBandejaUsuario = async (usuarioId) => {
  if (!usuarioId || process.env.NODE_ENV === 'test') return;
  try {
    const ahora = new Date().toISOString();

    // Consultar eventos vigentes
    const { data: eventos } = await supabase
      .from('eventos_comunitarios')
      .select('id, titulo, descripcion, tipo, fecha_evento, ubicacion')
      .or(`fecha_fin.gte.${ahora},and(fecha_fin.is.null,fecha_evento.gte.${ahora})`)
      .order('fecha_evento', { ascending: false })
      .limit(10);

    // Consultar qué avisos ya tiene este usuario
    const { data: existentes } = await supabase
      .from('notificaciones')
      .select('datos_adicionales')
      .eq('usuario_id', usuarioId);

    const idsExistentes = new Set(
      (existentes || [])
        .map((n) => n.datos_adicionales?.entidad_id || n.datos_adicionales?.evento_id)
        .filter(Boolean)
    );

    const filasNuevas = [];
    if (eventos && eventos.length > 0) {
      for (const ev of eventos) {
        if (!idsExistentes.has(String(ev.id))) {
          const { titulo, mensaje } = formatearNotifJornada(ev);
          filasNuevas.push({
            usuario_id: usuarioId,
            tipo: 'SISTEMA',
            titulo,
            mensaje,
            datos_adicionales: {
              entidad_id: String(ev.id),
              entidad_tipo: 'evento_comunitario',
              subtipo: 'JORNADA',
              evento_id: String(ev.id),
              fecha_evento: String(ev.fecha_evento || ''),
              ubicacion: String(ev.ubicacion || '')
            },
            leida: false,
            fecha_creacion: ev.fecha_evento || ahora
          });
        }
      }
    }

    if (filasNuevas.length > 0) {
      await supabase.from('notificaciones').insert(filasNuevas);
    }
  } catch (err) {
    console.warn('[Notifications] Nota al sincronizar bandeja del usuario:', err.message);
  }
};

/**
 * Consulta la bandeja de notificaciones in-app del usuario desde Supabase.
 * Lee registros reales persistidos en la tabla 'notificaciones', garantizando que
 * el estado 'leida: true/false' se conserve permanentemente y no se vuelva a generar.
 */
const getNotifications = async (usuarioId, { limit = 30, offset = 0, soloNoLeidas = false } = {}) => {
  try {
    // Sincronizar avisos comunitarios faltantes de manera idempotente
    await sincronizarBandejaUsuario(usuarioId);

    const [{ data, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
      notificationsRepo.listarPorUsuario(usuarioId, { limit, offset, soloNoLeidas }),
      notificationsRepo.contarNoLeidas(usuarioId)
    ]);

    if (error) {
      console.error('[Notifications] Error al listar notificaciones:', error.message);
    }

    const notificaciones = (data || []).map((n) => ({
      id: n.id,
      usuario_id: n.usuario_id,
      tipo: n.tipo,
      titulo: n.titulo || 'Notificación Biomark AI',
      mensaje: n.mensaje,
      fecha_creacion: n.fecha_creacion,
      fecha_lectura: n.fecha_lectura,
      leida: Boolean(n.leida || n.fecha_lectura),
      datos_adicionales: n.datos_adicionales || {}
    }));

    const total = count != null ? count : notificaciones.length;
    const noLeidas = unreadCount != null ? unreadCount : notificaciones.filter((n) => !n.leida).length;

    return {
      notificaciones,
      total,
      no_leidas: noLeidas
    };
  } catch (err) {
    console.error('[Notifications] Error inesperado en getNotifications:', err.message);
    return {
      notificaciones: [],
      total: 0,
      no_leidas: 0
    };
  }
};

/**
 * Marca una notificación como leída en Supabase de forma permanente.
 */
const markAsRead = async (usuarioId, notificacionId) => {
  try {
    const { data, error } = await notificationsRepo.marcarLeida(usuarioId, notificacionId);
    if (!error && data) {
      return { ...data, leida: true };
    }
  } catch (_) {}
  return { id: notificacionId, leida: true, fecha_lectura: new Date().toISOString() };
};

/**
 * Marca todas las notificaciones del usuario como leídas en Supabase de forma permanente.
 */
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
  formatearNotifJornada,
  formatearNotifBrote,
  formatearNotifPauta,
  formatearNotifAlertaSanitaria,
  TIPOS_NOTIFICACION
};
