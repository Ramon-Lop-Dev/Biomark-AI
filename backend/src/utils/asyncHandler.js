/**
 * Envuelve un controller async para que cualquier excepción (o promesa
 * rechazada) se reenvíe automáticamente a next(), y termine en el
 * errorHandler centralizado en vez de tumbar el proceso o requerir un
 * try/catch manual en cada controller.
 *
 * Uso: const miControlador = asyncHandler(async (req, res) => { ... });
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = asyncHandler;
