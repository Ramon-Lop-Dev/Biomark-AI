# Genera respuestas clínicas usando el modelo y los contextos autorizados.
from typing import Optional

from config import DEVICE, PERSONA_BIOMARK


class TextGenerator:
    def __init__(self, model, tokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def _construir_prompt(self, mensaje_usuario: str, contexto_rag: Optional[str], medical_context=None, conversation_history=None) -> str:
        """Arma el prompt final. Si hay contexto RAG relevante lo usa como
        referencia adicional; si no, deja que el modelo responda con su
        propio conocimiento médico (ya viene de su fine-tuning), pidiéndole
        cautela. En ambos casos se mantiene la identidad de Biomark AI."""
        secciones = [PERSONA_BIOMARK]
        if medical_context:
            secciones.append(f"Contexto clínico autorizado del paciente (úsalo solo si es relevante):\n{medical_context}")
        if conversation_history:
            secciones.append(f"Historial reciente de la conversación:\n{conversation_history}")
        if contexto_rag:
            secciones.append(f"Información de referencia relevante:\n{contexto_rag}")
        else:
            secciones.append("No hay normativa oficial específica cargada; responde con cautela.")
        secciones.append(
            f"Paciente: {mensaje_usuario}\n"
            "Asistente preventivo: orienta, no diagnostiques ni prescribas; indica señales de alarma."
        )
        return "\n\n".join(secciones)

    def generate_response(self, mensaje_usuario: str, contexto_rag: Optional[str], medical_context=None, conversation_history=None) -> str:
        if self.model is None or self.tokenizer is None:
            # Bug corregido: antes referenciaba una variable inexistente
            # (contexto_encontrado) y esto tronaba con NameError.
            contexto_preview = contexto_rag[:200] if contexto_rag else "ninguno"
            return f"Modo de respaldo (modelo no disponible en memoria). Contexto encontrado: {contexto_preview}"

        prompt = self._construir_prompt(mensaje_usuario, contexto_rag, medical_context, conversation_history)
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
