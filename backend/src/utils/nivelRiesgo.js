/**
 * Traduce el "risk_level" que devuelve el AI Service (en inglés: LOW,
 * MODERATE, HIGH — y potencialmente CRITICAL a futuro) al enum real de
 * Postgres "nivel_riesgo" (BAJO, MODERADO, ALTO, CRITICO), usado por
 * mensajes_chat.nivel_riesgo, alertas_epidemiologicas.nivel_alerta y
 * zonas_riesgo.nivel_riesgo_actual.
 *
 * Ver auditoría Fase 1, punto 5.3: hoy el AI Service (safety/checker.py +
 * inference/service.py) solo emite LOW/MODERATE/HIGH — nunca CRITICAL —
 * pero se incluye el mapeo igual por si el Safety Layer se refina más
 * adelante para emitirlo.
 *
 * Cualquier valor no reconocido cae a 'BAJO' con un warning en vez de
 * lanzar: un contrato inesperado del AI Service (típicamente por un
 * cambio ahí sin avisar) nunca debe tumbar la conversación del usuario
 * ni un INSERT por violar el CHECK del enum.
 */
const RISK_LEVEL_MAP = {
  LOW: 'BAJO',
  MODERATE: 'MODERADO',
  HIGH: 'ALTO',
  CRITICAL: 'CRITICO'
};

const mapearNivelRiesgo = (riskLevel) => {
  if (!riskLevel) return null;

  const mapeado = RISK_LEVEL_MAP[String(riskLevel).toUpperCase()];

  if (!mapeado) {
    console.warn(`[nivelRiesgo] Valor de risk_level no reconocido del AI Service: "${riskLevel}". Se usará BAJO por defecto.`);
    return 'BAJO';
  }

  return mapeado;
};

module.exports = { mapearNivelRiesgo, RISK_LEVEL_MAP };
