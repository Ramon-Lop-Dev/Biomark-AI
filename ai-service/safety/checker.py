"""Reglas deterministas de seguridad clínica para entrada y salida."""

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

PATRONES_CRITICOS = [
    r"dolor.{0,30}(pecho|torác|brazo izquierdo)",
    r"(no quiero vivir|quitarme la vida|suicid)",
    r"(dificultad|falta) para respirar",
    r"(desmayo|inconsciente|convulsion)",
    r"(cara|brazo).{0,20}(caíd|débil|adormec)",
]

PATRONES_ALTOS = [
    r"(sangrado|fiebre).{0,25}(intens|alta|mucho)",
    r"(embaraz|bebé).{0,30}(dolor|sangrado)",
]

MENSAJE_URGENCIA = (
    "Los síntomas que describes pueden requerir atención urgente. "
    "Llama al servicio de emergencias local o acude ahora al centro de salud más cercano."
)


def safety_layer_check(mensaje: str) -> bool:
    """Retorna True si el mensaje del usuario debe bloquearse."""
    mensaje_lower = mensaje.lower()
    return any(palabra in mensaje_lower for palabra in PALABRAS_PROHIBIDAS)


def clasificar_riesgo(mensaje: str) -> str:
    texto = mensaje.lower()
    if any(re.search(patron, texto) for patron in PATRONES_CRITICOS):
        return "CRITICAL"
    if any(re.search(patron, texto) for patron in PATRONES_ALTOS):
        return "HIGH"
    return "LOW"


def validar_respuesta(respuesta: str, riesgo: str) -> str:
    """Evita que una salida del modelo parezca diagnóstico o prescripción."""
    respuesta_limpia = respuesta.strip()
    absolutos = re.compile(r"\b(tienes|padeces|es definitivo|sin duda)\b", re.IGNORECASE)
    if absolutos.search(respuesta_limpia):
        respuesta_limpia = "La información no permite confirmar un diagnóstico. " + respuesta_limpia
    if riesgo in {"HIGH", "CRITICAL"} and "atención" not in respuesta_limpia.lower():
        respuesta_limpia = f"{respuesta_limpia}\n\n{MENSAJE_URGENCIA}"
    return respuesta_limpia
