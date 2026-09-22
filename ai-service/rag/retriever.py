"""
Módulo RAG de Biomark AI.

Se encarga de:
1. Sincronizar los PDFs del bucket 'documentos-minsa' de Supabase Storage
   e indexarlos en ChromaDB.
2. Buscar contexto relevante para una consulta, aplicando un umbral de
   distancia para NO inyectar contexto irrelevante en el prompt del modelo
   (el modelo ya trae conocimiento médico propio de su fine-tuning; el RAG
   es una capa adicional, no obligatoria en cada respuesta).
"""

import json
import os
from datetime import datetime
from typing import Optional

try:
    import chromadb
    from pypdf import PdfReader
    from sentence_transformers import SentenceTransformer
    RAG_DEPS_AVAILABLE = True
except ImportError:
    chromadb = None
    PdfReader = None
    SentenceTransformer = None
    RAG_DEPS_AVAILABLE = False

try:
    from supabase import Client
except ImportError:
    Client = object

from config import UMBRAL_RELEVANCIA, SUPABASE_BUCKET_MINSA

_MANIFEST_PATH = "./chroma_db/indexed_files.json"


class RagRetriever:
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client
        self.embedder = SentenceTransformer("all-MiniLM-L6-v2") if SentenceTransformer else None
        os.makedirs("./chroma_db", exist_ok=True)
        if chromadb:
            self.chroma_client = chromadb.PersistentClient(path="./chroma_db")
            self.collection = self.chroma_client.get_or_create_collection(
                name="minsa_knowledge_base"
            )
        else:
            self.chroma_client = None
            self.collection = None
        self.manifest = self._cargar_manifiesto()

    def _cargar_manifiesto(self) -> dict:
        """Carga el registro de archivos ya indexados en ChromaDB."""
        if os.path.exists(_MANIFEST_PATH):
            try:
                with open(_MANIFEST_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"[RAG] Error leyendo manifiesto: {e}")
        return {}

    def _guardar_manifiesto(self) -> None:
        """Persiste el registro de archivos indexados."""
        try:
            with open(_MANIFEST_PATH, "w", encoding="utf-8") as f:
                json.dump(self.manifest, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[RAG] Error guardando manifiesto: {e}")

    def _esta_indexado(self, nombre_archivo: str, updated_at: str, size: Optional[int]) -> bool:
        """Comprueba si el documento ya fue vectorizado e indexado previamente."""
        info = self.manifest.get(nombre_archivo)
        if not info:
            return False

        # Si el conteo de la colección está vacío, se debe re-indexar
        try:
            if self.collection.count() == 0:
                return False
        except Exception:
            return False

        # Si en Supabase cambió el timestamp o el tamaño, no está al día
        if updated_at and info.get("updated_at") and updated_at != info.get("updated_at"):
            return False
        if size is not None and info.get("size") is not None and size != info.get("size"):
            return False

        # Verificar existencia de al menos un fragmento en ChromaDB
        try:
            existentes = self.collection.get(where={"source": nombre_archivo}, limit=1)
            if existentes and existentes.get("ids"):
                return True
        except Exception:
            pass

        return True

    def sincronizar_y_indexar_bucket(self) -> None:
        """Descarga e indexa únicamente los PDFs nuevos o modificados del bucket,
        evitando re-descargar y re-vectorizar lo que ya está en ChromaDB."""
        if not RAG_DEPS_AVAILABLE or self.collection is None or self.embedder is None:
            print("[AVISO RAG] Dependencias RAG (chromadb / sentence-transformers) no disponibles. Omitiendo indexación.")
            return

        try:
            print(f"[RAG] Sincronizando documentos desde el bucket '{SUPABASE_BUCKET_MINSA}'...")
            archivos = self.supabase.storage.from_(SUPABASE_BUCKET_MINSA).list()
            if not archivos:
                print(
                    f"[RAG] ADVERTENCIA: el bucket '{SUPABASE_BUCKET_MINSA}' está vacío "
                    f"o el nombre no coincide con el real en Supabase Storage."
                )
                return
            os.makedirs("./temp_pdfs", exist_ok=True)

            for archivo in archivos:
                nombre_archivo = archivo.get("name", "")
                if not nombre_archivo.endswith(".pdf"):
                    continue

                updated_at = str(archivo.get("updated_at") or archivo.get("created_at") or "")
                metadata = archivo.get("metadata") or {}
                size = metadata.get("size") if isinstance(metadata, dict) else None

                if self._esta_indexado(nombre_archivo, updated_at, size):
                    chunks_previos = self.manifest.get(nombre_archivo, {}).get("chunks", "varios")
                    print(
                        f"[RAG] Documento ya indexado en ChromaDB: {nombre_archivo} "
                        f"({chunks_previos} fragmentos). Omitiendo re-descarga y re-vectorización."
                    )
                    continue

                print(f"[RAG] Descargando e indexando nuevo documento: {nombre_archivo}...")
                ruta_local = f"./temp_pdfs/{nombre_archivo}"
                res = self.supabase.storage.from_(SUPABASE_BUCKET_MINSA).download(nombre_archivo)
                with open(ruta_local, "wb") as f:
                    f.write(res)

                # Si ya existían fragmentos antiguos de este archivo, limpiarlos
                try:
                    self.collection.delete(where={"source": nombre_archivo})
                except Exception:
                    pass

                reader = PdfReader(ruta_local)
                chunk_id = 0
                for page_num, page in enumerate(reader.pages):
                    texto = page.extract_text()
                    if not texto:
                        continue
                    chunk_size = 500
                    chunks = [texto[i:i + chunk_size] for i in range(0, len(texto), chunk_size)]
                    for chunk in chunks:
                        if len(chunk.strip()) > 50:
                            vector = self.embedder.encode(chunk).tolist()
                            self.collection.upsert(
                                documents=[chunk],
                                embeddings=[vector],
                                ids=[f"{nombre_archivo}_p{page_num}_c{chunk_id}"],
                                metadatas=[{
                                    "source": nombre_archivo,
                                    "page": page_num,
                                    "chunk": chunk_id,
                                }],
                            )
                            chunk_id += 1

                self.manifest[nombre_archivo] = {
                    "updated_at": updated_at,
                    "size": size,
                    "chunks": chunk_id,
                    "indexed_at": datetime.now().isoformat(),
                }
                self._guardar_manifiesto()
                print(f"[RAG] Indexado con éxito: {nombre_archivo} ({chunk_id} fragmentos)")
        except Exception as e:
            print(f"[AVISO RAG] No se pudo sincronizar con Supabase Storage: {e}")

    def buscar_contexto_relevante(self, mensaje_usuario: str) -> tuple[Optional[str], list[str]]:
        """Busca los chunks más cercanos a la consulta y descarta los que no
        superan el umbral de relevancia. Retorna (contexto o None, fuentes)."""
        if not RAG_DEPS_AVAILABLE or self.collection is None or self.embedder is None:
            return None, []

        try:
            query_vector = self.embedder.encode(mensaje_usuario).tolist()
            resultados = self.collection.query(
                query_embeddings=[query_vector],
                n_results=2,
                include=["documents", "distances"],
            )
        except Exception as e:
            print(f"[RAG] Error al consultar la base vectorial: {e}")
            return None, []

        if not resultados or not resultados["documents"] or not resultados["documents"][0]:
            return None, []

        chunks_relevantes = []
        fuentes_usadas = []
        for i, distancia in enumerate(resultados["distances"][0]):
            if distancia <= UMBRAL_RELEVANCIA:
                chunks_relevantes.append(resultados["documents"][0][i])
                nombre_fuente = resultados["ids"][0][i].split("_p")[0]
                if nombre_fuente not in fuentes_usadas:
                    fuentes_usadas.append(nombre_fuente)

        if not chunks_relevantes:
            return None, []

        return "\n".join(chunks_relevantes), fuentes_usadas
