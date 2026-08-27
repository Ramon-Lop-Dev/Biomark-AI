const gisService = require('./gis.service');
const asyncHandler = require('../../utils/asyncHandler');

const getHealthCenters = asyncHandler(async (req, res) => {
    const data = await gisService.getHealthCenters();
    return res.status(200).json(data);
});

// req.query ya viene validado/coercido por validateQuery() con nearbySchema
// (latitude/longitude a number, radius_km con default 15 si no se mandó).
const getNearbyHealthCenters = asyncHandler(async (req, res) => {
    const { latitude, longitude, radius_km } = req.query;
    const data = await gisService.getNearbyHealthCenters(latitude, longitude, radius_km);
    return res.status(200).json(data);
});

module.exports = { getHealthCenters, getNearbyHealthCenters };