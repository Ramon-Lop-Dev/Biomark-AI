const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createRecommendationSchema,
  updateRecommendationSchema,
  COLOR_POR_CATEGORIA,
  ICONO_POR_CATEGORIA
} = require('../src/modules/recommendations/recommendations.validator');
const recommendationsRepo = require('../src/modules/recommendations/recommendations.repository');

test('Validador: Asigna color e icono normativo MINSA según la categoría', () => {
  const input = {
    categoria: 'dengue',
    titulo: 'Control Comunitario del Zancudo',
    resumen: 'Eliminación activa de criaderos de zancudos en recipientes.',
    detalle_clinico: 'Pautas de prevención del MINSA ante la época lluviosa en Nicaragua.',
    normativa_minsa: 'Normativa 004 MINSA',
    etiqueta: 'Salud Vectorial',
    puntos_clave: ['Cepillar pilas dos veces por semana.', 'Permitir abate/BTI.']
  };

  const parsed = createRecommendationSchema.parse(input);
  assert.equal(parsed.color_hex, COLOR_POR_CATEGORIA.dengue);
  assert.equal(parsed.icono, ICONO_POR_CATEGORIA.dengue);
  assert.equal(parsed.color_hex, '#EF4444');
  assert.equal(parsed.estado, 'PUBLICADO');
});

test('Validador: Rechaza recomendaciones sin normativa MINSA obligatoria', () => {
  const input = {
    categoria: 'cardiovascular',
    titulo: 'Chequeo de Presión',
    resumen: 'Medición regular de presión arterial.',
    detalle_clinico: 'Detalles clínicos de monitoreo de presión arterial en adultos.',
    normativa_minsa: '', // Inválida por estar vacía
    etiqueta: 'Cardiovascular',
    puntos_clave: ['Monitorear al menos una vez al mes.']
  };

  const result = createRecommendationSchema.safeParse(input);
  assert.equal(result.success, false);
});

test('Validador: Rechaza categorías no sanitarias o desconocidas', () => {
  const input = {
    categoria: 'categoria_falsa',
    titulo: 'Pauta no médica',
    resumen: 'Resumen descriptivo de prueba médica.',
    detalle_clinico: 'Detalle clínico de prueba médica para validación.',
    normativa_minsa: 'Normativa 001 MINSA',
    etiqueta: 'General',
    puntos_clave: ['Punto 1']
  };

  const result = createRecommendationSchema.safeParse(input);
  assert.equal(result.success, false);
});

test('Repositorio: Devuelve catálogo oficial de semillas MINSA como fallback seguro', async () => {
  const { data, error } = await recommendationsRepo.listarRecomendaciones();
  assert.equal(error, null);
  assert.ok(Array.isArray(data));
  assert.ok(data.length >= 6);

  const dengue = data.find((r) => r.categoria === 'dengue');
  assert.ok(dengue);
  assert.equal(dengue.color_hex, '#EF4444');
  assert.ok(dengue.normativa_minsa.includes('Normativa 004 MINSA'));

  const cardio = data.find((r) => r.categoria === 'cardiovascular');
  assert.ok(cardio);
  assert.equal(cardio.color_hex, '#E11D48');
});
