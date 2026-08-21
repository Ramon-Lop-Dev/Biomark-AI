const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

// Inicializar la aplicación Express
const app = express();

// 1. Middlewares de Seguridad Globales
app.use(helmet()); // Cabeceras HTTP seguras
app.use(cors());   // Habilitar CORS

// 2. Parseo de payloads
app.use(express.json()); 
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
// --- IMPORTAR RUTAS DE MÓDULOS ---
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const medicalRoutes = require('./modules/medical/medical.routes');
const symptomsRoutes = require('./modules/symptoms/symptoms.routes');
const vaccinesRoutes = require('./modules/vaccines/vaccines.routes');
const remindersRoutes = require('./modules/reminders/reminders.routes');
// --- APLICAR RUTAS ---
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/medical-history', medicalRoutes);
app.use('/api/symptoms', symptomsRoutes);
app.use('/api/vaccines', vaccinesRoutes);
app.use('/api/reminders', remindersRoutes);
module.exports = app;