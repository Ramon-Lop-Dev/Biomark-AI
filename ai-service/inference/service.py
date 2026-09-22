"""
Servicio clínico central de Biomark AI.

Las tres vías de entrada del sistema — texto directo (/chat), audio
transcrito (/voice) y hallazgo visual (/vision) — deben pasar exactamente
por el mismo Safety Layer + RAG + generación de texto. Este módulo es ese
punto único, para que main.py no repita la misma lógica tres veces.
"""

import re
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

        texto = re.sub(r"[¿?¡!.,]", "", mensaje_usuario.strip().lower())
        saludos = {"hola", "buenas", "buenos dias", "buenos días", "buenas tardes", "buenas noches"}
        if texto in saludos:
            return (
                "Hola, soy Biomark AI. Puedo orientarte sobre tus síntomas, "
                "señales de alarma y el siguiente paso. ¿Qué estás sintiendo y desde cuándo?",
                "LOW",
                ["Biomark AI"],
            )

        contexto, fuentes = self.retriever.buscar_contexto_relevante(mensaje_usuario)
        try:
            respuesta = self.generator.generate_response(
                mensaje_usuario,
                contexto,
                medical_context,
                conversation_history,
            )
        except Exception as e:
            # Nunca dejar que un error de generación tumbe la petición con un
            # 500 crudo: eso el cliente lo termina viendo como una respuesta
            # rara o vacía. Se registra el error real y se devuelve un
            # mensaje seguro en su lugar.
            print(f"[ClinicalService] Error generando respuesta: {e}")
            respuesta = (
                "No logré generar una orientación clara para eso en este momento. "
                "¿Puedes reformular tu mensaje o describir el síntoma con más detalle?"
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
        terminos_evolucion = (
            "mejoré", "mejore", "estoy mejor", "me siento mejor", "ya no me duele",
            "empeoré", "empeore", "estoy peor", "me siento peor", "no mejoro", "sigo mal",
            "sigo igual", "estoy igual", "aún me duele", "aun me duele", "todavía tengo",
            "todavia tengo", "sigo con", "mejoría", "mejoria", "progreso",
            "evolución", "evolucion", "cómo voy", "como voy", "registrar síntoma",
            "registrar sintoma", "registrar síntomas", "registrar sintomas",
        )
        if any(term in texto for term in terminos_evolucion):
            return "REGISTER_PROGRESS"
        if any(term in texto for term in ("recordatorio", "cita médica", "cita medica", "que me recuerdes", "ponme una alarma", "crear recordatorio")):
            return "REGISTER_REMINDER"
        if any(term in texto for term in ("centro de salud", "hospital", "clínica", "clinica", "dónde atenderme", "donde atenderme", "urgencias")):
            return "SHOW_NEAREST_CENTER"
        if any(term in texto for term in ("estoy tomando", "me recetaron", "medicamento", "pastilla", "medicina", "registrar medicamento")):
            return "REGISTER_MEDICATION"
        return None

    def debe_recomendar_centro(self, mensaje_usuario: str, risk_level: str) -> bool:
        """Indica cuándo la respuesta debe ofrecer búsqueda por ubicación."""
        texto = mensaje_usuario.lower()
        sintomas = (
            "dolor", "fiebre", "tos", "garganta", "respirar", "respiración",
            "sangrado", "vomito", "vómito", "diarrea", "mareo", "desmayo",
            "embarazo", "convulsión", "convulsion", "herida", "erupción", "sarpullido",
        )
        solicita_centro = any(
            termino in texto
            for termino in ("centro de salud", "hospital", "clínica", "clinica", "donde atenderme", "dónde atenderme")
        )
        return risk_level in ("CRITICAL", "HIGH", "MODERATE") or solicita_centro or any(
            sintoma in texto for sintoma in sintomas
        )