require('dotenv').config();
const app = require('./app');

// Definir el puerto desde las variables de entorno o usar 3000 por defecto
const PORT = process.env.PORT || 3000;

// Iniciar el servidor
app.listen(PORT, () => {
    console.log(`[Servidor] Ejecutándose en el entorno: ${process.env.NODE_ENV}`);
    console.log(`[Servidor] Escuchando en el puerto: ${PORT}`);
});