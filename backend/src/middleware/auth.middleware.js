const supabase = require('../config/supabase');
const { resolverUsuario } = require('../utils/resolverUsuario');
const AppError = require('../utils/AppError');

const verifyToken = async (req, res, next) => {
    // 1. Obtener el encabezado de autorización
    const authHeader = req.headers['authorization'];

    // 2. Extraer el token
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return next(new AppError('Acceso denegado. Token no proporcionado.', 401));
    }

    try {
        // 3. Usar el cliente de Supabase para validar el token de forma segura
        const { data, error } = await supabase.auth.getUser(token);

        if (error || !data.user) {
            return next(new AppError('Token inválido o expirado.', 401));
        }

        // 4. Inyectar los datos del usuario de Supabase Auth (auth.users)
        //    req.user.id aqui es el auth_id, NO el id de public.usuarios.
        req.user = data.user;

        // 5. Resolver el usuario interno (id, rol, activo) de public.usuarios.
        //    Todos los controllers deben usar req.usuarioId (no req.user.id)
        //    para cualquier consulta contra tablas de dominio, y
        //    req.usuarioRol para chequeos de RBAC (ver rbac.middleware.js).
        const usuario = await resolverUsuario(data.user.id);

        if (!usuario.activo) {
            return next(new AppError('Esta cuenta ha sido desactivada.', 403));
        }

        req.usuarioId = usuario.id;
        req.usuarioRol = usuario.rol;

        // 6. Dar paso al controlador
        next();
    } catch (error) {
        if (error.status === 404) {
            return next(new AppError(error.message, 404));
        }
        next(error);
    }
};

module.exports = { verifyToken };
