"""Localiza centros reales priorizando la especialidad solicitada."""

import math
from typing import TYPE_CHECKING, List, Optional

from gis.specialty_mapper import TIPOS_NO_APTOS_PARA_EMERGENCIA

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

    def _todos_los_centros(self) -> list:
        try:
            respuesta = self.supabase.table("centros_salud").select("*").execute()
            return respuesta.data or []
        except Exception as error:
            print(f"[GIS] Error consultando centros_salud: {error}")
            return []

    def _mas_cercano_de(self, centros: list, latitude: float, longitude: float) -> Optional[dict]:
        mas_cercano = None
        distancia_minima = float("inf")
        for centro in centros:
            try:
                distancia = _distancia_km(
                    latitude, longitude, float(centro["latitud"]), float(centro["longitud"])
                )
            except (KeyError, TypeError, ValueError):
                continue
            if distancia < distancia_minima:
                distancia_minima = distancia
                mas_cercano = {**centro, "distancia_km": round(distancia, 1)}
        return mas_cercano

    def buscar_mas_cercano(
        self,
        latitude: float,
        longitude: float,
        especialidades_preferidas: Optional[List[str]] = None,
        excluir_no_aptos_para_emergencia: bool = False,
    ) -> Optional[dict]:
        centros = self._todos_los_centros()
        if not centros:
            return None

        candidatos = centros
        if excluir_no_aptos_para_emergencia:
            centros_aptos = [
                centro
                for centro in centros
                if centro.get("tipo_unidad") not in TIPOS_NO_APTOS_PARA_EMERGENCIA
            ]
            if centros_aptos:
                candidatos = centros_aptos

        if especialidades_preferidas:
            for especialidad in especialidades_preferidas:
                coincidencias = [
                    centro
                    for centro in candidatos
                    if any(
                        str(disponible).casefold() == especialidad.casefold()
                        for disponible in (centro.get("especialidades") or [])
                    )
                ]
                resultado = self._mas_cercano_de(coincidencias, latitude, longitude)
                if resultado:
                    resultado["especialidad_coincidente"] = especialidad
                    return resultado

        return self._mas_cercano_de(candidatos, latitude, longitude)
