// Atiende análisis de imágenes médicas y devuelve resultados de apoyo.
const visionService = require('./vision.service');
const asyncHandler = require('../../utils/asyncHandler');

/**
 * POST /api/vision?tipo=piel|garganta
 * Recibe una imagen (multipart/form-data, campo "archivo") y el tipo de
 * análisis, y lo reenvía al ai-service para clasificación visual.
 */
const analizarImagen = asyncHandler(async (req, res) => {
    // Acepta 'tipo' como query param o como campo del form-data
    const tipo = req.query.tipo || req.body.tipo;
    const resultado = await visionService.analizarImagen(req.usuarioId, req.file, tipo);
    return res.status(200).json(resultado);
});

module.exports = { analizarImagen };
