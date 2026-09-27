const asyncHandler = require('../../utils/asyncHandler');
const invitationsService = require('./invitations.service');

const createHealthWorkerInvitation = asyncHandler(async (req, res) => {
  const adminId = req.usuarioId;
  const result = await invitationsService.inviteHealthWorker(adminId, req.body);
  return res.status(201).json({
    mensaje: 'Invitación para trabajador de salud generada exitosamente.',
    invitacion: result
  });
});

const createPromoterInvitation = asyncHandler(async (req, res) => {
  const workerId = req.usuarioId;
  const centroSaludId = req.body.centro_salud_id || req.centroSaludId || req.usuario?.centro_salud_id;
  const result = await invitationsService.invitePromoter(workerId, centroSaludId, req.body);
  return res.status(201).json({
    mensaje: 'Invitación para promotor comunitario generada exitosamente.',
    invitacion: result
  });
});

const verifyInvitation = asyncHandler(async (req, res) => {
  const { token } = req.params;
  const result = await invitationsService.verifyInvitation(token);
  return res.status(200).json(result);
});

const acceptInvitation = asyncHandler(async (req, res) => {
  const result = await invitationsService.acceptInvitation(req.body);
  return res.status(200).json(result);
});

const getMyPromoters = asyncHandler(async (req, res) => {
  const centroSaludId = req.scopeCentroSaludId || req.centroSaludId;
  if (!centroSaludId && req.usuarioRol !== 'ADMIN') {
    return res.status(403).json({ error: 'No tienes un centro de salud asignado.' });
  }
  const result = await invitationsService.listMyPromoters(centroSaludId);
  return res.status(200).json(result);
});

const updatePromoterStatus = asyncHandler(async (req, res) => {
  const workerId = req.usuarioId;
  const centroSaludId = req.scopeCentroSaludId || req.centroSaludId;
  const { id: promoterId } = req.params;
  const { estado } = req.body;
  const result = await invitationsService.updatePromoterStatus(workerId, centroSaludId, promoterId, estado);
  return res.status(200).json({
    mensaje: `Estado del promotor actualizado a ${estado}.`,
    promotor: result
  });
});

module.exports = {
  createHealthWorkerInvitation,
  createPromoterInvitation,
  verifyInvitation,
  acceptInvitation,
  getMyPromoters,
  updatePromoterStatus
};
