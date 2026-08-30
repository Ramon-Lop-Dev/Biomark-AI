# Prueba las reglas deterministas de seguridad clínica del AI Service.
import unittest

from safety.checker import clasificar_riesgo, safety_layer_check, validar_respuesta


class SafetyLayerTests(unittest.TestCase):
    def test_bloquea_prescripcion(self):
        self.assertTrue(safety_layer_check("¿Cuál es la dosis exacta?"))

    def test_detecta_urgencia_critica(self):
        self.assertEqual(clasificar_riesgo("Tengo dolor fuerte en el pecho y brazo izquierdo"), "CRITICAL")

    def test_detecta_riesgo_alto(self):
        self.assertEqual(clasificar_riesgo("Tengo fiebre muy alta"), "HIGH")

    def test_valida_respuesta_modelo(self):
        respuesta = validar_respuesta("Sin duda tienes dengue", "HIGH")
        self.assertIn("no permite confirmar", respuesta)
        self.assertIn("atención", respuesta.lower())


if __name__ == "__main__":
    unittest.main()
