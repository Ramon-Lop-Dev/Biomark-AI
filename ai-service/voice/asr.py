"""Reconocimiento automático de voz (ASR): transcribe audio a texto con
Whisper, para que el paciente pueda consultar a Biomark AI hablando en
vez de escribiendo."""

from transformers import pipeline

from config import DEVICE, ASR_MODEL_ID


class ASRService:
    def __init__(self, model_id: str = ASR_MODEL_ID):
        self.model_id = model_id
        self.pipeline = None
        self._load()

    def _load(self):
        try:
            print(f"[Voz] Cargando ASR ({self.model_id})...")
            self.pipeline = pipeline(
                task="automatic-speech-recognition",
                model=self.model_id,
                device=0 if DEVICE == "cuda" else -1,
            )
            print("[Voz] ASR cargado correctamente.")
        except Exception as e:
            print(f"[AVISO ASR] No disponible: {e}")
            self.pipeline = None

    @property
    def disponible(self) -> bool:
        return self.pipeline is not None

    def transcribir(self, ruta_audio: str) -> str:
        """Transcribe un archivo de audio ya guardado en disco. Lanza
        RuntimeError si el modelo no cargó (el caller decide qué HTTP
        status devolver)."""
        if not self.disponible:
            raise RuntimeError("El servicio ASR no está cargado en esta sesión.")
        resultado = self.pipeline(ruta_audio, generate_kwargs={"language": "spanish"})
        return resultado["text"].strip()
