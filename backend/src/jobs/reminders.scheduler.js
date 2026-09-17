// Scheduler periódico para procesar y disparar recordatorios vencidos hacia n8n.
const cron = require('node-cron');
const remindersService = require('../modules/reminders/reminders.service');

const iniciarSchedulerRecordatorios = () => {
  cron.schedule('* * * * *', async () => {
    try {
      await remindersService.processDueReminders();
    } catch (error) {
      console.error('[Reminders Scheduler] Error al procesar recordatorios:', error.message);
    }
  });

  console.log('[Reminders Scheduler] Iniciado — revisando recordatorios vencidos cada minuto');
};

module.exports = { iniciarSchedulerRecordatorios };
