import 'package:flutter/material.dart';
import '../../biomark_brand.dart';

/// Sistema Universal de Modales y Diálogos de BIOMARK AI.
/// Implementa una tarjeta con diseño coherente: esquinas redondeadas (28px),
/// ícono centralizado (46px), textos legibles según modo claro/oscuro y acciones centradas.
class BiomarkDialog {
  BiomarkDialog._();

  static Color _getCardBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E293B) : Colors.white;
  }

  static Color _getTitleColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  static Color _getMessageColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  /// Diálogo de Error (ícono rojo de alerta, acción en rojo acento)
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Entendido',
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _buildCard(
        context: dialogContext,
        iconWidget: const Icon(
          Icons.error_outline_rounded,
          size: 46,
          color: Colors.redAccent,
        ),
        title: title,
        message: message,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAction?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Éxito / Correcto (ícono verde esmeralda Biomark, acción en verde)
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Continuar',
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _buildCard(
        context: dialogContext,
        iconWidget: const Icon(
          Icons.check_circle_outline_rounded,
          size: 46,
          color: BiomarkColors.green,
        ),
        title: title,
        message: message,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAction?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: BiomarkColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Diálogo Informativo (ícono azul Biomark, acción en azul)
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Entendido',
    VoidCallback? onAction,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildCard(
        context: dialogContext,
        iconWidget: const Icon(
          Icons.info_outline_rounded,
          size: 46,
          color: BiomarkColors.blue,
        ),
        title: title,
        message: message,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAction?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: BiomarkColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Diálogo de Carga ("cargando" con spinner continuo en verde Biomark)
  static Future<void> showLoading(
    BuildContext context, {
    String title = 'Por favor espera',
    String message = 'Procesando solicitud...',
  }) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: _buildCard(
          context: dialogContext,
          iconWidget: const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(BiomarkColors.green),
            ),
          ),
          title: title,
          message: message,
          actions: const [],
        ),
      ),
    );
  }

  /// Cierra el diálogo de carga si está activo
  static void hideLoading(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Diálogo de Confirmación (ícono ámbar/azul o destructivo, botones Cancelar y Confirmar)
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
  }) async {
    if (!context.mounted) return false;
    final primaryColor = isDestructive
        ? Colors.redAccent
        : (iconColor ?? (isDestructive ? Colors.redAccent : BiomarkColors.blue));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _buildCard(
        context: dialogContext,
        iconWidget: Icon(
          icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
          size: 46,
          color: primaryColor,
        ),
        title: title,
        message: message,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: _getMessageColor(context),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Diálogo Personalizado (para formularios, entradas de texto o layouts a la medida)
  static Future<T?> showCustom<T>(
    BuildContext context, {
    Widget? iconWidget,
    IconData? icon,
    Color? iconColor,
    required String title,
    String? message,
    Widget? contentWidget,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return null;
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => _buildCard(
        context: dialogContext,
        iconWidget: iconWidget ??
            (icon != null
                ? Icon(icon, size: 46, color: iconColor ?? BiomarkColors.blue)
                : null),
        title: title,
        message: message,
        contentWidget: contentWidget,
        actions: actions ??
            [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: BiomarkColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Aceptar'),
              ),
            ],
      ),
    );
  }

  /// Constructor base de la tarjeta AlertDialog
  static Widget _buildCard({
    required BuildContext context,
    Widget? iconWidget,
    required String title,
    String? message,
    Widget? contentWidget,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: _getCardBg(context),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: iconWidget,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _getTitleColor(context),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: contentWidget ??
          (message != null
              ? Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getMessageColor(context),
                    fontSize: 14,
                    height: 1.45,
                  ),
                )
              : null),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actions: actions,
    );
  }
}
