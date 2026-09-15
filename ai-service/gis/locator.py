"""Localiza centros reales priorizando la especialidad solicitada."""

import math
from typing import TYPE_CHECKING, List, Optional

from gis.specialty_mapper import codigo_servicio

if TYPE_CHECKING:
    from supabase import Client


def _distancia_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    radio_tierra = 6371
    delta_latitud = math.radians(lat2 - lat1)
    delta_longitud = math.radians(lon2 - lon1)
    a = (
        math.sin(delta_latitud / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(delta_longitud / 2) ** 2
    )
    return radio_tierra * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class HealthCenterLocator:
    def __init__(self, supabase_client: "Client"):
        self.supabase = supabase_client

    def buscar_mas_cercano(
        self,
        latitude: float,
        longitude: float,
        especialidades_preferidas: Optional[List[str]] = None,
        excluir_no_aptos_para_emergencia: bool = False,
    ) -> Optional[dict]:
        nivel_minimo = 2 if excluir_no_aptos_para_emergencia else 1
        servicios = especialidades_preferidas or ["Atención general"]
        for especialidad in servicios:
            try:
                respuesta = self.supabase.rpc(
                    "centros_cercanos",
                    {
                        "p_lat": latitude,
                        "p_lon": longitude,
                        "p_servicio": codigo_servicio(especialidad),
                        "p_edad": None,
                        "p_nivel_min": nivel_minimo,
                        "p_radio_m": 50000,
                        "p_limite": 1,
                    },
                ).execute()
            except Exception as error:
                print(f"[GIS] Error consultando centros_cercanos: {error}")
                return None

            if respuesta.data:
                centro = dict(respuesta.data[0])
                centro["distancia_km"] = round(float(centro.pop("metros", 0)) / 1000, 1)
                centro["especialidad_coincidente"] = especialidad
                centro["tipo_unidad"] = "NIVEL_" + str(centro.get("nivel_atencion", ""))
                return centro

        return None