"""Capa determinista de seguridad clínica para todas las entradas del modelo."""

import re

PALABRAS_PROHIBIDAS = [
    "recétame",
    "recetame",
    "dosis exacta",
    "qué dosis",
    "que dosis",
    "cuánta dosis",
    "cuanta dosis",
    "cuántos mg",
    "cuantos mg",
    "pastillas para curar",
    "diagnóstico definitivo",
    "diagnostico definitivo",
    "prescríbeme",
    "prescribeme",
]

MENSAJE_BLOQUEO = (
    "Como asistente preventivo de salud, no puedo emitir diagnósticos "
    "definitivos ni recetar medicamentos o dosis específicas. Te recomiendo "
    "acudir a tu centro de salud más cercano para una valoración presencial."
)

MENSAJE_URGENCIA = (
    "Los síntomas que describes pueden requerir atención urgente. "
    "Llama a emergencias o acude de inmediato al hospital o centro de salud "
    "más cercano; no esperes una respuesta de esta aplicación."
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
    """Retorna True si el mensaje del usuario pide expresamente prescripción, dosis o diagnóstico definitivo."""
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
    """Evita respuestas vacías, afirmaciones de diagnóstico definitivo o prescripciones no autorizadas."""
    texto = re.sub(r"\s+", " ", (respuesta or "")).strip()
    if not texto:
        texto = (
            "Como asistente de salud preventiva, puedo orientarte sobre posibles "
            "causas y señales de alarma, pero te recomiendo consultar a un profesional "
            "de salud en tu centro más cercano."
        )

    # Neutralizar diagnósticos definitivos
    texto = re.sub(
        r"diagnóstico confirmado|tienes definitivamente|sin duda tienes|te diagnostico con",
        "posibilidad que debe confirmar un profesional de salud",
        texto,
        flags=re.IGNORECASE,
    )

    # Neutralizar prescripciones farmacológicas accidentales
    texto = re.sub(
        r"\b(?:toma|tomar|beber|ingiere|administra)\s+\d+\s*(?:mg|miligramos|ml|gotas)\b",
        "mantén medidas generales de cuidado e hidratación sin automedicarte",
        texto,
        flags=re.IGNORECASE,
    )

    if risk_level in ("CRITICAL", "HIGH") and "urgente" not in texto.lower():
        texto = f"Busca atención médica urgente en tu centro más cercano. {texto}"
    return texto[:3000]
