"""Clasificación de imágenes clínicas: piel y garganta.

Los dos modelos tienen arquitecturas distintas pero comparten la misma
interfaz (`disponible`, `predecir`), así que VisionService los trata por
igual sin que a main.py le importe cómo funciona cada uno por dentro:

- Piel: un solo modelo .keras multi-clase (Tanishq77/skin-condition-classifier).
- Garganta: pipeline de dos pasos — extractor de características MobileNetV2
  (.h5) + clasificador KNN (.pkl) — publicado en el Space de Hugging Face
  engrharis/Throat_Image_Classifier. No es un .keras único, así que necesita
  su propio preprocesamiento (ver preprocess_image en el app.py original)."""

import io
from typing import Dict, List, Optional, Tuple

import joblib
import numpy as np
import tensorflow as tf
from huggingface_hub import hf_hub_download
from PIL import Image
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

from config import (
    SKIN_MODEL_REPO,
    SKIN_MODEL_FILE,
    THROAT_MODEL_REPO,
    THROAT_EXTRACTOR_FILE,
    THROAT_KNN_FILE,
)

CLASES_PIEL = ["Acné", "Carcinoma", "Eczema", "Queratosis", "Milia", "Rosácea"]
CLASES_GARGANTA = ["Normal", "Posible amigdalitis/faringitis"]


class VisionModel:
    """Modelo de visión de una sola pieza: un .keras multi-clase (piel)."""

    def __init__(self, nombre: str, clases: List[str]):
        self.nombre = nombre
        self.clases = clases
        self.modelo = None

    @property
    def disponible(self) -> bool:
        return self.modelo is not None

    def predecir(self, imagen_bytes: bytes) -> Tuple[str, float]:
        if not self.disponible:
            raise RuntimeError(f"El modelo de '{self.nombre}' no está cargado en esta sesión.")

        imagen = Image.open(io.BytesIO(imagen_bytes)).convert("RGB").resize((224, 224))
        img_array = tf.keras.utils.img_to_array(imagen)
        img_array = tf.expand_dims(img_array, 0)

        predicciones = self.modelo.predict(img_array)
        score = tf.nn.softmax(predicciones[0])
        condicion = self.clases[int(np.argmax(score))]
        confianza = float(np.max(score)) * 100
        return condicion, confianza


class ThroatModel:
    """Modelo de garganta: extractor MobileNetV2 + clasificador KNN
    (dos archivos, en vez de un solo .keras). Mismo preprocesamiento que
    el Space original de Hugging Face: resize 224x224 + preprocess_input
    de mobilenet_v2."""

    def __init__(self, clases: List[str]):
        self.nombre = "garganta"
        self.clases = clases
        self.extractor = None
        self.knn = None

    @property
    def disponible(self) -> bool:
        return self.extractor is not None and self.knn is not None

    def _preprocesar(self, imagen_bytes: bytes) -> np.ndarray:
        imagen = Image.open(io.BytesIO(imagen_bytes)).convert("RGB").resize((224, 224))
        img_array = np.array(imagen)
        img_array = preprocess_input(img_array)
        return np.expand_dims(img_array, axis=0)

    def predecir(self, imagen_bytes: bytes) -> Tuple[str, float]:
        if not self.disponible:
            raise RuntimeError("El modelo de 'garganta' no está cargado en esta sesión.")

        img_procesada = self._preprocesar(imagen_bytes)
        features = self.extractor.predict(img_procesada)

        indice_clase = int(self.knn.predict(features)[0])
        condicion = self.clases[indice_clase]

        # KNeighborsClassifier soporta predict_proba; si por alguna razón
        # el modelo cargado no lo soporta, se usa una confianza binaria
        # como respaldo en vez de tronar.
        if hasattr(self.knn, "predict_proba"):
            confianza = float(np.max(self.knn.predict_proba(features))) * 100
        else:
            confianza = 100.0

        return condicion, confianza


class VisionService:
    """Agrupa los modelos de visión disponibles y expone una única forma
    de consultarlos por tipo ('piel' o 'garganta')."""

    def __init__(self):
        self.modelos: Dict[str, object] = {
            "piel": VisionModel("piel", CLASES_PIEL),
            "garganta": ThroatModel(CLASES_GARGANTA),
        }
        self._cargar_piel()
        self._cargar_garganta()

    def _cargar_piel(self) -> None:
        modelo = self.modelos["piel"]
        try:
            ruta = hf_hub_download(repo_id=SKIN_MODEL_REPO, filename=SKIN_MODEL_FILE)
            modelo.modelo = tf.keras.models.load_model(ruta)
            print("[Vision] Modelo de dermatología cargado correctamente.")
        except Exception as e:
            print(f"[AVISO VISION-PIEL] No disponible: {e}")

    def _cargar_garganta(self) -> None:
        modelo = self.modelos["garganta"]
        try:
            ruta_extractor = hf_hub_download(
                repo_id=THROAT_MODEL_REPO, filename=THROAT_EXTRACTOR_FILE, repo_type="space"
            )
            ruta_knn = hf_hub_download(
                repo_id=THROAT_MODEL_REPO, filename=THROAT_KNN_FILE, repo_type="space"
            )
            modelo.extractor = tf.keras.models.load_model(ruta_extractor)
            modelo.knn = joblib.load(ruta_knn)
            print("[Vision] Modelo de garganta (extractor + KNN) cargado correctamente.")
        except Exception as e:
            print(f"[AVISO VISION-GARGANTA] No disponible: {e}")

    def get(self, tipo: str) -> Optional[object]:
        return self.modelos.get(tipo)
