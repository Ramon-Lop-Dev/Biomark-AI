const axios = require('axios');
const FormData = require('form-data');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

const postVoice = (fileBuffer, filename, mimetype) => {
  asegurarConfiguracion();

  const formData = new FormData();
  formData.append('archivo', fileBuffer, {
    filename: filename || 'audio.wav',
    contentType: mimetype || 'audio/wav'
  });

  return axios.post(`${AI_SERVICE_URL}/voice`, formData, {
    headers: { ...formData.getHeaders(), 'X-Internal-Key': AI_SERVICE_INTERNAL_KEY },
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
    timeout: 120000
  });
};

const postSynthesize = (text) => {
  asegurarConfiguracion();

  return axios.post(`${AI_SERVICE_URL}/audio/synthesize`, { text }, {
    headers: {
      'X-Internal-Key': AI_SERVICE_INTERNAL_KEY,
      'Content-Type': 'application/json'
    },
    responseType: 'arraybuffer',
    timeout: 60000
  });
};

module.exports = { postVoice, postSynthesize };
