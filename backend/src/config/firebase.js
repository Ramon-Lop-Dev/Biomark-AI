const admin = require('firebase-admin');

const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY || '';

if (!admin.apps.length && process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && rawPrivateKey) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: rawPrivateKey.replace(/\\n/g, '\n'),
    }),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
} else if (!admin.apps.length) {
  console.warn('[Firebase] Credenciales FCM no configuradas. Se omite inicialización de Firebase Admin.');
}

module.exports = admin;