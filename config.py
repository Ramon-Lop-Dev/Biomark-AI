"""
Configuración centralizada de Biomark AI.

Todo lo que puede cambiar entre entornos (Colab, VPS) o que es sensible
(credenciales) vive aquí, leído desde variables de entorno. Ningún otro
módulo debe leer os.getenv() directamente ni hardcodear credenciales.
"""

import os
import torch
from dotenv import load_dotenv

load_dotenv()

# --- Credenciales y configuración obligatoria ---
# Sin valores por defecto "reales": si falta algo, el servicio debe fallar
# de forma explícita en vez de arrancar con una llave de ejemplo filtrada.
AI_SERVICE_INTERNAL_KEY = os.getenv("AI_SERVICE_INTERNAL_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

_faltantes = [
    nombre
    for nombre, valor in [
        ("AI_SERVICE_INTERNAL_KEY", AI_SERVICE_INTERNAL_KEY),
        ("SUPABASE_URL", SUPABASE_URL),
        ("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY),
    ]
    if not valor
]
if _faltantes:
    raise RuntimeError(
        f"Faltan variables de entorno obligatorias: {', '.join(_faltantes)}. "
        f"Revisa tu archivo .env (usa .env.example como referencia)."
    )

# --- Configuración opcional (con valores por defecto razonables) ---
MODEL_ID = os.getenv("MODEL_ID", "BiomarkAI/Biomark-AI-Produccion")
PORT = int(os.getenv("PORT", "8000"))

# Umbral de distancia del RAG: mientras MÁS BAJO, más estricta la exigencia
# de similitud para considerar un chunk como relevante. Calíbralo probando
# preguntas relevantes vs. irrelevantes contra las distancias reales que
# devuelve ChromaDB.
UMBRAL_RELEVANCIA = float(os.getenv("UMBRAL_RELEVANCIA", "0.75"))

# --- Dispositivo de inferencia ---
# Detecta GPU automáticamente si existe (Colab hoy, VPS con GPU mañana);
# usa CPU si no hay GPU disponible, sin necesidad de tocar código.
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
TORCH_DTYPE = torch.bfloat16 if DEVICE == "cuda" else torch.float32

# --- Voz: ASR (voz -> texto) y TTS (texto -> voz) ---
ASR_MODEL_ID = os.getenv("ASR_MODEL_ID", "openai/whisper-small")
TTS_MODEL_ID = os.getenv("TTS_MODEL_ID", "facebook/mms-tts-spa")

# --- Visión: piel y garganta ---
# El modelo de piel se descarga de Hugging Face Hub (un solo .keras).
SKIN_MODEL_REPO = os.getenv("SKIN_MODEL_REPO", "Tanishq77/skin-condition-classifier")
SKIN_MODEL_FILE = os.getenv("SKIN_MODEL_FILE", "skin_model.keras")

# El modelo de garganta es un pipeline de dos archivos (extractor MobileNetV2
# + clasificador KNN) publicado como Hugging Face Space, no un .keras único.
THROAT_MODEL_REPO = os.getenv("THROAT_MODEL_REPO", "engrharis/Throat_Image_Classifier")
THROAT_EXTRACTOR_FILE = os.getenv("THROAT_EXTRACTOR_FILE", "mobilenetv2_feature_extractor.h5")
THROAT_KNN_FILE = os.getenv("THROAT_KNN_FILE", "knn_pharyngitis_model.pkl")

# --- Identidad de Biomark AI ---
# Se inyecta en cada prompt para mantener tono e identidad consistentes,
# sobre todo cuando preguntan quién o qué es el asistente.
PERSONA_BIOMARK = (
    "Eres Biomark AI, un asistente de salud preventiva creado para apoyar a la "
    "población nicaragüense con información confiable sobre salud. Respondes "
    "con tono médico, cálido y empático, en un lenguaje claro y cercano. "
    "Cuando te pregunten quién o qué eres, preséntate brevemente indicando tu "
    "nombre, tu propósito de apoyo informativo (con base en normativas del "
    "MINSA como dengue, atención a la niñez y vacunación), y aclara que no "
    "reemplazas una consulta médica profesional. Nunca das diagnósticos "
    "definitivos ni recetas médicas."
)
