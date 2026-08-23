"""
Biomark AI — Motor de Inferencia (Producción)

Este archivo solo orquesta los módulos: config, safety, rag, inference.
Toda la lógica vive en su propio módulo para que el proyecto escale sin
que main.py se vuelva un archivo gigante.

Funciona igual en Google Colab (pruebas) y en un VPS (producción) — lo
único que cambia entre entornos es cómo se arranca (ver README.md).
"""

from fastapi import FastAPI, Header, HTTPException
from supabase import create_client, Client

from config import AI_SERVICE_INTERNAL_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DEVICE
from safety.checker import safety_layer_check, MENSAJE_BLOQUEO
from rag.retriever import RagRetriever
from inference.model_loader import get_model_and_tokenizer
from inference.generator import TextGenerator

app = FastAPI(title="Biomark AI - Production Engine")

# --- Supabase ---
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# --- RAG ---
retriever = RagRetriever(supabase)
retriever.sincronizar_y_indexar_bucket()

# --- Modelo + generador ---
model, tokenizer = get_model_and_tokenizer()
generator = TextGenerator(model, tokenizer)


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "Biomark AI Engine", "device": DEVICE}


@app.post("/chat")
async def chat_inference(data: dict, x_internal_key: str = Header(None)):
    if x_internal_key != AI_SERVICE_INTERNAL_KEY:
        raise HTTPException(status_code=403, detail="Acceso no autorizado: llave interna inválida")

    mensaje_usuario = data.get("message", "")

    if safety_layer_check(mensaje_usuario):
        return {"reply": MENSAJE_BLOQUEO, "risk_level": "HIGH", "sources": ["Safety Layer Policy"]}

    contexto_encontrado, fuentes_usadas = retriever.buscar_contexto_relevante(mensaje_usuario)
    respuesta_limpia = generator.generate_response(mensaje_usuario, contexto_encontrado)

    if contexto_encontrado:
        risk_level = "MODERATE"
    else:
        risk_level = "LOW"
        fuentes_usadas = ["Conocimiento general del modelo"]

    return {"reply": respuesta_limpia, "risk_level": risk_level, "sources": fuentes_usadas}


# Arranque directo en VPS: `python main.py`
# En Colab NO se ejecuta este bloque; ahí se arranca con
# `await uvicorn.Server(...).serve()` en una celda aparte (ver README.md).
if __name__ == "__main__":
    import uvicorn
    from config import PORT
    uvicorn.run(app, host="0.0.0.0", port=PORT)
