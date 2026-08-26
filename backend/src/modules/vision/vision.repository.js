const axios = require('axios');
const FormData = require('form-data');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

const postVision = (fileBuffer, filename, mimetype, tipo) => {
  asegurarConfiguracion();

  const formData = new FormData();
  formData.append('archivo', fileBuffer, {
    filename: filename || 'imagen.jpg',
    contentType: mimetype || 'image/jpeg'
  });

  return axios.post(`${AI_SERVICE_URL}/vision`, formData, {
    params: { tipo }, // el ai-service espera 'tipo' como query param
    headers: { ...formData.getHeaders(), 'X-Internal-Key': AI_SERVICE_INTERNAL_KEY },
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
    timeout: 60000
  });
};

module.exports = { postVision };
