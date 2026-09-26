const test = require('node:test');
const assert = require('node:assert/strict');

// Proveer variables de entorno mínimas para carga de módulos
process.env.SUPABASE_URL = process.env.SUPABASE_URL || 'https://dummy.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'dummy_service_role_key';
process.env.SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'dummy_anon_key';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'dummy_jwt_secret';

test('App y todos los módulos de rutas cargan sin errores de sintaxis ni de dependencias', () => {
  assert.doesNotThrow(() => {
    require('../src/modules/content/content.routes');
    require('../src/modules/medical/medical.routes');
    require('../src/modules/auth/auth.routes');
    require('../src/modules/community/community.routes');
    require('../src/modules/recommendations/recommendations.routes');
    require('../src/modules/gis/gis.routes');
    require('../src/modules/reminders/reminders.routes');
    require('../src/modules/notifications/notifications.routes');
    require('../src/app');
  });
});
