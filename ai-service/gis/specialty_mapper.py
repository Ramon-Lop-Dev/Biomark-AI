"""Mapea lenguaje clínico del usuario a especialidades verificables."""

import re
import unicodedata
from typing import List, Tuple


_REGLAS: List[Tuple[List[str], List[str]]] = [
    (
        [
            r"\b(emergencia|urgencia)\b.*\b(pediatr|nin[oa]|nene|bebe|lactante)",
            r"\b(pediatr|nin[oa]|nene|bebe|lactante)\b.*\b(emergencia|urgencia)\b",
        ],
        ["Cirugía pediátrica", "Neonatología", "Pediatría"],
    ),
    (
        [r"\b(pediatr|niñ[oa]|nin[oa]|nene|bebe|lactante|recien nacido)"],
        ["Pediatría", "Neonatología", "Cirugía pediátrica", "Atención general"],
    ),
    (
        [
            r"\b(embaraz|parto|contraccion|sangrado vaginal|ginecol|obstetric)",
            r"\bsalud de la mujer\b",
            r"\bemergencia de la mujer\b",
        ],
        ["Gineco-obstetricia", "Salud de la mujer", "Maternidad"],
    ),
    (
        [r"\b(pecho|corazon|cardiac|presion alta|hipertension)"],
        ["Cardiología", "Cardiología pediátrica", "Hemodinamia", "Medicina interna"],
    ),
    ([r"\b(suicid|ansiedad|depresion|salud mental|panico)"], ["Psiquiatría", "Salud mental"]),
    ([r"\b(alcohol|droga|adiccion)"], ["Adicciones", "Salud mental"]),
    ([r"\b(piel|mancha|sarpullido|erupcion|grano|urticaria)"], ["Dermatología"]),
    ([r"\b(ojo|ojos|vista|vision|ver borroso)"], ["Oftalmología", "Cirugía ocular"]),
    ([r"\b(oido|escucha|audicion|habla)"], ["Audiología", "Logopedia"]),
    (
        [r"\b(estomago|diarrea|vomito|gastritis|higado|endoscopia)"],
        ["Gastroenterología", "Endoscopía", "Medicina interna"],
    ),
    ([r"\b(diabetes|azucar alta|glucosa|tiroides|hormona)"], ["Endocrinología", "Diabetes"]),
    ([r"\b(cancer|tumor|quimioterapia|oncolog)"], ["Oncología", "Quimioterapia", "Radioterapia"]),
    ([r"\b(respirar|pulmon|tos|asma|neumonia)"], ["Medicina interna", "Multiespecialidad"]),
    ([r"\b(fiebre|garganta|faringitis|resfriado|gripe|influenza)"], ["Medicina general", "Medicina interna", "Atención general"]),
    ([r"\b(cabeza|migraña|migrana|mareo|desmayo|convulsion)"], ["Neurología", "Medicina interna", "Atención general"]),
    ([r"\b(orinar|orina|urinaria|riñon|rinon|ardor al orinar)"], ["Urología", "Medicina interna", "Atención general"]),
    ([r"\b(dolor abdominal|abdomen|vientre|estreñimiento|estrenimiento)"], ["Gastroenterología", "Medicina interna", "Atención general"]),
    (
        [r"\b(fractura|hueso roto|cirugia|herida profunda|cortada|machete|hemorragia|sangra.*mucho)"],
        ["Cirugía", "Multiespecialidad"],
    ),
    ([r"\b(rehabilitacion|fisioterapia|movilidad)"], ["Rehabilitación física", "Medicina física"]),
    ([r"\b(vacun|esquema de vacunas)"], ["Vacunación", "Atención general"]),
    ([r"\b(tercera edad|adulto mayor|anciano)"], ["Gerontología", "Atención general"]),
]

_COMPILADAS = [
    ([re.compile(patron, re.IGNORECASE) for patron in patrones], especialidades)
    for patrones, especialidades in _REGLAS
]
ESPECIALIDADES_FALLBACK = ["Atención general", "Atención general básica", "Multiespecialidad"]
TIPOS_NO_APTOS_PARA_EMERGENCIA = {"Puesto de Salud"}


def _normalizar(texto: str) -> str:
    return "".join(
        caracter
        for caracter in unicodedata.normalize("NFD", texto.lower())
        if unicodedata.category(caracter) != "Mn"
    )


def especialidades_sugeridas(mensaje_usuario: str) -> List[str]:
    texto = _normalizar(mensaje_usuario or "")
    for patrones, especialidades in _COMPILADAS:
        if any(patron.search(texto) for patron in patrones):
            return especialidades + [e for e in ESPECIALIDADES_FALLBACK if e not in especialidades]
    return ESPECIALIDADES_FALLBACK