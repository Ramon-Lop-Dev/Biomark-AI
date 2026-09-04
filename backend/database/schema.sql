-- BIOMARK AI — Esquema de base de datos (Supabase PostgreSQL)
-- Ya creado y aplicado en el proyecto real de Supabase.
-- Este archivo queda como fuente de verdad versionada del esquema.

CREATE TABLE public.usuarios (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  auth_id uuid UNIQUE,
  correo text NOT NULL UNIQUE,
  rol USER-DEFINED NOT NULL DEFAULT 'USUARIO'::rol_usuario,
  activo boolean NOT NULL DEFAULT true,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_actualizacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id)
);

CREATE TABLE public.perfiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL UNIQUE,
  nombre_completo text NOT NULL,
  fecha_nacimiento date,
  sexo USER-DEFINED,
  telefono text,
  direccion text,
  municipio text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_actualizacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT perfiles_pkey PRIMARY KEY (id),
  CONSTRAINT perfiles_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.historial_medico (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  nombre_condicion text NOT NULL,
  fecha_diagnostico date,
  notas text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT historial_medico_pkey PRIMARY KEY (id),
  CONSTRAINT historial_medico_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.alergias (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  alergeno text NOT NULL,
  severidad USER-DEFINED NOT NULL DEFAULT 'LEVE'::severidad_alergia,
  notas text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT alergias_pkey PRIMARY KEY (id),
  CONSTRAINT alergias_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.medicamentos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  nombre_medicamento text NOT NULL,
  dosis text,
  frecuencia text,
  fecha_inicio date,
  fecha_fin date,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT medicamentos_pkey PRIMARY KEY (id),
  CONSTRAINT medicamentos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.antecedentes_familiares (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  parentesco text NOT NULL,
  nombre_condicion text NOT NULL,
  notas text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT antecedentes_familiares_pkey PRIMARY KEY (id),
  CONSTRAINT antecedentes_familiares_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.vacunas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  nombre_vacuna text NOT NULL,
  numero_dosis integer NOT NULL DEFAULT 1,
  fecha_aplicacion date NOT NULL,
  fecha_proxima_dosis date,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT vacunas_pkey PRIMARY KEY (id),
  CONSTRAINT vacunas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.sintomas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  nombre_sintoma text NOT NULL,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT sintomas_pkey PRIMARY KEY (id),
  CONSTRAINT sintomas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.registros_sintomas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  sintoma_id uuid NOT NULL,
  temperatura numeric,
  presion_arterial text,
  notas text,
  url_foto text,
  fecha_registro timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT registros_sintomas_pkey PRIMARY KEY (id),
  CONSTRAINT registros_sintomas_sintoma_id_fkey FOREIGN KEY (sintoma_id) REFERENCES public.sintomas(id)
);

CREATE TABLE public.eventos_medicos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  tipo_evento USER-DEFINED NOT NULL,
  descripcion text,
  fecha_evento timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT eventos_medicos_pkey PRIMARY KEY (id),
  CONSTRAINT eventos_medicos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.imagenes_medicas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  evento_medico_id uuid NOT NULL,
  url_imagen text NOT NULL,
  clasificacion text,
  confianza numeric,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT imagenes_medicas_pkey PRIMARY KEY (id),
  CONSTRAINT imagenes_medicas_evento_medico_id_fkey FOREIGN KEY (evento_medico_id) REFERENCES public.eventos_medicos(id)
);

CREATE TABLE public.recordatorios (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  tipo USER-DEFINED NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  fecha_programada timestamp with time zone NOT NULL,
  estado USER-DEFINED NOT NULL DEFAULT 'PENDIENTE'::estado_recordatorio,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT recordatorios_pkey PRIMARY KEY (id),
  CONSTRAINT recordatorios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.notificaciones (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  tipo USER-DEFINED NOT NULL,
  mensaje text NOT NULL,
  fecha_envio timestamp with time zone,
  fecha_lectura timestamp with time zone,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.sesiones_chat (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  fecha_inicio timestamp with time zone NOT NULL DEFAULT now(),
  fecha_fin timestamp with time zone,
  CONSTRAINT sesiones_chat_pkey PRIMARY KEY (id),
  CONSTRAINT sesiones_chat_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.mensajes_chat (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  sesion_chat_id uuid NOT NULL,
  emisor USER-DEFINED NOT NULL,
  mensaje text NOT NULL,
  nivel_riesgo USER-DEFINED,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT mensajes_chat_pkey PRIMARY KEY (id),
  CONSTRAINT mensajes_chat_sesion_chat_id_fkey FOREIGN KEY (sesion_chat_id) REFERENCES public.sesiones_chat(id)
);

CREATE TABLE public.centros_salud (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  nombre text NOT NULL,
  tipo USER-DEFINED NOT NULL,
  latitud numeric NOT NULL,
  longitud numeric NOT NULL,
  direccion text,
  telefono text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT centros_salud_pkey PRIMARY KEY (id)
);

CREATE TABLE public.eventos_comunitarios (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  organizador_id uuid NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  fecha_evento timestamp with time zone NOT NULL,
  ubicacion text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT eventos_comunitarios_pkey PRIMARY KEY (id),
  CONSTRAINT eventos_comunitarios_organizador_id_fkey FOREIGN KEY (organizador_id) REFERENCES public.usuarios(id)
);

CREATE TABLE public.zonas_riesgo (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  municipio text NOT NULL,
  latitud numeric NOT NULL,
  longitud numeric NOT NULL,
  radio_km numeric NOT NULL DEFAULT 5,
  nivel_riesgo_actual USER-DEFINED NOT NULL DEFAULT 'BAJO'::nivel_riesgo,
  fecha_actualizacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT zonas_riesgo_pkey PRIMARY KEY (id)
);

CREATE TABLE public.reportes_epidemiologicos (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  cargado_por uuid,
  fuente text NOT NULL,
  enfermedad text NOT NULL,
  municipio text NOT NULL,
  fecha_reporte date NOT NULL,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reportes_epidemiologicos_pkey PRIMARY KEY (id),
  CONSTRAINT reportes_epidemiologicos_cargado_por_fkey FOREIGN KEY (cargado_por) REFERENCES public.usuarios(id)
);

CREATE TABLE public.alertas_epidemiologicas (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  reporte_epidemiologico_id uuid NOT NULL,
  zona_riesgo_id uuid NOT NULL,
  nivel_alerta USER-DEFINED NOT NULL,
  mensaje text NOT NULL,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT alertas_epidemiologicas_pkey PRIMARY KEY (id),
  CONSTRAINT alertas_epidemiologicas_reporte_epidemiologico_id_fkey FOREIGN KEY (reporte_epidemiologico_id) REFERENCES public.reportes_epidemiologicos(id),
  CONSTRAINT alertas_epidemiologicas_zona_riesgo_id_fkey FOREIGN KEY (zona_riesgo_id) REFERENCES public.zonas_riesgo(id)
);

CREATE TABLE public.reportes_comunitarios (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid NOT NULL,
  zona_riesgo_id uuid,
  cantidad_casos integer NOT NULL DEFAULT 1,
  descripcion text,
  latitud numeric NOT NULL,
  longitud numeric NOT NULL,
  estado USER-DEFINED NOT NULL DEFAULT 'PENDIENTE_VALIDACION'::estado_reporte_comunitario,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reportes_comunitarios_pkey PRIMARY KEY (id),
  CONSTRAINT reportes_comunitarios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT reportes_comunitarios_zona_riesgo_id_fkey FOREIGN KEY (zona_riesgo_id) REFERENCES public.zonas_riesgo(id)
);

CREATE TABLE public.registros_auditoria (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  usuario_id uuid,
  tipo_entidad text NOT NULL,
  id_entidad uuid NOT NULL,
  accion text NOT NULL,
  detalle jsonb,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT registros_auditoria_pkey PRIMARY KEY (id),
  CONSTRAINT registros_auditoria_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
