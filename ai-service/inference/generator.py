import re
from datetime import date, datetime
from typing import Optional

from config import DEVICE, PERSONA_BIOMARK

_MARCADORES_NUEVO_TURNO = [
    r"\n?\s*Paciente\s*:",
    r"\n?\s*USUARIO\s*:",
    r"\n?\s*Asistente[^:]*:",
    # El modelo base fue afinado con formato tipo [INST]...[/INST]. Si el
    # prompt de entrada no respeta exactamente ese formato, el modelo
    # "termina la idea" solo y empieza a alucinar un turno nuevo completo
    # (incluyendo su propia pregunta de apertura, a veces con errores de
    # tipeo). Cortamos ahí para no mostrarle ese ruido al paciente.
    r"\[/?INST\]",
    r"<<SYS>>",
    r"<</SYS>>",
    r"<\|im_start\|>",
    r"<\|im_end\|>",
]

# Limpieza final: si algún token de control queda suelto en el texto (sin
# que dispare un corte de turno completo), se elimina igual antes de
# mostrar la respuesta.
_TOKENS_DE_CONTROL = re.compile(
    r"\[/?INST\]|<<SYS>>|<</SYS>>|<\|im_start\|>|<\|im_end\|>|</?s>"
)


def _calcular_edad(fecha_nacimiento) -> Optional[int]:
    """Calcula edad en años a partir de un ISO date/datetime string. Los
    modelos de lenguaje son poco confiables haciendo aritmética de fechas
    por su cuenta, así que se calcula acá en vez de pasarle la fecha cruda
    y esperar que el modelo infiera la edad."""
    if not fecha_nacimiento:
        return None
    try:
        texto = str(fecha_nacimiento)[:10]
        nacimiento = datetime.strptime(texto, "%Y-%m-%d").date()
        hoy = date.today()
        edad = hoy.year - nacimiento.year - ((hoy.month, hoy.day) < (nacimiento.month, nacimiento.day))
        return edad if 0 <= edad <= 120 else None
    except (ValueError, TypeError):
        return None


def _formatear_contexto_medico(medical_context) -> str:
    """Convierte el contexto médico crudo (dict anidado que arma
    medicalContext.service.js en el backend: perfil, alergias,
    medicamentos, historial, antecedentes_familiares, vacunas, sintomas)
    en un resumen clínico en español que el modelo pueda leer de forma
    confiable, en vez de inyectar el repr crudo del dict de Python."""
    if not medical_context or not isinstance(medical_context, dict):
        return "No hay contexto médico autorizado para este paciente."

    lineas = []

    perfil = medical_context.get("perfil") or {}
    edad = _calcular_edad(perfil.get("fecha_nacimiento"))
    sexo = perfil.get("sexo")
    datos_perfil = []
    if edad is not None:
        datos_perfil.append(f"{edad} años")
    if sexo:
        datos_perfil.append(f"sexo {sexo}")
    if datos_perfil:
        lineas.append("Paciente: " + ", ".join(datos_perfil) + ".")

    alergias = medical_context.get("alergias") or []
    if alergias:
        texto_alergias = "; ".join(
            f"{a.get('alergeno', 'desconocido')} (severidad {a.get('severidad', 'no especificada')})"
            for a in alergias[:10]
        )
        lineas.append(f"Alergias conocidas: {texto_alergias}.")

    medicamentos = medical_context.get("medicamentos") or []
    if medicamentos:
        texto_meds = "; ".join(
            f"{m.get('nombre_medicamento', 'desconocido')}"
            + (f" ({m.get('dosis')}, {m.get('frecuencia')})" if m.get("dosis") or m.get("frecuencia") else "")
            for m in medicamentos[:10]
        )
        lineas.append(f"Medicamentos actuales: {texto_meds}.")

    historial = medical_context.get("historial") or []
    if historial:
        texto_historial = "; ".join(
            h.get("nombre_condicion", "condición no especificada") for h in historial[:10]
        )
        lineas.append(f"Condiciones diagnosticadas previamente: {texto_historial}.")

    antecedentes = medical_context.get("antecedentes_familiares") or []
    if antecedentes:
        texto_antecedentes = "; ".join(
            f"{a.get('parentesco', 'familiar')}: {a.get('nombre_condicion', 'condición no especificada')}"
            for a in antecedentes[:10]
        )
        lineas.append(f"Antecedentes familiares: {texto_antecedentes}.")

    sintomas = medical_context.get("sintomas") or []
    if sintomas:
        texto_sintomas = "; ".join(s.get("nombre_sintoma", "síntoma no especificado") for s in sintomas[:10])
        lineas.append(f"Síntomas registrados recientemente por el paciente: {texto_sintomas}.")

    seguimiento = medical_context.get("seguimiento") or medical_context.get("seguimiento_salud") or []
    if seguimiento:
        texto_seg = "; ".join(
            f"{s.get('sintoma', 'síntoma')}: estado {s.get('estado', 'no especificado')}"
            + (f" (intensidad {s.get('intensidad')}/10)" if s.get("intensidad") is not None else "")
            + (f" - notas: {s.get('notas')}" if s.get("notas") else "")
            for s in seguimiento[:5]
        )
        lineas.append(f"Evolución reciente de síntomas: {texto_seg}.")

    vacunas = medical_context.get("vacunas") or []
    if vacunas:
        texto_vacunas = "; ".join(v.get("nombre_vacuna", "vacuna no especificada") for v in vacunas[:5])
        lineas.append(f"Vacunas más recientes: {texto_vacunas}.")

    if not lineas:
        return "El paciente autorizó su contexto médico, pero no tiene datos cargados todavía."

    return " ".join(lineas)


class TextGenerator:
    def __init__(self, model, tokenizer):
        self.model = model
        self.tokenizer = tokenizer

    def _construir_prompt(
        self,
        mensaje_usuario: str,
        contexto_rag: Optional[str],
        medical_context=None,
        conversation_history=None,
    ) -> str:
        contexto_paciente = _formatear_contexto_medico(medical_context)
        historial = conversation_history or []
        turnos = "\n".join(
            f"{turno.get('emisor', 'USUARIO')}: {turno.get('mensaje', '')}"
            for turno in historial[-10:]
        ) or "Sin mensajes anteriores."
        referencia = contexto_rag or "No hay referencia clínica específica cargada."

        reglas = (
            "Reglas obligatorias de seguridad clínica:\n"
            "1. CERO PRESCRIPCIONES: NUNCA recetes medicamentos, nombres de fármacos ni dosis específicas.\n"
            "2. SIN DIAGNÓSTICO DEFINITIVO: Distingue siempre orientación preventiva de diagnóstico médico formal.\n"
            "3. PREGUNTAS EDUCATIVAS O GENERALES (ej. '¿Qué es el sarampión?', '¿Cómo se transmite el dengue?'): "
            "Explica de forma clara, didáctica y objetiva la definición, causas conocidas y síntomas típicos "
            "según lineamientos médicos y del MINSA. No asumas que la persona lo padece ni fuerces estructura de triaje.\n"
            "4. DESCRIPCIÓN DE SÍNTOMAS: Explica qué condiciones o causas probables suelen asociarse a esos síntomas "
            "en tono condicional ('podría deberse a', 'suele asociarse a'), indica medidas generales de cuidado "
            "(hidratación, reposo) y destaca las señales de alarma para acudir de urgencia a un centro de salud.\n"
            "5. SEGUIMIENTO DE EVOLUCIÓN (estados MEJORO, IGUAL, EMPEORO, NO_SEGURO): Valora la evolución en base al historial. "
            "Si mejoró, refuerza el autocuidado; si empeoró o no está seguro, aconseja valoración presencial pronta.\n"
            "6. Saludos: responde cordialmente y pregunta en qué puedes orientar hoy.\n"
            "Responde SOLO por el Asistente en un único turno, en español claro, cálido y empático."
        )

        cuerpo = (
            f"Contexto médico autorizado del paciente: {contexto_paciente}\n\n"
            f"Historial reciente de conversación:\n{turnos}\n\n"
            f"Referencia clínica: {referencia}\n\n"
            f"Paciente: {mensaje_usuario}"
        )

        # El modelo de producción es un fine-tune de tipo instruct (formato
        # [INST]...[/INST]). Si le mandamos texto plano sin ese formato, no
        # reconoce dónde termina el turno y empieza a alucinar uno nuevo
        # (de ahí el "[/INST]" filtrándose en las respuestas). Si el
        # tokenizador trae su chat_template, lo usamos para que el prompt
        # quede exactamente en el formato con el que se entrenó el modelo;
        # si no lo trae, se cae al formato de texto plano de siempre.
        chat_template = getattr(self.tokenizer, "chat_template", None)
        if chat_template:
            try:
                mensajes = [
                    {"role": "system", "content": f"{PERSONA_BIOMARK}\n\n{reglas}"},
                    {"role": "user", "content": cuerpo},
                ]
                return self.tokenizer.apply_chat_template(
                    mensajes, tokenize=False, add_generation_prompt=True
                )
            except Exception as e:
                print(f"[TextGenerator] No se pudo aplicar chat_template, uso prompt plano: {e}")

        return (
            f"{PERSONA_BIOMARK}\n\n{reglas}\n\n{cuerpo}\n"
            "Asistente preventivo (responde en español claro y breve):"
        )

    def _cortar_en_siguiente_turno(self, texto: str) -> str:
        """Si el modelo sigue generando después de su respuesta y empieza a
        inventar un nuevo turno de conversación, cortamos ahí."""
        posiciones = []
        for patron in _MARCADORES_NUEVO_TURNO:
            m = re.search(patron, texto)
            if m:
                posiciones.append(m.start())
        if posiciones:
            texto = texto[:min(posiciones)]
        return texto.strip()

    def generate_response(
        self,
        mensaje_usuario: str,
        contexto_rag: Optional[str],
        medical_context=None,
        conversation_history=None,
    ) -> str:
        if self.model is None or self.tokenizer is None:
            contexto_preview = contexto_rag[:200] if contexto_rag else "ninguno"
            return (
                "No puedo generar una orientación clínica fiable en este momento. "
                "Describe tus síntomas a un profesional de salud o acude a un centro cercano."
            )

        prompt = self._construir_prompt(
            mensaje_usuario,
            contexto_rag,
            medical_context,
            conversation_history,
        )
        inputs = self.tokenizer(prompt, return_tensors="pt").to(DEVICE)
        input_len = inputs["input_ids"].shape[-1]

        outputs = self.model.generate(
            **inputs,
            max_new_tokens=180,
            do_sample=False,
            repetition_penalty=1.12,
            no_repeat_ngram_size=3,
            pad_token_id=self.tokenizer.eos_token_id,
        )

        # Solo decodifica los tokens NUEVOS (no re-decodifica el prompt
        # completo para luego intentar borrarlo con .replace() de texto,
        # que fallaba cuando la re-decodificación no calzaba byte a byte
        # con el prompt original).
        tokens_generados = outputs[0][input_len:]
        respuesta = self.tokenizer.decode(tokens_generados, skip_special_tokens=True).strip()

        respuesta = self._cortar_en_siguiente_turno(respuesta)
        # Red de seguridad extra: si algún token de control quedó suelto sin
        # disparar un corte de turno (por ejemplo al final del texto, sin
        # nada después que lo delate como un turno nuevo), se limpia igual.
        respuesta = _TOKENS_DE_CONTROL.sub("", respuesta)
        respuesta = re.sub(r"^(Asistente(?: preventivo)?\s*:\s*)", "", respuesta, flags=re.IGNORECASE)
        respuesta = re.sub(r"\n{3,}", "\n\n", respuesta).strip()

        if not respuesta:
            return "No logré generar una respuesta clara para eso. ¿Puedes reformular tu pregunta o dar más detalle?"

        return respuesta