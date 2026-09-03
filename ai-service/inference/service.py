"""
Servicio clínico central de Biomark AI.

Las tres vías de entrada del sistema — texto directo (/chat), audio
transcrito (/voice) y hallazgo visual (/vision) — deben pasar exactamente
por el mismo Safety Layer + RAG + generación de texto. Este módulo es ese
punto único, para que main.py no repita la misma lógica tres veces.
"""

from typing import List, Tuple

from safety.checker import (
    MENSAJE_BLOQUEO,
    MENSAJE_URGENCIA,
    clasificar_riesgo,
    safety_layer_check,
    validar_respuesta,
)
from rag.retriever import RagRetriever
from inference.generator import TextGenerator


class ClinicalService:
    def __init__(self, retriever: RagRetriever, generator: TextGenerator):
        self.retriever = retriever
        self.generator = generator

    def responder(self, mensaje_usuario: str, medical_context=None, conversation_history=None) -> Tuple[str, str, List[str]]:
        """Retorna (respuesta, risk_level, fuentes) para cualquier mensaje
        de texto, sin importar si el mensaje se originó como texto, como
        transcripción de audio, o como descripción de un hallazgo visual."""
        if safety_layer_check(mensaje_usuario):
            return MENSAJE_BLOQUEO, "HIGH", ["Safety Layer Policy"]

        riesgo_detectado = clasificar_riesgo(mensaje_usuario)
        if riesgo_detectado == "CRITICAL":
            return MENSAJE_URGENCIA, "CRITICAL", ["Clinical Safety Policy"]

        contexto, fuentes = self.retriever.buscar_contexto_relevante(mensaje_usuario)
        respuesta = self.generator.generate_response(
            mensaje_usuario,
            contexto,
            medical_context,
            conversation_history,
        )

        risk_level = riesgo_detectado
        if risk_level == "LOW" and contexto:
            risk_level = "MODERATE"
        if risk_level == "LOW":
            fuentes = ["Conocimiento general del modelo"]

        return validar_respuesta(respuesta, risk_level), risk_level, fuentes

    def sugerir_accion(self, mensaje_usuario: str):
        """Sugiere una siguiente acción no destructiva para que el cliente
        pueda pedir confirmación antes de escribir datos del usuario.

        No diagnostica ni crea recordatorios: solo clasifica la intención
        explícita del mensaje y devuelve None cuando no es suficientemente
        clara.
        """
        texto = mensaje_usuario.lower()
        if any(term in texto for term in ("mejoré", "mejore", "estoy mejor", "empeoré", "empeore", "sigo igual")):
            return "REGISTER_PROGRESS"
        if any(term in texto for term in ("recordatorio", "cita médica", "cita medica", "que me recuerdes")):
            return "REGISTER_REMINDER"
        if any(term in texto for term in ("centro de salud", "hospital", "clínica", "clinica", "dónde atenderme", "donde atenderme")):
            return "SHOW_NEAREST_CENTER"
        if any(term in texto for term in ("estoy tomando", "me recetaron", "medicamento", "pastilla", "medicina")):
            return "REGISTER_MEDICATION"
        return None
