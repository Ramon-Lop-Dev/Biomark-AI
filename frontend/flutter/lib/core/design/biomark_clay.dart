// Proporciona superficies reutilizables con estilo claymorphism corporativo.
import 'package:flutter/material.dart';

import '../../biomark_brand.dart';

class BiomarkClay {
  const BiomarkClay._();

  static BoxDecoration surface({
    Color color = BiomarkColors.white,
    double radius = 18,
    bool inset = false,
  }) {
    final shadowColor = BiomarkColors.black.withValues(alpha: 0.08);
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: inset ? shadowColor : BiomarkColors.white,
          blurRadius: inset ? 10 : 14,
          offset: inset ? const Offset(3, 4) : const Offset(-4, -4),
        ),
        if (!inset)
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(4, 6),
          ),
      ],
    );
  }
}

class BiomarkClaySurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  const BiomarkClaySurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = BiomarkColors.white,
    this.radius = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BiomarkClay.surface(color: color, radius: radius),
      child: child,
    );
  }
}
