// Atiende lectura y actualización del perfil del usuario.
const usersService = require('./users.service');
const asyncHandler = require('../../utils/asyncHandler');

// GET /api/users/profile
const getProfile = asyncHandler(async (req, res) => {
    const data = await usersService.getProfile(req.usuarioId);
    return res.status(200).json(data);
});

// PUT /api/users/profile
const updateProfile = asyncHandler(async (req, res) => {
    const data = await usersService.updateProfile(req.usuarioId, req.body);
    return res.status(200).json(data);
});

// POST /api/users/profile/photo
const updateProfilePhoto = asyncHandler(async (req, res) => {
    const data = await usersService.updateProfilePhoto(req.usuarioId, req.file);
    return res.status(200).json(data);
});

module.exports = { getProfile, updateProfile, updateProfilePhoto };
