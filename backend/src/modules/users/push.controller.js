// Atiende el alta y baja autenticada de dispositivos push.
const asyncHandler = require('../../utils/asyncHandler');
const service = require('./push.service');

const registerToken = asyncHandler(async (req, res) => res.status(201).json(await service.registrar(req.usuarioId, req.body)));
const deleteToken = asyncHandler(async (req, res) => {
  await service.eliminar(req.usuarioId, req.body.fcm_token);
  return res.status(204).send();
});

module.exports = { registerToken, deleteToken };