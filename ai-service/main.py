from fastapi import FastAPI, Header, HTTPException
import uvicorn
import os
from sentence_transformers import SentenceTransformer
import chromadb
from supabase import create_client, Client
from pypdf import PdfReader

# Importar los módulos que acabamos de crear
from inference.model_loader import get_model_and_tokenizer
from inference.generator import TextGenerator

app = FastAPI(title="Biomark AI Production Engine - Modular")

AI_SERVICE_INTERNAL_KEY = os.getenv("AI_SERVICE_INTERNAL_KEY", "biomark_secure_internal_key_2026_xyz")
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://tu-proyecto.supabase.co")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "tu-key")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# Cargar modelo y generador
model, tokenizer = get_model_and_tokenizer()
generator = TextGenerator(model, tokenizer)

# Inicializar RAG (ChromaDB + Embeddings)
embedder = SentenceTransformer('all-MiniLM-L6-v2')
chroma_client = chromadb.PersistentClient(path="./chroma_db")
collection = chroma_client.get_or_create_collection(name="minsa_knowledge_base")

def safety_layer_check(mensaje: str) -> bool:
    palabras_prohibidas = ["recétame", "dosis exacta", "pastillas para curar", "diagnóstico definitivo"]
    for palabra in palabras_prohibidas:
        if palabra in mensaje.lower():
            return True
    return False

@app.post("/chat")
async def chat_inference(data: dict, x_internal_key: str = Header(None)):
    if x_internal_key != AI_SERVICE_INTERNAL_KEY:
        raise HTTPException(status_code=403, detail="Acceso no autorizado")
    
    mensaje_usuario = data.get("message", "")
    
    if safety_layer_check(mensaje_usuario):
        return {
            "reply": "Lo siento, como asistente preventivo no puedo emitir diagnósticos definitivos ni prescribir medicamentos. Le recomendamos acudir a su centro de salud más cercano.",
            "risk_level": "HIGH",
            "sources": ["Safety Layer Policy"]
        }
    
    # Búsqueda RAG
    contexto_encontrado = "Directrices generales de salud preventiva."
    try:
        query_vector = embedder.encode(mensaje_usuario).tolist()
        resultados = collection.query(query_embeddings=[query_vector], n_results=2)
        if resultados and resultados['documents'] and len(resultados['documents'][0]) > 0:
            contexto_encontrado = "\n".join(resultados['documents'][0])
    except Exception as e:
        print(f"Error en RAG: {e}")

    # Inferencia usando el generador modular
    respuesta_limpia = generator.generate_response(mensaje_usuario, contexto_encontrado)

    return {
        "reply": respuesta_limpia,
        "risk_level": "MODERATE",
        "sources": ["Normativa de Malaria (DTTIR)", "Normativa 017 Atención a la Infancia"]
    }