"""Capa de seguridad clínica: bloquea consultas que piden prescripciones
o diagnósticos definitivos, que Biomark AI no debe emitir."""

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


def safety_layer_check(mensaje: str) -> bool:
    """Retorna True si el mensaje del usuario debe bloquearse."""
    mensaje_lower = mensaje.lower()
    return any(palabra in mensaje_lower for palabra in PALABRAS_PROHIBIDAS)
