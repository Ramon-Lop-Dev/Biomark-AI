// Superficie translúcida con efecto Glassmorphism (vidrio esmerilado) para Biomark AI.
// Diseñada para adaptarse a temas claro, oscuro y alto contraste (WCAG AAA).
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../biomark_brand.dart';
import 'app_themecontroller.dart';

class BiomarkGlassSurface extends StatelessWidget {
  const BiomarkGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blurSigma = 12.0,
    this.borderColor,
    this.backgroundColor,
    this.elevation = 0,
    this.onTap,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? borderColor;
  final Color? backgroundColor;
  final double elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = AppThemeController.instance.isHighContrast;
    final radius = borderRadius ?? BorderRadius.circular(22);

    // En modo alto contraste, se usan bordes sólidos y superficies opacas para garantizar ratio > 7:1
    if (isHighContrast) {
      final solidCard = Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2.0,
          ),
        ),
        child: child,
      );

      if (onTap != null) {
        return InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: solidCard,
        );
      }
      return solidCard;
    }

    // Colores y transparencias para Glassmorphism
    final defaultBg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.72);

    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.85);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : BiomarkColors.blue.withValues(alpha: 0.07);

    final surfaceContent = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18 + elevation * 4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    Widget result = margin != null
        ? Padding(padding: margin!, child: surfaceContent)
        : surfaceContent;

    if (onTap != null) {
      result = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: result,
      );
    }

    return result;
  }
}
