// Configura la aplicación Express, seguridad global y rutas del backend.
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

// Inicializar la aplicación Express
const app = express();

// 1. Middlewares de Seguridad Globales
app.use(helmet()); // Cabeceras HTTP seguras
const allowedOrigins = (process.env.CORS_ORIGINS || '').split(',').map((origin) => origin.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : false }));

// 2. Parseo de payloads
app.use(express.json({ limit: '256kb' }));
app.use(express.urlencoded({ extended: true }));

// 3. Rate Limiting (Mitigar abuso y ataques de fuerza bruta)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100, // Límite de 100 peticiones por IP
    message: { error: "Demasiadas peticiones, intente más tarde.", code: "429" }
});
app.use(limiter);

// 4. Ruta de Healthcheck (Verificación de disponibilidad general del sistema)
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', message: 'BIOMARK AI Backend up and running' });
});
app.get('/ready', async (req, res) => {
    const supabase = require('./config/supabase');
    const aiServiceUrl = process.env.AI_SERVICE_URL;
    const { error } = await supabase.from('usuarios').select('id').limit(1);
    const ready = !error && Boolean(aiServiceUrl);
    return res.status(ready ? 200 : 503).json({ status: ready ? 'ready' : 'not_ready', supabase: !error, ai_service_configured: Boolean(aiServiceUrl) });
});
// --- IMPORTAR RUTAS DE MÓDULOS ---
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const medicalRoutes = require('./modules/medical/medical.routes');
const symptomsRoutes = require('./modules/symptoms/symptoms.routes');
const vaccinesRoutes = require('./modules/vaccines/vaccines.routes');
const remindersRoutes = require('./modules/reminders/reminders.routes');
const communityRoutes = require('./modules/community/community.routes');
const gisRoutes = require('./modules/gis/gis.routes');
const epidemiologyRoutes=require('./modules/epidemiology/epidemiology.routes')
const chatRoutes = require('./modules/chat/chat.routes');
const voiceRoutes = require('./modules/voice/voice.routes');
const visionRoutes = require('./modules/vision/vision.routes');
const progressRoutes = require('./modules/progress/progress.routes');
const goalsRoutes = require('./modules/progress/goals.routes');
const navigationRoutes = require('./modules/gis/navigation.routes');
const { markReminderSent } = require('./modules/reminders/internal.controller');
const { verifyInternalWebhook } = require('./middleware/internalWebhook.middleware');
// --- APLICAR RUTAS ---
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/medical-history', medicalRoutes);
app.use('/api/symptoms', symptomsRoutes);
app.use('/api/vaccines', vaccinesRoutes);
app.use('/api/reminders', remindersRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/gis', gisRoutes);
app.use('/api/navigation', navigationRoutes);
app.use('/api/epidemiology', epidemiologyRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/voice', voiceRoutes);
app.use('/api/vision', visionRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/progress/goals', goalsRoutes);
app.patch('/internal/reminders/:id/sent', verifyInternalWebhook, markReminderSent);

// Ruta no encontrada (debe ir después de todas las rutas montadas)
app.use((req, res) => {
    res.status(404).json({ error: 'Ruta no encontrada', code: '404' });
});

// Manejador de errores centralizado — SIEMPRE al final, después de las rutas.
// A partir de aquí, cualquier next(error) de cualquier módulo termina aquí.
const errorHandler = require('./middleware/errorHandler.middleware');
app.use(errorHandler);

module.exports = app;