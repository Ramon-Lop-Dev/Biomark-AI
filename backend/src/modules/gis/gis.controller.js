const gisService = require('./gis.service');
const asyncHandler = require('../../utils/asyncHandler');

const getHealthCenters = asyncHandler(async (req, res) => {
    const data = await gisService.getHealthCenters();
    return res.status(200).json(data);
});

module.exports = { getHealthCenters };
