import unittest
from safety.checker import (
    safety_layer_check,
    clasificar_riesgo,
    validar_respuesta,
    MENSAJE_BLOQUEO,
    MENSAJE_URGENCIA,
)
from inference.generator import _formatear_contexto_medico, TextGenerator


class SafetyAndEvolutionTests(unittest.TestCase):
    def test_bloquea_solicitudes_de_prescripcion_y_dosis(self):
        self.assertTrue(safety_layer_check("Recétame pastillas para la fiebre"))
        self.assertTrue(safety_layer_check("¿Qué dosis exacta debo tomar?"))
        self.assertTrue(safety_layer_check("Dime cuántos mg tomo de paracetamol"))
        self.assertTrue(safety_layer_check("Dame un diagnóstico definitivo"))

    def test_permite_preguntas_educativas_y_descripcion_de_sintomas(self):
        self.assertFalse(safety_layer_check("¿Qué es el sarampión?"))
        self.assertFalse(safety_layer_check("¿Cómo se transmite el dengue?"))
        self.assertFalse(safety_layer_check("Tengo dolor de garganta y fiebre leve desde ayer"))

    def test_clasificacion_de_riesgo(self):
        self.assertEqual(clasificar_riesgo("no puedo respirar"), "CRITICAL")
        self.assertEqual(clasificar_riesgo("tengo dolor intenso en el pecho"), "CRITICAL")
        self.assertEqual(clasificar_riesgo("tengo fiebre alta y vómitos persistentes"), "HIGH")
        self.assertEqual(clasificar_riesgo("tengo dolor de cabeza y tos"), "MODERATE")
        self.assertEqual(clasificar_riesgo("¿Qué es el sarampión?"), "LOW")

    def test_validar_respuesta_neutraliza_afirmaciones_concluyentes_y_dosis(self):
        respuesta_concluyente = "Tienes definitivamente sarampión. Toma 500 mg de medicina."
        validada = validar_respuesta(respuesta_concluyente, "LOW")
        self.assertNotIn("Tienes definitivamente", validada)
        self.assertNotIn("500 mg", validada)
        self.assertIn("posibilidad que debe confirmar un profesional", validada.lower())

    def test_formatear_contexto_medico_incluye_evolucion(self):
        contexto = {
            "perfil": {"fecha_nacimiento": "1998-05-12", "sexo": "M"},
            "alergias": [{"alergeno": "Penicilina", "severidad": "alta"}],
            "medicamentos": [{"nombre_medicamento": "Loratadina", "dosis": "10mg", "frecuencia": "diaria"}],
            "historial": [{"nombre_condicion": "Rinitis alérgica"}],
            "antecedentes_familiares": [{"parentesco": "Padre", "nombre_condicion": "Hipertensión"}],
            "sintomas": [{"nombre_sintoma": "Fiebre"}],
            "seguimiento": [
                {
                    "sintoma": "Fiebre",
                    "estado": "MEJORO",
                    "intensidad": 3,
                    "notas": "Temperatura bajó a 37.0°C tras paños húmedos"
                },
                {
                    "sintoma": "Dolor de cabeza",
                    "estado": "IGUAL",
                    "intensidad": 6,
                    "notas": "Persiste en la zona frontal"
                }
            ]
        }
        resumen = _formatear_contexto_medico(contexto)
        self.assertIn("Penicilina", resumen)
        self.assertIn("Loratadina", resumen)
        self.assertIn("Fiebre: estado MEJORO", resumen)
        self.assertIn("Dolor de cabeza: estado IGUAL", resumen)

    def test_construccion_de_prompt_no_falla(self):
        generator = TextGenerator(model=None, tokenizer=None)
        prompt = generator._construir_prompt(
            mensaje_usuario="¿Qué es el sarampión?",
            contexto_rag="El sarampión es una enfermedad vírica aguda y altamente contagiosa...",
            medical_context={"perfil": {"sexo": "F"}},
            conversation_history=[{"emisor": "USUARIO", "mensaje": "Hola"}],
        )
        self.assertIn("¿Qué es el sarampión?", prompt)
        self.assertIn("CERO PRESCRIPCIONES", prompt)
        self.assertIn("PREGUNTAS EDUCATIVAS", prompt)

    def test_construccion_de_prompt_con_mistral_chat_template(self):
        class MockMistralTokenizer:
            chat_template = "dummy_jinja_template"

            def apply_chat_template(self, messages, tokenize=False, add_generation_prompt=True):
                for m in messages:
                    if m["role"] not in ("user", "assistant"):
                        raise ValueError("Only user and assistant roles are supported!")
                return f"[INST] {messages[0]['content']} [/INST]"

        generator = TextGenerator(model=None, tokenizer=MockMistralTokenizer())
        prompt = generator._construir_prompt(
            mensaje_usuario="¿Cómo prevenir el dengue?",
            contexto_rag="Eliminar criaderos de zancudos.",
            medical_context=None,
            conversation_history=[],
        )
        self.assertTrue(prompt.startswith("[INST]"))
        self.assertTrue(prompt.endswith("[/INST]"))
        self.assertIn("¿Cómo prevenir el dengue?", prompt)

    def test_sugerir_accion_detecta_progreso_y_evolucion(self):
        from inference.service import ClinicalService
        service = ClinicalService(retriever=None, generator=None)
        self.assertEqual(service.sugerir_accion("Hoy ya me siento mejor de la fiebre"), "REGISTER_PROGRESS")
        self.assertEqual(service.sugerir_accion("Sigo con dolor de garganta y malestar"), "REGISTER_PROGRESS")
        self.assertEqual(service.sugerir_accion("No mejoro, me siento peor que ayer"), "REGISTER_PROGRESS")
        self.assertEqual(service.sugerir_accion("Quiero registrar mi mejoría"), "REGISTER_PROGRESS")
        self.assertEqual(service.sugerir_accion("¿Cómo registro mi progreso?"), "REGISTER_PROGRESS")
        self.assertEqual(service.sugerir_accion("Aún me duele el estómago"), "REGISTER_PROGRESS")


if __name__ == "__main__":
    unittest.main()

