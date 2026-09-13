-- Elimina todos los datos propios del usuario en una sola transaccion.
CREATE OR REPLACE FUNCTION public.eliminar_cuenta_usuario(p_usuario_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_auth_id uuid;
BEGIN
  SELECT auth_id INTO v_auth_id FROM public.usuarios WHERE id = p_usuario_id FOR UPDATE;
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'USUARIO_NO_ENCONTRADO'; END IF;

  DELETE FROM public.hitos_mejoria WHERE objetivo_id IN (SELECT id FROM public.objetivos_mejoria WHERE usuario_id = p_usuario_id);
  DELETE FROM public.objetivos_mejoria WHERE usuario_id = p_usuario_id;
  DELETE FROM public.registros_sintomas WHERE sintoma_id IN (SELECT id FROM public.sintomas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.imagenes_medicas WHERE evento_medico_id IN (SELECT id FROM public.eventos_medicos WHERE usuario_id = p_usuario_id);
  DELETE FROM public.mensajes_chat WHERE sesion_chat_id IN (SELECT id FROM public.sesiones_chat WHERE usuario_id = p_usuario_id);
  DELETE FROM public.alertas_epidemiologicas WHERE reporte_epidemiologico_id IN (SELECT id FROM public.reportes_epidemiologicos WHERE cargado_por = p_usuario_id);
  DELETE FROM public.reportes_epidemiologicos WHERE cargado_por = p_usuario_id;
  DELETE FROM public.dispositivos_push WHERE usuario_id = p_usuario_id;
  DELETE FROM public.consentimientos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfiles WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_medico WHERE usuario_id = p_usuario_id;
  DELETE FROM public.alergias WHERE usuario_id = p_usuario_id;
  DELETE FROM public.medicamentos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.antecedentes_familiares WHERE usuario_id = p_usuario_id;
  DELETE FROM public.vacunas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.sintomas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.eventos_medicos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.recordatorios WHERE usuario_id = p_usuario_id;
  DELETE FROM public.notificaciones WHERE usuario_id = p_usuario_id;
  DELETE FROM public.sesiones_chat WHERE usuario_id = p_usuario_id;
  DELETE FROM public.seguimiento_salud WHERE usuario_id = p_usuario_id;
  DELETE FROM public.reportes_comunitarios WHERE usuario_id = p_usuario_id;
  DELETE FROM public.solicitudes_roles WHERE usuario_id = p_usuario_id;
  UPDATE public.solicitudes_roles SET revisado_por = NULL WHERE revisado_por = p_usuario_id;
  DELETE FROM public.eventos_comunitarios WHERE organizador_id = p_usuario_id;
  DELETE FROM public.registros_auditoria WHERE usuario_id = p_usuario_id;
  DELETE FROM public.usuarios WHERE id = p_usuario_id;
  RETURN v_auth_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.eliminar_cuenta_usuario(uuid) TO service_role;