"""Síntesis de voz (TTS): convierte la respuesta de texto de Biomark AI en
audio, con el modelo VITS multilingüe de Meta afinado para español."""

import io

import scipy.io.wavfile
import torch
from transformers import AutoTokenizer, VitsModel

from config import DEVICE, TTS_MODEL_ID


class TTSService:
    def __init__(self, model_id: str = TTS_MODEL_ID):
        self.model_id = model_id
        self.tokenizer = None
        self.model = None
        self._load()

    def _load(self):
        try:
            print(f"[Voz] Cargando TTS ({self.model_id})...")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_id)
            self.model = VitsModel.from_pretrained(self.model_id).to(DEVICE)
            print("[Voz] TTS cargado correctamente.")
        except Exception as e:
            print(f"[AVISO TTS] No disponible: {e}")
            self.tokenizer = None
            self.model = None

    @property
    def disponible(self) -> bool:
        return self.model is not None and self.tokenizer is not None

    def sintetizar(self, texto: str) -> bytes:
        """Genera audio WAV (bytes) a partir de un texto. Lanza
        RuntimeError si el modelo no cargó."""
        if not self.disponible:
            raise RuntimeError("El servicio TTS no está cargado en esta sesión.")

        inputs = self.tokenizer(texto, return_tensors="pt").to(DEVICE)
        with torch.no_grad():
            output = self.model(**inputs).waveform

        audio_numpy = output.squeeze().cpu().numpy()
        buffer = io.BytesIO()
        scipy.io.wavfile.write(buffer, rate=self.model.config.sampling_rate, data=audio_numpy)
        buffer.seek(0)
        return buffer.read()
