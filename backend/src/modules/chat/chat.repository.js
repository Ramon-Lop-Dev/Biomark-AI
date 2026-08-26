const axios = require('axios');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

const postChat = (message) => {
  asegurarConfiguracion();

  return axios.post(`${AI_SERVICE_URL}/chat`, { message }, {
    headers: {
      'X-Internal-Key': AI_SERVICE_INTERNAL_KEY,
      'Content-Type': 'application/json'
    },
    timeout: 180000
  });
};

module.exports = { postChat };
