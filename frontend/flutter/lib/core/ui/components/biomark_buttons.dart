// Biblioteca de Botones Reutilizables de Biomark AI
// Diseñados conforme a la guía de marca (Syne/Poppins, BiomarkColors, WCAG 2.1 AA/AAA)
import 'package:flutter/material.dart';
import '../../../biomark_brand.dart';
import '../../design/app_themecontroller.dart';

/// Botón de Acción Principal (Filled / Elevated)
/// Utilizado para acciones prioritarias como "Iniciar Medición", "Enviar Reporte", "Guardar".
class BiomarkPrimaryButton extends StatelessWidget {
  const BiomarkPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52.0,
    this.borderRadius = 16.0,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = AppThemeController.instance.isHighContrast;
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isHighContrast
        ? Colors.black
        : (backgroundColor ?? BiomarkColors.green);
    final defaultFg = isHighContrast
        ? Colors.white
        : (foregroundColor ?? Colors.white);

    final content = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultBg,
          foregroundColor: defaultFg,
          elevation: isHighContrast ? 0 : 2,
          shadowColor: BiomarkColors.green.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isHighContrast
                ? const BorderSide(color: Colors.white, width: 2.0)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(defaultFg),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: defaultFg),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.2,
                      color: defaultFg,
                    ),
                  ),
                ],
              ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: content) : content;
  }
}

/// Botón Secundario con Borde (Outlined)
/// Utilizado para acciones secundarias como "Cancelar", "Volver", "Configurar".
class BiomarkOutlinedButton extends StatelessWidget {
  const BiomarkOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.height = 50.0,
    this.borderRadius = 16.0,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = AppThemeController.instance.isHighContrast;
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorder = isHighContrast
        ? Colors.black
        : (borderColor ?? (isDark ? Colors.white38 : BiomarkColors.blue));
    final defaultText = isHighContrast
        ? Colors.black
        : (textColor ?? (isDark ? Colors.white : BiomarkColors.blue));

    final content = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: defaultText,
          side: BorderSide(
            color: defaultBorder,
            width: isHighContrast ? 2.0 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: defaultText),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: isHighContrast ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14.5,
                color: defaultText,
              ),
            ),
          ],
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: content) : content;
  }
}

/// Botón Destructivo o de Alerta Roja (Para rechazos, descartes o emergencias)
class BiomarkDangerButton extends StatelessWidget {
  const BiomarkDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.warning_amber_rounded,
    this.height = 50.0,
    this.borderRadius = 16.0,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFEF4444);
    final content = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: dangerColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: content) : content;
  }
}

/// Botón Asistido por Voz (Micrófono Circular con Efecto de Marca)
class BiomarkVoiceButton extends StatelessWidget {
  const BiomarkVoiceButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
    this.tooltip = 'Hablar con el Asistente de Salud',
    this.size = 56.0,
  });

  final VoidCallback onPressed;
  final bool isListening;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final activeColor = isListening ? const Color(0xFFEF4444) : BiomarkColors.blue;

    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: isListening ? 0.5 : 0.3),
                  blurRadius: isListening ? 16 : 8,
                  spreadRadius: isListening ? 4 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de Filtro / Categoría Reutilizable (Pill Chip)
class BiomarkFilterChip extends StatelessWidget {
  const BiomarkFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.count,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = BiomarkColors.green;
    final unselectedBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final selectedFg = Colors.white;
    final unselectedFg = isDark ? Colors.white70 : const Color(0xFF334155);

    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? BiomarkColors.green
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? selectedFg : unselectedFg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedFg : unselectedFg,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? selectedFg : unselectedFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
