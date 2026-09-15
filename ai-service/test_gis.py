import unittest

from gis.locator import HealthCenterLocator
from gis.specialty_mapper import especialidades_sugeridas


class FakeResponse:
    def __init__(self, data):
        self.data = data


class FakeSupabase:
    def __init__(self, centers):
        self.centers = centers

    def rpc(self, _name, _params):
        return self

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

    def test_prioriza_especialidad_con_rpc_espacial(self):
        locator = HealthCenterLocator(
            FakeSupabase(
                [
                    {"nombre": "Hospital pediátrico", "nivel_atencion": 3, "metros": 1200},
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
        self.assertEqual(result["distancia_km"], 1.2)


if __name__ == "__main__":
    unittest.main()