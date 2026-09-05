from typing import Optional

from config import DEVICE, PERSONA_BIOMARK


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
        """Arma el prompt final. Si hay contexto RAG relevante lo usa como
        referencia adicional; si no, deja que el modelo responda con su
        propio conocimiento médico (ya viene de su fine-tuning), pidiéndole
        cautela. En ambos casos se mantiene la identidad de Biomark AI."""
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
            "el siguiente paso recomendado.\n\n"
            f"Contexto médico autorizado del paciente: {contexto_paciente}\n\n"
            f"Historial reciente de conversación:\n{turnos}\n\n"
            f"Referencia clínica: {referencia}\n\n"
            f"Paciente: {mensaje_usuario}\n"
            "Asistente preventivo (responde en español claro y breve):"
        )

    def generate_response(
        self,
        mensaje_usuario: str,
        contexto_rag: Optional[str],
        medical_context=None,
        conversation_history=None,
    ) -> str:
        if self.model is None or self.tokenizer is None:
            # Bug corregido: antes referenciaba una variable inexistente
            # (contexto_encontrado) y esto tronaba con NameError.
            contexto_preview = contexto_rag[:200] if contexto_rag else "ninguno"
            return f"Modo de respaldo (modelo no disponible en memoria). Contexto encontrado: {contexto_preview}"

        prompt = self._construir_prompt(
            mensaje_usuario,
            contexto_rag,
            medical_context,
            conversation_history,
        )
        inputs = self.tokenizer(prompt, return_tensors="pt").to(DEVICE)

        outputs = self.model.generate(
            **inputs,
            max_new_tokens=256,
            temperature=0.7,
            do_sample=True,
            pad_token_id=self.tokenizer.eos_token_id,
        )

        respuesta_completa = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        respuesta_limpia = respuesta_completa.replace(prompt, "").strip()
        return respuesta_limpia
