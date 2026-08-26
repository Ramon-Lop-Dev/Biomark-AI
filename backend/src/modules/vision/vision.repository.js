const axios = require('axios');
const crypto = require('crypto');
const FormData = require('form-data');
const supabase = require('../../config/supabase');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

// Bucket de Supabase Storage donde se guardan las imágenes médicas
// analizadas. Se asume PRIVADO (no público) por tratarse de datos de
// salud: por eso se generan URLs firmadas (ver subirImagen) en vez de
// URLs públicas permanentes. Debe existir en el proyecto de Supabase con
// este nombre exacto antes de desplegar esta corrección; si el proyecto
// ya usa otro nombre de bucket, basta con cambiar esta constante.
const BUCKET_IMAGENES_MEDICAS = 'imagenes-medicas';

// Duración de la URL firmada. Es una solución temporal: al vencer, el
// registro en imagenes_medicas.url_imagen deja de ser accesible aunque el
// archivo siga existiendo en el bucket. Regenerar URLs firmadas bajo
// demanda (en vez de guardar una fija) queda fuera de esta corrección.
const SEGUNDOS_VALIDEZ_URL_FIRMADA = 60 * 60 * 24 * 30; // 30 días

const postVision = (fileBuffer, filename, mimetype, tipo) => {
  asegurarConfiguracion();

  const formData = new FormData();
  formData.append('archivo', fileBuffer, {
    filename: filename || 'imagen.jpg',
    contentType: mimetype || 'image/jpeg'
  });

  return axios.post(`${AI_SERVICE_URL}/vision`, formData, {
    params: { tipo }, // el ai-service espera 'tipo' como query param
    headers: { ...formData.getHeaders(), 'X-Internal-Key': AI_SERVICE_INTERNAL_KEY },
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
    timeout: 60000
  });
};

// --- persistencia clínica (eventos_medicos + imagenes_medicas) ---

// Sube el archivo a Storage y devuelve una URL firmada para guardar en
// imagenes_medicas.url_imagen (NOT NULL en el schema). La ruta incluye
// usuario_id como prefijo para que las imágenes de cada usuario queden
// agrupadas y no colisionen entre sí.
const subirImagen = async (usuarioId, fileBuffer, filename, mimetype) => {
  const extension = (filename && filename.includes('.')) ? filename.split('.').pop() : 'jpg';
  const ruta = `${usuarioId}/${crypto.randomUUID()}.${extension}`;

  const { error: errorSubida } = await supabase.storage
    .from(BUCKET_IMAGENES_MEDICAS)
    .upload(ruta, fileBuffer, { contentType: mimetype || 'image/jpeg', upsert: false });

  if (errorSubida) {
    return { url: null, error: errorSubida };
  }

  const { data: firmada, error: errorFirma } = await supabase.storage
    .from(BUCKET_IMAGENES_MEDICAS)
    .createSignedUrl(ruta, SEGUNDOS_VALIDEZ_URL_FIRMADA);

  if (errorFirma) {
    return { url: null, error: errorFirma };
  }

  return { url: firmada.signedUrl, error: null };
};

const crearEventoMedico = (usuarioId, descripcion) =>
  supabase
    .from('eventos_medicos')
    .insert({ usuario_id: usuarioId, tipo_evento: 'DIAGNOSTICO', descripcion })
    .select('id')
    .single();

const crearImagenMedica = (eventoMedicoId, { url_imagen, clasificacion, confianza }) =>
  supabase
    .from('imagenes_medicas')
    .insert({ evento_medico_id: eventoMedicoId, url_imagen, clasificacion, confianza })
    .select()
    .single();

module.exports = { postVision, subirImagen, crearEventoMedico, crearImagenMedica };
