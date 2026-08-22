"""
AI Service — Chat (texto)
Corre en Google Colab. Sirve el modelo BiomarkAI/Biomark-AI-Produccion
(variante GGUF cuantizada) como API REST, para que el backend Node.js
la consuma via AI_SERVICE_URL (la URL publica que te da ngrok).
"""

from fastapi import FastAPI
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI(title="Biomark AI - Chat Service")

print("Cargando modelo...")
llm = Llama.from_pretrained(
    repo_id="BiomarkAI/Biomark-AI-Produccion-Q4_K_M-GGUF",
    filename="biomark-ai-produccion-q4_k_m.gguf",
    n_ctx=2048,
)
print("Modelo cargado.")


class MensajeEntrada(BaseModel):
    mensaje: str
    contexto: str = ""  # historial reciente o antecedentes, si se manda desde Node


@app.get("/health")
def health():
    return {"status": "ok", "service": "chat"}


@app.post("/chat")
def chat(entrada: MensajeEntrada):
    prompt = f"### Instruccion:\n{entrada.contexto}\n{entrada.mensaje}\n\n### Respuesta:\n"
    output = llm(prompt, max_tokens=300, stop=["###"])
    respuesta = output["choices"][0]["text"].strip()
    return {"respuesta": respuesta}
