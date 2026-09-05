"""
Biomark AI — Motor de Inferencia (Producción)

Este archivo solo orquesta los módulos: config, safety, rag, inference,
voice, vision. Toda la lógica vive en su propio módulo para que el
proyecto escale sin que main.py se vuelva un archivo gigante.

Funciona igual en Google Colab (pruebas) y en un VPS (producción) — lo
único que cambia entre entornos es cómo se arranca (ver README.md).
"""

import json
import os
import tempfile

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.responses import Response
from supabase import create_client, Client

from config import AI_SERVICE_INTERNAL_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DEVICE
from rag.retriever import RagRetriever
from inference.model_loader import get_model_and_tokenizer
from inference.generator import TextGenerator
from inference.service import ClinicalService
from voice.asr import ASRService
from voice.tts import TTSService
from vision.classifier import VisionService
from gis.locator import HealthCenterLocator
from gis.specialty_mapper import especialidades_sugeridas

app = FastAPI(title="Biomark AI - Production Engine")

# --- Supabase ---
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# --- RAG ---
retriever = RagRetriever(supabase)
retriever.sincronizar_y_indexar_bucket()

# --- Modelo principal + generador + servicio clínico compartido ---
model, tokenizer = get_model_and_tokenizer()
generator = TextGenerator(model, tokenizer)
clinical_service = ClinicalService(retriever, generator)

# --- Voz y visión (cada uno tolera fallar sin tumbar el resto del servicio) ---
asr_service = ASRService()
tts_service = TTSService()
vision_service = VisionService()

# --- GIS: recomendación de centro de salud real, solo para /chat por ahora ---
locator = HealthCenterLocator(supabase)


def verificar_clave(x_internal_key: str) -> None:
    if x_internal_key != AI_SERVICE_INTERNAL_KEY:
        raise HTTPException(status_code=403, detail="Acceso no autorizado: llave interna inválida")


@app.get("/health")
async def health_check():
    # No hace trabajo pesado ni bloqueante, solo lee estado ya calculado en
    # memoria — puede quedarse async sin congelar el servidor.
    return {
        "status": "ok",
        "service": "Biomark AI Engine",
        "device": DEVICE,
        "llm": model is not None,
        "asr": asr_service.disponible,
        "tts": tts_service.disponible,
        "vision_piel": vision_service.get("piel").disponible,
        "vision_garganta": vision_service.get("garganta").disponible,
    }


# def normal (no async): /generate llama a model.generate(), que es
# bloqueante y pesado. Con "async def", FastAPI la corre en el mismo hilo
# del event loop y congela TODO el servidor (incluido /health) mientras
# genera. Con "def" normal, FastAPI la corre en un thread pool aparte.
@app.post("/chat")
def chat_inference(data: dict, x_internal_key: str = Header(None)):
    verificar_clave(x_internal_key)
    mensaje_usuario = data.get("message", "")
    if not mensaje_usuario.strip():
        raise HTTPException(status_code=400, detail="El campo 'message' es obligatorio")

    respuesta, risk_level, fuentes = clinical_service.responder(
        mensaje_usuario,
        medical_context=data.get("medical_context"),
        conversation_history=data.get("conversation_history"),
    )

    # GIS: si el cliente manda coordenadas, se busca el centro de salud
    # REAL más cercano (nunca inventado por el LLM) y se agrega tanto al
    # texto de la respuesta como en un campo estructurado aparte, para que
    # Flutter pueda mostrarlo en un mapa sin tener que parsear el texto.
    centro_sugerido = None
    ubicacion_requerida = False
    latitude = data.get("latitude")
    longitude = data.get("longitude")
    if latitude is not None and longitude is not None:
        try:
            latitude = float(latitude)
            longitude = float(longitude)
            if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
                raise ValueError
        except (TypeError, ValueError):
            latitude = longitude = None

    if latitude is not None and longitude is not None:
        centro_sugerido = locator.buscar_mas_cercano(
            latitude,
            longitude,
            especialidades_preferidas=especialidades_sugeridas(mensaje_usuario),
            excluir_no_aptos_para_emergencia=risk_level in ("CRITICAL", "HIGH"),
        )
        if centro_sugerido:
            respuesta += (
                f"\n\nEl centro recomendado para tu caso es "
                f"{centro_sugerido['nombre']} (a {centro_sugerido['distancia_km']} km)"
                + (f", en {centro_sugerido['direccion']}." if centro_sugerido.get("direccion") else ".")
            )
    elif clinical_service.debe_recomendar_centro(mensaje_usuario, risk_level):
        ubicacion_requerida = True
        respuesta += (
            "\n\nPara recomendarte el centro de salud u hospital más cercano, "
            "necesito tu ubicación. Activa el permiso de ubicación en la app."
        )

    return {
        "reply": respuesta,
        "risk_level": risk_level,
        "sources": fuentes,
        "suggested_action": clinical_service.sugerir_accion(mensaje_usuario),
        "centro_sugerido": centro_sugerido,
        "ubicacion_requerida": ubicacion_requerida,
    }


@app.post("/voice")
def voice_endpoint(
    archivo: UploadFile = File(...),
    medical_context: str = Form("{}"),
    conversation_history: str = Form("[]"),
    x_internal_key: str = Header(None),
):
    verificar_clave(x_internal_key)
    if not asr_service.disponible:
        raise HTTPException(status_code=503, detail="El servicio de voz (ASR) no está disponible")

    sufijo = os.path.splitext(archivo.filename or "")[1] or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=sufijo) as tmp:
        tmp.write(archivo.file.read())
        ruta_temp = tmp.name

    try:
        texto_transcrito = asr_service.transcribir(ruta_temp)
    except Exception as e:
        texto_transcrito = ""
        print(f"[ASR] Error: {e}")
    finally:
        if os.path.exists(ruta_temp):
            os.remove(ruta_temp)

    if not texto_transcrito:
        raise HTTPException(status_code=422, detail="No se pudo transcribir el audio")

    try:
        contexto = json.loads(medical_context)
        historial = json.loads(conversation_history)
    except json.JSONDecodeError:
        contexto, historial = None, []
    respuesta, risk_level, fuentes = clinical_service.responder(
        texto_transcrito,
        medical_context=contexto,
        conversation_history=historial,
    )
    return {
        "transcription": texto_transcrito,
        "reply": respuesta,
        "risk_level": risk_level,
        "sources": fuentes,
    }


@app.post("/audio/synthesize")
def synthesize_endpoint(data: dict, x_internal_key: str = Header(None)):
    verificar_clave(x_internal_key)
    if not tts_service.disponible:
        raise HTTPException(status_code=503, detail="El servicio de voz (TTS) no está disponible")

    texto = data.get("text", "")
    if not texto.strip():
        raise HTTPException(status_code=400, detail="El campo 'text' es obligatorio")

    try:
        audio_bytes = tts_service.sintetizar(texto)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generando audio: {e}")

    return Response(content=audio_bytes, media_type="audio/wav")


@app.post("/vision")
def vision_endpoint(tipo: str, archivo: UploadFile = File(...), x_internal_key: str = Header(None)):
    verificar_clave(x_internal_key)

    modelo = vision_service.get(tipo)
    if modelo is None:
        raise HTTPException(status_code=400, detail="El parámetro 'tipo' debe ser 'piel' o 'garganta'")
    if not modelo.disponible:
        raise HTTPException(status_code=503, detail=f"El modelo de '{tipo}' no está cargado en esta sesión")

    try:
        image_bytes = archivo.file.read()
        condicion_detectada, confianza = modelo.predecir(image_bytes)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analizando la imagen: {e}")

    prompt_clinico = (
        f"El sistema visual detectó una condición de {tipo} compatible con "
        f"{condicion_detectada} con una confianza del {confianza:.1f}%. "
        f"¿Qué directrices preventivas aplican?"
    )
    respuesta, risk_level, fuentes = clinical_service.responder(prompt_clinico)

    return {
        "tipo_analisis": tipo,
        "condicion_detectada": condicion_detectada,
        "confidence_percentage": round(confianza, 1),
        "biomark_recommendation": respuesta,
        "risk_level": risk_level,
        "sources": fuentes,
    }


# Arranque directo en VPS: `python main.py`
# En Colab NO se ejecuta este bloque; ahí se arranca con
# `await uvicorn.Server(...).serve()` en una celda aparte (ver README.md).
if __name__ == "__main__":
    import uvicorn
    from config import PORT
    uvicorn.run(app, host="0.0.0.0", port=PORT)
