# Carga el modelo de lenguaje y tokenizer configurados para inferencia.
from transformers import AutoModelForCausalLM, AutoTokenizer

from config import MODEL_ID, DEVICE, TORCH_DTYPE


class ModelLoader:
    def __init__(self, model_id: str = MODEL_ID):
        self.model_id = model_id
        self.tokenizer = None
        self.model = None
        self.load_model()

    def load_model(self):
        try:
            print(f"[Biomark AI] Cargando tokenizador para {self.model_id}...")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_id)

            print(f"[Biomark AI] Cargando modelo en {DEVICE.upper()}...")
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                torch_dtype=TORCH_DTYPE,
                device_map="auto",
            )
            print(f"[Biomark AI] Modelo cargado exitosamente en {DEVICE.upper()}.")
        except Exception as e:
            print(f"[ERROR CRÍTICO] No se pudo cargar el modelo principal: {e}")
            self.model = None

    def get_instance(self):
        return self.model, self.tokenizer


# Instancia global exportable (patrón singleton simple)
_loader = None


def get_model_and_tokenizer():
    global _loader
    if _loader is None:
        _loader = ModelLoader()
    return _loader.get_instance()
