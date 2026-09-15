-- Endurece el flujo de solicitudes de roles privilegiados.
-- Ejecutar después de 007_solicitudes_roles.sql.

CREATE UNIQUE INDEX IF NOT EXISTS uq_solicitud_rol_pendiente_usuario
  ON public.solicitudes_roles(usuario_id, rol_solicitado)
  WHERE estado = 'PENDIENTE';

CREATE INDEX IF NOT EXISTS idx_reportes_comunitarios_estado_fecha
  ON public.reportes_comunitarios(estado, fecha_creacion DESC);
