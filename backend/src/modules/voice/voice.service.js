const voiceRepo = require('./voice.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const transcribirYResponder = async (usuarioId, file, sessionId) => {
  if (!file) {
    throw new AppError("Se requiere un archivo de audio en el campo 'archivo'", 400);
  }

  try {
    const { data } = await voiceRepo.postVoice(file.buffer, file.originalname, file.mimetype);
    const { transcription, reply, risk_level, sources } = data;

    // Ver nota equivalente en chat.service.js: la persistencia real en
    // sesiones_chat/mensajes_chat queda para una fase posterior.
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'mensajes_chat',
      idEntidad: usuarioId,
      accion: 'MENSAJE_VOZ',
      detalle: { risk_level }
    });

    return {
      session_id: sessionId || 'sesion-activa',
      transcription,
      reply,
      risk_level,
      sources
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (voice):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de voz no está disponible temporalmente', status);
  }
};

const sintetizarVoz = async (text) => {
  try {
    const { data } = await voiceRepo.postSynthesize(text);
    return data; // audio binario (arraybuffer, se envía tal cual al cliente)
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (synthesize):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de síntesis de voz no está disponible temporalmente', status);
  }
};

module.exports = { transcribirYResponder, sintetizarVoz };
