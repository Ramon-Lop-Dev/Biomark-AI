// Atiende consulta y actualización de consentimientos del usuario.
const asyncHandler = require('../../utils/asyncHandler');
const service = require('./consent.service');

const getConsentimientos = asyncHandler(async (req, res) => res.json(await service.listar(req.usuarioId)));
const putConsentimiento = asyncHandler(async (req, res) => {
  const data = await service.guardar(req.usuarioId, req.body.tipo_consentimiento, req.body.otorgado);
  return res.json(data);
});

module.exports = { getConsentimientos, putConsentimiento };