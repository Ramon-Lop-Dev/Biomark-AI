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

import os
from typing import Optional

import chromadb
from pypdf import PdfReader
from sentence_transformers import SentenceTransformer
from supabase import Client

from config import UMBRAL_RELEVANCIA


class RagRetriever:
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client
        self.embedder = SentenceTransformer("all-MiniLM-L6-v2")
        self.chroma_client = chromadb.PersistentClient(path="./chroma_db")
        self.collection = self.chroma_client.get_or_create_collection(
            name="minsa_knowledge_base"
        )

    def sincronizar_y_indexar_bucket(self) -> None:
        """Descarga los PDFs del bucket 'documentos-minsa', los fragmenta en
        chunks de texto y los indexa en ChromaDB."""
        try:
            print("[RAG] Sincronizando documentos desde el bucket 'documentos-minsa'...")
            archivos = self.supabase.storage.from_("documentos-minsa").list()
            os.makedirs("./temp_pdfs", exist_ok=True)

            for archivo in archivos:
                nombre_archivo = archivo["name"]
                if not nombre_archivo.endswith(".pdf"):
                    continue

                ruta_local = f"./temp_pdfs/{nombre_archivo}"
                res = self.supabase.storage.from_("documentos-minsa").download(nombre_archivo)
                with open(ruta_local, "wb") as f:
                    f.write(res)

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
                            )
                            chunk_id += 1
                print(f"[RAG] Indexado: {nombre_archivo} ({chunk_id} fragmentos)")
        except Exception as e:
            print(f"[AVISO RAG] No se pudo sincronizar con Supabase Storage: {e}")

    def buscar_contexto_relevante(self, mensaje_usuario: str) -> tuple[Optional[str], list[str]]:
        """Busca los chunks más cercanos a la consulta y descarta los que no
        superan el umbral de relevancia. Retorna (contexto o None, fuentes)."""
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
