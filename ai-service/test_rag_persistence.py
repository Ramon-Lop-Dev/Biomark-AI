import json
import os
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from rag.retriever import RagRetriever


class RagPersistenceTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.mock_manifest_path = os.path.join(self.temp_dir.name, "indexed_files.json")

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_manifiesto_carga_y_guarda_correctamente(self):
        mock_supabase = MagicMock()
        retriever = RagRetriever(mock_supabase)
        retriever.manifest = {
            "guia_dengue.pdf": {
                "updated_at": "2026-09-01T10:00:00Z",
                "size": 2048,
                "chunks": 12,
            }
        }

        with patch("rag.retriever._MANIFEST_PATH", self.mock_manifest_path):
            retriever._guardar_manifiesto()
            self.assertTrue(os.path.exists(self.mock_manifest_path))

            cargado = retriever._cargar_manifiesto()
            self.assertIn("guia_dengue.pdf", cargado)
            self.assertEqual(cargado["guia_dengue.pdf"]["chunks"], 12)

    def test_esta_indexado_detecta_archivos_existentes_y_nuevos(self):
        mock_supabase = MagicMock()
        retriever = RagRetriever(mock_supabase)
        mock_collection = MagicMock()
        mock_collection.count.return_value = 10
        mock_collection.get.return_value = {"ids": ["guia_dengue.pdf_p0_c0"]}
        retriever.collection = mock_collection

        retriever.manifest = {
            "guia_dengue.pdf": {
                "updated_at": "2026-09-01T10:00:00Z",
                "size": 2048,
                "chunks": 12,
            }
        }

        # Mismo archivo sin cambios: debe retornar True
        self.assertTrue(retriever._esta_indexado("guia_dengue.pdf", "2026-09-01T10:00:00Z", 2048))

        # Archivo que no existe en el manifiesto: debe retornar False
        self.assertFalse(retriever._esta_indexado("guia_nueva.pdf", "2026-09-01T10:00:00Z", 1024))

        # Archivo con fecha actualizada en Supabase: debe retornar False (requiere re-indexar)
        self.assertFalse(retriever._esta_indexado("guia_dengue.pdf", "2026-09-20T12:00:00Z", 2048))

        # Archivo con tamaño alterado: debe retornar False
        self.assertFalse(retriever._esta_indexado("guia_dengue.pdf", "2026-09-01T10:00:00Z", 5000))

    def test_sincronizar_omite_descarga_si_ya_esta_en_chroma(self):
        mock_supabase = MagicMock()
        mock_storage_bucket = MagicMock()
        mock_supabase.storage.from_.return_value = mock_storage_bucket

        # Simular lista de Supabase con un archivo ya indexado
        mock_storage_bucket.list.return_value = [
            {
                "name": "normativa_004.pdf",
                "updated_at": "2026-08-15T00:00:00Z",
                "metadata": {"size": 4096},
            }
        ]

        retriever = RagRetriever(mock_supabase)
        mock_collection = MagicMock()
        mock_collection.count.return_value = 5
        mock_collection.get.return_value = {"ids": ["normativa_004.pdf_p0_c0"]}
        retriever.collection = mock_collection
        retriever.embedder = MagicMock()
        retriever.manifest = {
            "normativa_004.pdf": {
                "updated_at": "2026-08-15T00:00:00Z",
                "size": 4096,
                "chunks": 5,
            }
        }

        with patch("rag.retriever.RAG_DEPS_AVAILABLE", True):
            retriever.sincronizar_y_indexar_bucket()

        # NO debe haber llamado a download
        mock_storage_bucket.download.assert_not_called()


if __name__ == "__main__":
    unittest.main()
