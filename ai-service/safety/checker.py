"""Capa determinista de seguridad clínica para todas las entradas del modelo."""

import re

PALABRAS_PROHIBIDAS = [
    "recétame",
    "dosis exacta",
    "pastillas para curar",
    "diagnóstico definitivo",
]

MENSAJE_BLOQUEO = (
    "Lo siento, como asistente preventivo no puedo emitir diagnósticos "
    "definitivos ni prescribir medicamentos. Le recomendamos acudir a su "
    "centro de salud más cercano."
)

MENSAJE_URGENCIA = (
    "Los síntomas que describes pueden requerir atención urgente. "
    "Llama a emergencias o acude ahora al hospital más cercano; no esperes "
    "a una respuesta de esta aplicación."
)

_CRITICOS = (
    "no puedo respirar", "me falta el aire", "dolor intenso en el pecho",
    "inconsciente", "convulsion", "convulsión", "sangrado abundante",
    "debilidad de un lado", "quiero suicidarme", "me quiero suicidar",
)
_ALTOS = (
    "desmayo", "sangrado", "dolor intenso", "fiebre alta", "embarazo",
    "vómitos persistentes", "vomitos persistentes", "confusión", "confusion",
)
_MODERADOS = (
    "dolor", "fiebre", "tos", "diarrea", "vómito", "vomito", "mareo",
    "sarpullido", "erupción", "erupcion", "ardor", "hinchado",
)


def safety_layer_check(mensaje: str) -> bool:
    """Retorna True si el mensaje del usuario debe bloquearse."""
    mensaje_lower = mensaje.lower()
    return any(palabra in mensaje_lower for palabra in PALABRAS_PROHIBIDAS)


def clasificar_riesgo(mensaje: str) -> str:
    """Clasifica señales de alarma sin depender del modelo generativo."""
    texto = re.sub(r"\s+", " ", mensaje.lower()).strip()
    if any(term in texto for term in _CRITICOS):
        return "CRITICAL"
    if any(term in texto for term in _ALTOS):
        return "HIGH"
    if any(term in texto for term in _MODERADOS):
        return "MODERATE"
    return "LOW"


def validar_respuesta(respuesta: str, risk_level: str) -> str:
    """Evita respuestas vacías o afirmaciones de diagnóstico definitivo."""
    texto = re.sub(r"\s+", " ", (respuesta or "")).strip()
    if not texto:
        texto = "No pude generar una orientación clara. Consulta a un profesional de salud."
    texto = re.sub(r"diagnóstico confirmado|tienes definitivamente|sin duda tienes", "posibilidad que debe confirmar un profesional", texto, flags=re.IGNORECASE)
    if risk_level in ("CRITICAL", "HIGH") and "urgente" not in texto.lower():
        texto = f"Busca atención médica urgente. {texto}"
    return texto[:3000]
