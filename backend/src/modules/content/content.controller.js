const contentService = require('./content.service');
const asyncHandler = require('../../utils/asyncHandler');

const getHealthContent = asyncHandler(async (req, res) => {
  const { categoria, fuente, limit, offset } = req.query;
  const data = await contentService.getPublishedContent({
    categoria,
    fuente,
    limit: limit ? parseInt(limit, 10) : 20,
    offset: offset ? parseInt(offset, 10) : 0
  });
  return res.status(200).json(data);
});

const getHealthContentDetails = asyncHandler(async (req, res) => {
  const data = await contentService.getContentById(req.params.id);
  return res.status(200).json(data);
});

const ingestContent = asyncHandler(async (req, res) => {
  const data = await contentService.ingestOfficialContent(req.body, req.usuarioId || null);
  return res.status(201).json(data);
});

module.exports = {
  getHealthContent,
  getHealthContentDetails,
  ingestContent
};
