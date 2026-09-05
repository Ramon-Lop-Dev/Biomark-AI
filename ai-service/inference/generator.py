import re
from typing import Optional

from config import DEVICE, PERSONA_BIOMARK

_MARCADORES_NUEVO_TURNO = [
    r"\n\s*Paciente\s*:",
    r"\n\s*USUARIO\s*:",
    r"\n\s*Asistente[^:]*:",
]


class TextGenerator:
    def __init__(self, model, tokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def _construir_prompt(
        self,
        mensaje_usuario: str,
        contexto_rag: Optional[str],
        medical_context=None,
        conversation_history=None,
    ) -> str:
        contexto_paciente = medical_context or "No hay contexto médico autorizado."
        historial = conversation_history or []
        turnos = "\n".join(
            f"{turno.get('emisor', 'USUARIO')}: {turno.get('mensaje', '')}"
            for turno in historial[-10:]
        ) or "Sin mensajes anteriores."
        referencia = contexto_rag or "No hay referencia clínica específica cargada."
        return (
            f"{PERSONA_BIOMARK}\n\n"
            "Reglas obligatorias: no inventes datos, no afirmes un diagnóstico, no prescribas "
            "ni indiques dosis. Distingue orientación de diagnóstico. Si faltan datos, haz "
            "preguntas concretas sobre duración, intensidad, edad, sexo y señales de alarma. "
            "Para un saludo responde cordialmente y pregunta qué síntoma o duda tiene la persona. "
            "Para síntomas, explica posibilidades de forma condicional, señales de alarma y "
            "el siguiente paso recomendado. Responde SOLO por el Asistente, en un único turno, "
            "y no continúes la conversación inventando nuevos mensajes del paciente.\n\n"
            f"Contexto médico autorizado del paciente: {contexto_paciente}\n\n"
            f"Historial reciente de conversación:\n{turnos}\n\n"
            f"Referencia clínica: {referencia}\n\n"
            f"Paciente: {mensaje_usuario}\n"
            "Asistente preventivo (responde en español claro y breve):"
        )

    def _cortar_en_siguiente_turno(self, texto: str) -> str:
        """Si el modelo sigue generando después de su respuesta y empieza a
        inventar un nuevo turno de conversación, cortamos ahí."""
        posiciones = []
        for patron in _MARCADORES_NUEVO_TURNO:
            m = re.search(patron, texto)
            if m:
                posiciones.append(m.start())
        if posiciones:
            texto = texto[:min(posiciones)]
        return texto.strip()

    def generate_response(
        self,
        mensaje_usuario: str,
        contexto_rag: Optional[str],
        medical_context=None,
        conversation_history=None,
    ) -> str:
        if self.model is None or self.tokenizer is None:
            contexto_preview = contexto_rag[:200] if contexto_rag else "ninguno"
            return f"Modo de respaldo (modelo no disponible en memoria). Contexto encontrado: {contexto_preview}"

        prompt = self._construir_prompt(
            mensaje_usuario,
            contexto_rag,
            medical_context,
            conversation_history,
        )
        inputs = self.tokenizer(prompt, return_tensors="pt").to(DEVICE)
        input_len = inputs["input_ids"].shape[-1]

        outputs = self.model.generate(
            **inputs,
            max_new_tokens=256,
            temperature=0.7,
            do_sample=True,
            pad_token_id=self.tokenizer.eos_token_id,
        )

        # Solo decodifica los tokens NUEVOS (no re-decodifica el prompt
        # completo para luego intentar borrarlo con .replace() de texto,
        # que fallaba cuando la re-decodificación no calzaba byte a byte
        # con el prompt original).
        tokens_generados = outputs[0][input_len:]
        respuesta = self.tokenizer.decode(tokens_generados, skip_special_tokens=True).strip()

        respuesta = self._cortar_en_siguiente_turno(respuesta)

        if not respuesta:
            return "No logré generar una respuesta clara para eso. ¿Puedes reformular tu pregunta o dar más detalle?"

        return respuesta