from typing import Optional

from config import DEVICE, PERSONA_BIOMARK


class TextGenerator:
    def __init__(self, model, tokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def _construir_prompt(self, mensaje_usuario: str, contexto_rag: Optional[str]) -> str:
        """Arma el prompt final. Si hay contexto RAG relevante lo usa como
        referencia adicional; si no, deja que el modelo responda con su
        propio conocimiento médico (ya viene de su fine-tuning), pidiéndole
        cautela. En ambos casos se mantiene la identidad de Biomark AI."""
        if contexto_rag:
            return (
                f"{PERSONA_BIOMARK}\n\n"
                f"Tienes información de referencia relevante para esta consulta:\n"
                f"{contexto_rag}\n\n"
                f"Paciente: {mensaje_usuario}\n"
                f"Asistente preventivo (usa la referencia si aplica, y tu conocimiento médico si es necesario):"
            )
        return (
            f"{PERSONA_BIOMARK}\n\n"
            f"No tienes normativa oficial específica cargada para esta consulta puntual, "
            f"así que responde con tu conocimiento médico general, siendo cauteloso.\n\n"
            f"Paciente: {mensaje_usuario}\n"
            f"Asistente preventivo:"
        )

    def generate_response(self, mensaje_usuario: str, contexto_rag: Optional[str]) -> str:
        if self.model is None or self.tokenizer is None:
            # Bug corregido: antes referenciaba una variable inexistente
            # (contexto_encontrado) y esto tronaba con NameError.
            contexto_preview = contexto_rag[:200] if contexto_rag else "ninguno"
            return f"Modo de respaldo (modelo no disponible en memoria). Contexto encontrado: {contexto_preview}"

        prompt = self._construir_prompt(mensaje_usuario, contexto_rag)
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
