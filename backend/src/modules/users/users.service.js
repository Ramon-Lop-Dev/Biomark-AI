// Coordina operaciones de perfil y auditoría del usuario.
const usersRepo = require('./users.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const crypto = require('crypto');
const supabase = require('../../config/supabase');

const BUCKET_FOTOS_PERFIL = 'fotos-perfil';
const FOTO_URL_SEGUNDOS = 60 * 60 * 24;

const conUrlFoto = async (data) => {
  const fotoPath = data?.perfiles?.foto_path;
  if (!fotoPath) return data;

  const { data: signed, error } = await supabase.storage
    .from(BUCKET_FOTOS_PERFIL)
    .createSignedUrl(fotoPath, FOTO_URL_SEGUNDOS);
  if (error) throw new AppError('No se pudo obtener la foto de perfil', 500);

  return {
    ...data,
    perfiles: { ...data.perfiles, foto_url: signed.signedUrl }
  };
};

const getProfile = async (usuarioId) => {
  const { data, error } = await usersRepo.findUsuarioConPerfil(usuarioId);

  if (error) {
    throw new AppError('No se pudo obtener el perfil', 500);
  }

  return conUrlFoto(data);
};

const updateProfile = async (usuarioId, cambios) => {
  const { data, error } = await usersRepo.actualizarPerfil(usuarioId, cambios);

  if (error) {
    throw new AppError('No se pudo actualizar el perfil', 500);
  }

  // No debería pasar en condiciones normales (perfiles se crea junto con
  // usuarios en el registro), pero si la fila de perfiles no existe,
  // el UPDATE no afecta ninguna fila y Supabase devuelve data = null.
  if (!data) {
    throw new AppError('No se encontró un perfil asociado a este usuario', 404);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'perfiles',
    idEntidad: usuarioId,
    accion: 'ACTUALIZACION',
    detalle: { campos_actualizados: Object.keys(cambios) }
  });

  // Se devuelve la misma forma que getProfile (usuario + perfil anidado)
  // para que el cliente no tenga que manejar dos formatos de respuesta
  // distintos entre GET y PUT.
  return getProfile(usuarioId);
};

const updateProfilePhoto = async (usuarioId, file) => {
  if (!file) throw new AppError('Debes seleccionar una imagen', 400);

  const { data: current, error: currentError } = await usersRepo.findUsuarioConPerfil(usuarioId);
  if (currentError || !current) throw new AppError('No se encontró el perfil', 404);

  const extension = ({
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp'
  })[file.mimetype] || 'jpg';
  const fotoPath = `${usuarioId}/${crypto.randomUUID()}.${extension}`;
  const { error: uploadError } = await supabase.storage
    .from(BUCKET_FOTOS_PERFIL)
    .upload(fotoPath, file.buffer, {
      contentType: file.mimetype,
      cacheControl: '3600',
      upsert: false
    });
  if (uploadError) throw new AppError('No se pudo guardar la foto de perfil', 500);

  const { error: updateError } = await usersRepo.actualizarFotoPath(usuarioId, fotoPath);
  if (updateError) {
    await supabase.storage.from(BUCKET_FOTOS_PERFIL).remove([fotoPath]);
    throw new AppError('No se pudo asociar la foto al perfil', 500);
  }

  const fotoAnterior = current.perfiles?.foto_path;
  if (fotoAnterior) {
    await supabase.storage.from(BUCKET_FOTOS_PERFIL).remove([fotoAnterior]);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'perfiles',
    idEntidad: usuarioId,
    accion: 'ACTUALIZACION',
    detalle: { campos_actualizados: ['foto_path'] }
  });

  return getProfile(usuarioId);
};

module.exports = { getProfile, updateProfile, updateProfilePhoto };
