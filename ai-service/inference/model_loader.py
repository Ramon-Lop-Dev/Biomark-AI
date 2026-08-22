import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

class ModelLoader:
    def __init__(self, model_id: str = "BiomarkAI/Biomark-AI-Produccion"):
        self.model_id = model_id
        self.tokenizer = None
        self.model = None
        self.load_model()

    def load_model(self):
        try:
            print(f"Cargando tokenizador para {self.model_id}...")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_id)
            
            print(f"Cargando modelo especializado en GPU...")
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                torch_dtype=torch.bfloat16,
                device_map="auto"
            )
            print("¡Modelo cargado exitosamente en el motor de inferencia!")
        except Exception as e:
            print(f"[ERROR CRÍTICO] No se pudo cargar el modelo principal: {e}")
            self.model = None

    def get_instance(self):
        return self.model, self.tokenizer

# Instancia global exportable
_loader = None

def get_model_and_tokenizer():
    global _loader
    if _loader is None:
        _loader = ModelLoader()
    return _loader.get_instance()