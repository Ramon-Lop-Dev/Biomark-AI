import torch

class TextGenerator:
    def __init__(self, model, tokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def generate_response(self, mensaje_usuario: str, contexto_rag: str) -> str:
        if self.model is None or self.tokenizer is None:
            return f"Modo de respaldo (Modelo no disponible en memoria). Contexto encontrado: {contexto_encontrado[:200]}"

        # Construir el prompt clínico estructurado
        prompt = (
            f"Contexto normativo oficial MINSA:\n{contexto_rag}\n\n"
            f"Paciente: {mensaje_usuario}\n"
            f"Asistente preventivo:"
        )

        inputs = self.tokenizer(prompt, return_tensors="pt").to("cuda")
        
        # Generar tokens con parámetros de control de calidad y temperatura
        outputs = self.model.generate(
            **inputs, 
            max_new_tokens=256, 
            temperature=0.7, 
            do_sample=True,
            pad_token_id=self.tokenizer.eos_token_id
        )

        respuesta_completa = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        # Limpiar el prompt de la salida para devolver únicamente la respuesta del asistente
        respuesta_limpia = respuesta_completa.replace(prompt, "").strip()
        
        return respuesta_limpia