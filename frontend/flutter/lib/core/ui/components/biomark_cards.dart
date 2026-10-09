// Biblioteca de Tarjetas (Cards) Reutilizables de Biomark AI
// Coherente con tipografías Syne/Poppins, paleta Biomark y soporte WCAG 2.1 AA/AAA
import 'package:flutter/material.dart';
import '../../../biomark_brand.dart';
import '../../design/biomark_glass_surface.dart';
import '../../design/app_themecontroller.dart';

/// Tarjeta de Medición de Pulso y Signos Vitales (SCG / PPG)
class BiomarkVitalPulseCard extends StatelessWidget {
  const BiomarkVitalPulseCard({
    super.key,
    required this.bpm,
    required this.statusLabel,
    required this.isNormal,
    this.recordedAt,
    this.onMeasureTap,
  });

  final int? bpm;
  final String statusLabel;
  final bool isNormal;
  final String? recordedAt;
  final VoidCallback? onMeasureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = AppThemeController.instance.isHighContrast;

    final statusColor = isNormal ? BiomarkColors.green : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.white
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighContrast
              ? Colors.black
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isHighContrast ? 2.0 : 1.2,
        ),
        boxShadow: isHighContrast
            ? []
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : BiomarkColors.blue.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Frecuencia Cardíaca',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bpm != null ? '$bpm' : '--',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w900,
                  fontSize: 42,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LPM (latidos por minuto)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (recordedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Último registro: $recordedAt',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
          if (onMeasureTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onMeasureTap,
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: const Text(
                  'Tomar Medición SCG',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BiomarkColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de Estado de Triaje Comunitario CCM (Rojo, Amarillo, Verde)
class BiomarkTriageStatusCard extends StatelessWidget {
  const BiomarkTriageStatusCard({
    super.key,
    required this.nivelTriaje,
    required this.titulo,
    required this.descripcion,
    this.centroSaludAsignado,
    this.accionLabel,
    this.onAccionTap,
  });

  /// 'ROJO', 'AMARILLO' o 'VERDE'
  final String nivelTriaje;
  final String titulo;
  final String descripcion;
  final String? centroSaludAsignado;
  final String? accionLabel;
  final VoidCallback? onAccionTap;

  Color get _triageColor {
    switch (nivelTriaje.toUpperCase()) {
      case 'ROJO':
        return const Color(0xFFEF4444);
      case 'AMARILLO':
        return const Color(0xFFF59E0B);
      case 'VERDE':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData get _triageIcon {
    switch (nivelTriaje.toUpperCase()) {
      case 'ROJO':
        return Icons.warning_rounded;
      case 'AMARILLO':
        return Icons.info_rounded;
      case 'VERDE':
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _triageColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(_triageIcon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nivelTriaje.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            descripcion,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          if (centroSaludAsignado != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_hospital_rounded, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  'Jurisdicción: $centroSaludAsignado',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
          if (accionLabel != null && onAccionTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAccionTap,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color, width: 1.5),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  accionLabel!,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta Informativa / Artículo de Salud MINSA
class BiomarkHealthCard extends StatelessWidget {
  const BiomarkHealthCard({
    super.key,
    required this.title,
    required this.category,
    required this.summary,
    this.readTimeMinutes = 3,
    this.icon = Icons.health_and_safety_rounded,
    this.onTap,
  });

  final String title;
  final String category;
  final String summary;
  final int readTimeMinutes;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BiomarkGlassSurface(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BiomarkColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: BiomarkColors.green,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    '$readTimeMinutes min',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        height: 1.35,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BiomarkColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: BiomarkColors.blue, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de Jornada Comunitaria / Evento Barrial
class BiomarkEventCard extends StatelessWidget {
  const BiomarkEventCard({
    super.key,
    required this.title,
    required this.dateText,
    required this.location,
    required this.organizer,
    this.onViewMapTap,
  });

  final String title;
  final String dateText;
  final String location;
  final String organizer;
  final VoidCallback? onViewMapTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Bloque de Fecha
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: BiomarkColors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_rounded, color: BiomarkColors.blue, size: 20),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: BiomarkColors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Información del evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.place_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Organiza: $organizer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (onViewMapTap != null)
            IconButton(
              onPressed: onViewMapTap,
              icon: const Icon(Icons.map_rounded, color: BiomarkColors.blue),
              tooltip: 'Ver en mapa',
            ),
        ],
      ),
    );
  }
}
