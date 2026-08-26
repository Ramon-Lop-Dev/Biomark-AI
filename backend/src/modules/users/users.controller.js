const usersService = require('./users.service');
const asyncHandler = require('../../utils/asyncHandler');

// GET /api/users/profile
const getProfile = asyncHandler(async (req, res) => {
    const data = await usersService.getProfile(req.usuarioId);
    return res.status(200).json(data);
});

module.exports = { getProfile };
