import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Servicio global de gestión de estados de carga para BIOMARK AI.
/// Bloquea interacción, previene dobles toques, maneja timeouts y reintentos.
class LoadingService extends ChangeNotifier {
  LoadingService._();
  static final LoadingService instance = LoadingService._();

  bool _isLoading = false;
  String _message = 'Procesando...';
  Timer? _timeoutTimer;
  VoidCallback? _currentRetryAction;

  bool get isLoading => _isLoading;
  String get message => _message;
  bool get hasRetry => _currentRetryAction != null;

  /// Muestra el overlay de carga bloqueando toda interacción.
  /// Incluye timeout de seguridad predeterminado de 20 segundos.
  void show({
    String message = 'Procesando...',
    Duration timeout = const Duration(seconds: 20),
    VoidCallback? onTimeout,
  }) {
    _timeoutTimer?.cancel();
    _message = message;
    _isLoading = true;
    notifyListeners();

    _timeoutTimer = Timer(timeout, () {
      if (_isLoading) {
        hide();
        onTimeout?.call();
      }
    });
  }

  /// Oculta el overlay y libera la interacción.
  void hide() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envuelve una tarea asíncrona dentro del overlay global de carga.
  /// Previene doble ejecución concurrente y maneja timeout y excepciones.
  Future<T> wrap<T>({
    required BuildContext context,
    required Future<T> Function() task,
    String message = 'Procesando solicitud...',
    Duration timeout = const Duration(seconds: 25),
    String? errorMessage,
  }) async {
    if (_isLoading) {
      // Si ya hay una operación en curso, evitamos concurrencia accidental
      throw Exception('Una operación ya se encuentra en curso.');
    }

    show(
      message: message,
      timeout: timeout,
      onTimeout: () {
        if (context.mounted) {
          _showErrorSnackbar(
            context,
            'La operación tardó demasiado tiempo. Verifica tu conexión a internet.',
          );
        }
      },
    );

    try {
      final result = await task().timeout(timeout);
      return result;
    } on TimeoutException {
      if (context.mounted) {
        _showErrorSnackbar(
          context,
          'Tiempo de espera agotado. Revisa tu conexión de red.',
        );
      }
      rethrow;
    } catch (error) {
      if (context.mounted) {
        final display = errorMessage ?? _formatErrorMessage(error);
        _showErrorSnackbar(context, display);
      }
      rethrow;
    } finally {
      hide();
    }
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString().replaceFirst(RegExp(r'^[a-zA-Z0-9]+Exception:\s*'), '');
    if (str.contains('SocketException') || str.contains('Failed host lookup') || str.contains('Network is unreachable')) {
      return 'Sin conexión al servidor. Revisa tu acceso a internet.';
    }
    if (str.contains('500') || str.contains('Internal Server Error')) {
      return 'El servidor experimenta una intermitencia temporal. Intenta de nuevo.';
    }
    return str.isEmpty ? 'Ocurrió un error inesperado.' : str;
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Widget Overlay que envuelve la aplicación completa en MaterialApp.builder.
/// Proporciona feedback visual elegante y bloquea gestos durante peticiones.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LoadingService.instance,
      builder: (context, _) {
        final isLoading = LoadingService.instance.isLoading;
        final message = LoadingService.instance.message;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            child,
            if (isLoading)
              Positioned.fill(
                child: PopScope(
                  canPop: false, // Bloquea el botón atrás en Android mientras carga
                  child: AbsorbPointer(
                    absorbing: true,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: (isDark ? Colors.black : const Color(0xFF0F172A))
                            .withValues(alpha: 0.45),
                        child: Center(
                          child: _ElegantLoadingCard(message: message, isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ElegantLoadingCard extends StatelessWidget {
  const _ElegantLoadingCard({
    required this.message,
    required this.isDark,
  });

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    const accentGreen = Color(0xFF16A34A);

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentGreen.withValues(alpha: 0.12),
            ),
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Por favor espera un momento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal auxiliar para confirmaciones o cargas localizadas si se requiere.
class LoadingModal {
  static void show(BuildContext context, {String message = 'Cargando...'}) {
    LoadingService.instance.show(message: message);
  }

  static void hide() {
    LoadingService.instance.hide();
  }
}
