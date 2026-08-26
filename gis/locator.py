"""Geolocalización de centros de salud reales.

Este módulo NUNCA le pide al LLM que "invente" un centro de salud 
 En su lugar, hace un
cálculo determinista (fórmula de Haversine) sobre datos reales de la
tabla `centros_salud` de Supabase, reutilizando el mismo cliente que ya
usa el módulo de RAG.
"""

import math
from typing import Optional

from supabase import Client


def _distancia_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Fórmula de Haversine: distancia en línea recta entre dos coordenadas."""
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class HealthCenterLocator:
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client

    def buscar_mas_cercano(self, latitude: float, longitude: float) -> Optional[dict]:
        """Retorna el centro de salud real más cercano a una coordenada,
        o None si la tabla está vacía o hay un error de consulta."""
        try:
            respuesta = self.supabase.table("centros_salud").select("*").execute()
            centros = respuesta.data
        except Exception as e:
            print(f"[GIS] Error consultando centros_salud: {e}")
            return None

        if not centros:
            return None

        mas_cercano = None
        distancia_minima = float("inf")

        for centro in centros:
            distancia = _distancia_km(latitude, longitude, centro["latitud"], centro["longitud"])
            if distancia < distancia_minima:
                distancia_minima = distancia
                mas_cercano = {**centro, "distancia_km": round(distancia, 1)}

        return mas_cercano
