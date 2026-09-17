import 'package:flutter/material.dart';

/// Puntos de ruptura (breakpoints) estándar para Biomark AI
class ResponsiveBreakpoints {
  static const double mobileMax = 650;
  static const double tabletMax = 1050;
  static const double desktopMax = 1400;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax;
}

/// Contenedor que centra el contenido en pantallas anchas (web / desktop / tablet)
/// y permite que fluya de manera 100% natural en dispositivos móviles.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 950,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    if (isMobile) {
      return padding != null ? Padding(padding: padding!, child: child) : child;
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
