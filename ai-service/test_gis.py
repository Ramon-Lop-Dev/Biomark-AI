import unittest

from gis.locator import HealthCenterLocator
from gis.specialty_mapper import especialidades_sugeridas


class FakeResponse:
    def __init__(self, data):
        self.data = data


class FakeSupabase:
    def __init__(self, centers):
        self.centers = centers

    def table(self, _name):
        return self

    def select(self, _columns):
        return self

    def execute(self):
        return FakeResponse(self.centers)


class GisTests(unittest.TestCase):
    def test_mapea_casos_prioritarios(self):
        self.assertEqual(especialidades_sugeridas("emergencia pediátrica")[0], "Cirugía pediátrica")
        self.assertEqual(especialidades_sugeridas("emergencia de la mujer")[0], "Gineco-obstetricia")
        self.assertEqual(especialidades_sugeridas("dolor de pecho en un niño")[0], "Pediatría")

    def test_prioriza_especialidad_y_omite_fila_invalida(self):
        locator = HealthCenterLocator(
            FakeSupabase(
                [
                    {"nombre": "Puesto cercano", "latitud": 12.0, "longitud": -86.0,
                     "tipo_unidad": "Puesto de Salud", "especialidades": ["Pediatría"]},
                    {"nombre": "Hospital pediátrico", "latitud": 12.1, "longitud": -86.1,
                     "tipo_unidad": "Hospital", "especialidades": ["Pediatría"]},
                    {"nombre": "Fila inválida", "especialidades": ["Pediatría"]},
                ]
            )
        )
        result = locator.buscar_mas_cercano(
            12.0,
            -86.0,
            especialidades_preferidas=["Pediatría"],
            excluir_no_aptos_para_emergencia=True,
        )
        self.assertEqual(result["nombre"], "Hospital pediátrico")
        self.assertEqual(result["especialidad_coincidente"], "Pediatría")


if __name__ == "__main__":
    unittest.main()