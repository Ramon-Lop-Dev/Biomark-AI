// Insignias (Badges) y Etiquetas de Estado para Biomark AI
// Coherente con los protocolos de triaje CCM (MINSA) y gobernanza institucional en cascada
import 'package:flutter/material.dart';
import '../../../biomark_brand.dart';
import '../../design/app_themecontroller.dart';

/// Insignia Semafórica de Triaje Comunitario CCM
class BiomarkTriageBadge extends StatelessWidget {
  const BiomarkTriageBadge({
    super.key,
    required this.level,
    this.showIcon = true,
    this.dense = false,
  });

  /// 'ROJO', 'AMARILLO' o 'VERDE'
  final String level;
  final bool showIcon;
  final bool dense;

  Color get _color {
    switch (level.toUpperCase()) {
      case 'ROJO':
        return const Color(0xFFEF4444);
      case 'AMARILLO':
        return const Color(0xFFF59E0B);
      case 'VERDE':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData get _icon {
    switch (level.toUpperCase()) {
      case 'ROJO':
        return Icons.emergency_rounded;
      case 'AMARILLO':
        return Icons.warning_amber_rounded;
      case 'VERDE':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String get _label {
    switch (level.toUpperCase()) {
      case 'ROJO':
        return 'Urgencia (Rojo)';
      case 'AMARILLO':
        return 'Alerta (Amarillo)';
      case 'VERDE':
      default:
        return 'Rutinario (Verde)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isHighContrast = AppThemeController.instance.isHighContrast;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.white : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast ? Colors.black : color.withValues(alpha: 0.5),
          width: isHighContrast ? 2.0 : 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon, size: dense ? 13 : 15, color: isHighContrast ? Colors.black : color),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
              color: isHighContrast ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignia de Rol Institucional Biomark AI
class BiomarkRoleBadge extends StatelessWidget {
  const BiomarkRoleBadge({
    super.key,
    required this.role,
  });

  /// 'ADMIN', 'TRABAJADOR_SALUD', 'PROMOTOR', 'USUARIO'
  final String role;

  String get _roleName {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'SILAIS Managua';
      case 'TRABAJADOR_SALUD':
        return 'Médico / MINSA';
      case 'PROMOTOR':
        return 'Promotor de Salud';
      case 'USUARIO':
      default:
        return 'Ciudadano';
    }
  }

  Color get _roleColor {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFF6366F1);
      case 'TRABAJADOR_SALUD':
        return BiomarkColors.blue;
      case 'PROMOTOR':
        return BiomarkColors.green;
      case 'USUARIO':
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData get _roleIcon {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      case 'TRABAJADOR_SALUD':
        return Icons.local_hospital_rounded;
      case 'PROMOTOR':
        return Icons.groups_rounded;
      case 'USUARIO':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            _roleName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignia de Estado de Conectividad / Sincronización Offline
class BiomarkSyncBadge extends StatelessWidget {
  const BiomarkSyncBadge({
    super.key,
    required this.isOnline,
    this.pendingSyncCount = 0,
  });

  final bool isOnline;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? BiomarkColors.green : const Color(0xFFF59E0B);
    final text = isOnline
        ? 'En línea'
        : (pendingSyncCount > 0
            ? 'Modo sin red ($pendingSyncCount pendientes)'
            : 'Modo sin red');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
