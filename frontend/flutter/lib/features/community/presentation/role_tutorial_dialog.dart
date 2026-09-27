import 'package:flutter/material.dart';

import '../../../biomark_brand.dart';
import '../../../core/auth/auth_session.dart';

class _TutorialStep {
  final IconData icon;
  final Color color;
  final String badge;
  final String title;
  final String description;
  final List<String> bulletPoints;

  const _TutorialStep({
    required this.icon,
    required this.color,
    required this.badge,
    required this.title,
    required this.description,
    this.bulletPoints = const [],
  });
}

/// Diálogo interactivo de bienvenida y tutorial guiado según el rol del usuario.
/// Cumple estrictamente con el protocolo anti-overflow (softWrap, Expanded y altura dinámica).
class RoleTutorialDialog extends StatefulWidget {
  const RoleTutorialDialog({
    super.key,
    this.initialRole,
  });

  final String? initialRole;

  static Future<void> show(BuildContext context, {String? initialRole}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoleTutorialDialog(initialRole: initialRole),
    );
  }

  @override
  State<RoleTutorialDialog> createState() => _RoleTutorialDialogState();
}

class _RoleTutorialDialogState extends State<RoleTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late final String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole ?? AuthSession.instance.role;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_TutorialStep> _getStepsForRole(String role) {
    switch (role) {
      case 'ADMIN':
        return const [
          _TutorialStep(
            icon: Icons.security_rounded,
            color: BiomarkColors.blue,
            badge: 'SILAIS MANAGUA · COMANDO',
            title: 'Centro de Mando Departamental',
            description:
                'Como Director o Administrador del SILAIS Managua, tienes acceso al monitoreo en tiempo real de todos los centros de salud, brotes epidémicos y reportes de la capital.',
            bulletPoints: [
              'Vigilancia epidemiológica continua en todos los distritos de Managua.',
              'Auditoría y trazabilidad oficial de todas las intervenciones sanitarias.',
              'Gestión centralizada del estado de alertas y pautas normativas.',
            ],
          ),
          _TutorialStep(
            icon: Icons.vpn_key_rounded,
            color: BiomarkColors.green,
            badge: 'ACREDITACIÓN RÁPIDA (1 CLIC)',
            title: 'Emisión de Pases Oficiales',
            description:
                'Genera códigos de acreditación institucionales para Médicos, Enfermeros y Promotores seleccionando el centro de salud de adscripción.',
            bulletPoints: [
              'Sin pedir correos ni formularios engorrosos: genera el token al instante.',
              'Botón directo para copiar y enviar el código por WhatsApp, SMS o en persona.',
              'Vigencia de 7 días con registro automático de auditoría sanitaria.',
            ],
          ),
          _TutorialStep(
            icon: Icons.supervised_user_circle_rounded,
            color: Color(0xFF0253A6),
            badge: 'SUPERVISIÓN TERRITORIAL',
            title: 'Red Departamental de Promotores',
            description:
                'Supervisa el estado y desempeño de los brigadistas comunitarios adscritos a cada uno de los centros de salud de Managua.',
            bulletPoints: [
              'Visualiza a qué centro de salud pertenece cada brigadista.',
              'Activa o suspende permisos comunitarios en tiempo real.',
              'Seguimiento directo a los reportes de campo de cada sector.',
            ],
          ),
          _TutorialStep(
            icon: Icons.campaign_rounded,
            color: Color(0xFFD97706),
            badge: 'DIRECTRICES MINSA',
            title: 'Pautas Sanitarias y Alertas',
            description:
                'Publica recomendaciones oficiales, pautas clínicas y avisos a la población respaldados por las normativas vigentes del MINSA.',
            bulletPoints: [
              'Avisos prioritarios visibles en la pantalla principal de los ciudadanos.',
              'Guías clínicas de referencia para el personal de salud.',
              'Protocolos de prevención de dengue, leptospirosis y patologías estacionales.',
            ],
          ),
        ];

      case 'TRABAJADOR_SALUD':
        return const [
          _TutorialStep(
            icon: Icons.local_hospital_rounded,
            color: BiomarkColors.blue,
            badge: 'MINSA · ATENCIÓN CLÍNICA',
            title: 'Centro de Mando Local',
            description:
                'Tu cuenta está adscrita a tu Centro de Salud. Desde aquí coordinas la atención médica, la supervisión de campo y la verificación de brotes en tu sector.',
            bulletPoints: [
              'Vinculación institucional oficial con tu establecimiento de salud.',
              'Acceso privilegiado al triaje de sospechas comunitarias.',
              'Coordinación directa con brigadistas asignados a tu territorio.',
            ],
          ),
          _TutorialStep(
            icon: Icons.checklist_rounded,
            color: BiomarkColors.green,
            badge: 'TRIAJE CLÍNICO CCM',
            title: 'Validación de Casos en Terreno',
            description:
                'Revisa los reportes de sospechas epidemiológicas enviados por los promotores casa a casa y valida o descarta con criterio clínico.',
            bulletPoints: [
              'Clasificación por severidad: Verde (Leve), Amarillo (Moderado), Rojo (Grave).',
              'Validación formal que actualiza el mapa epidemiológico oficial.',
              'Detección oportuna de signos de alarma para traslado inmediato.',
            ],
          ),
          _TutorialStep(
            icon: Icons.people_outline_rounded,
            color: Color(0xFF0253A6),
            badge: 'EQUIPO DE CAMPO',
            title: 'Acreditar y Coordinar Promotores',
            description:
                'Emite códigos de acreditación para los brigadistas de tu comunidad para que reporten sospechas directamente a tu centro.',
            bulletPoints: [
              'Genera pases institucionales para los líderes comunitarios de tu barrio.',
              'Los promotores quedan automáticamente vinculados a tu centro de salud.',
              'Supervisa la actividad de visitas y alertas levantadas en el terreno.',
            ],
          ),
          _TutorialStep(
            icon: Icons.map_rounded,
            color: Color(0xFFEF4444),
            badge: 'VIGILANCIA EPIDEMIOLÓGICA',
            title: 'Mapa de Riesgo y Jornadas',
            description:
                'Monitorea focos de calor infecciosos y coordina jornadas comunitarias de fumigación, abatización y vacunación.',
            bulletPoints: [
              'Visualización satelital de casos activos confirmados en Managua.',
              'Planificación de jornadas de prevención en barrios priorizados.',
              'Convocatoria y registro de eventos de salud pública.',
            ],
          ),
        ];

      case 'PROMOTOR':
        return const [
          _TutorialStep(
            icon: Icons.volunteer_activism_rounded,
            color: BiomarkColors.green,
            badge: 'BRIGADISTA COMUNITARIO MINSA',
            title: 'Vigilancia en Terreno y Comunidad',
            description:
                'Eres el pilar fundamental de la prevención en tu barrio. Tu labor conecta a las familias con el Centro de Salud para salvar vidas.',
            bulletPoints: [
              'Visitas casa a casa para detección temprana de personas con fiebre.',
              'Identificación y eliminación de criaderos de zancudos y focos de riesgo.',
              'Orientación a las familias para no automedicarse y acudir al centro.',
            ],
          ),
          _TutorialStep(
            icon: Icons.add_location_alt_rounded,
            color: BiomarkColors.blue,
            badge: 'REPORTE CCM EN VIVO',
            title: 'Registro de Reportes Comunitarios',
            description:
                'Cuando detectes sospechas de dengue, diarrea o leptospirosis en una vivienda, regístralas de inmediato con su ubicación exacta.',
            bulletPoints: [
              'Geolocalización automática de la vivienda en el mapa.',
              'Evaluación guiada de signos de alarma (Triaje Comunitario).',
              'Envío inmediato al médico de tu Centro de Salud para su validación.',
            ],
          ),
          _TutorialStep(
            icon: Icons.event_available_rounded,
            color: Color(0xFFD97706),
            badge: 'JORNADAS DE SALUD',
            title: 'Jornadas de Vacunación y Limpieza',
            description:
                'Participa y convoca a tu comunidad a jornadas de vacunación, fumigación casa a casa y aplicación de abate en pilas y barriles.',
            bulletPoints: [
              'Consulta las fechas y sectores programados para intervención.',
              'Acompaña a las brigadas de fumigación en tu sector.',
              'Verifica que los hogares queden protegidos contra epidemias.',
            ],
          ),
          _TutorialStep(
            icon: Icons.health_and_safety_rounded,
            color: Color(0xFF003875),
            badge: 'RESPALDO OFICIAL',
            title: 'Coordinación con tu Centro de Salud',
            description:
                'Cuentas con el respaldo y la supervisión del Centro de Salud de tu sector para actuar ante emergencias y casos graves.',
            bulletPoints: [
              'Canal directo de comunicación para reportar alertas rojas.',
              'Acceso continuo a guías y pautas de prevención del MINSA.',
              'Reconocimiento formal de tu rol como promotor acreditado.',
            ],
          ),
        ];

      default: // USUARIO
        return const [
          _TutorialStep(
            icon: Icons.health_and_safety_rounded,
            color: BiomarkColors.blue,
            badge: 'BIOMARK AI · CIUDADANO',
            title: 'Tu Copiloto de Salud Familiar',
            description:
                'Bienvenido a BIOMARK AI. Una plataforma diseñada para orientar y proteger la salud de tu familia con base médica adaptada a Nicaragua.',
            bulletPoints: [
              'Orientación médica 24/7 impulsada por inteligencia artificial clínica.',
              'Reconocimiento de síntomas y lectura explicativa de recetas.',
              'Recordatorios automáticos para tus tomas de medicamentos.',
            ],
          ),
          _TutorialStep(
            icon: Icons.map_rounded,
            color: Color(0xFFEF4444),
            badge: 'MAPA EPIDEMIOLÓGICO',
            title: 'Alertas de Brotes en Managua',
            description:
                'Conoce en tiempo real qué enfermedades están circulando en los barrios de Managua y ubica los Centros de Salud y Hospitales más cercanos.',
            bulletPoints: [
              'Zonas de riesgo y brotes activos de dengue y leptospirosis.',
              'Rutas, teléfonos y servicios de centros de salud en la capital.',
              'Medidas preventivas aprobadas por el MINSA para tu hogar.',
            ],
          ),
          _TutorialStep(
            icon: Icons.notifications_active_rounded,
            color: Color(0xFFD97706),
            badge: 'PREVENCIÓN OFICIAL',
            title: 'Avisos y Jornadas del MINSA',
            description:
                'Entérate de las jornadas gratuitas de vacunación, fumigación en tu barrio y recomendaciones del Ministerio de Salud.',
            bulletPoints: [
              'Fechas oficiales de jornadas de salud comunitaria.',
              'Consejos de hidratación y manejo de fiebres en niños y adultos.',
              'Pautas normativas para proteger a tu familia ante brotes.',
            ],
          ),
          _TutorialStep(
            icon: Icons.vpn_key_rounded,
            color: BiomarkColors.green,
            badge: 'ACREDITACIÓN SANITARIA',
            title: '¿Eres Brigadista o Médico?',
            description:
                'Para proteger la veracidad epidemiológica, la validación de brotes requiere acreditación formal emitida por un Centro de Salud.',
            bulletPoints: [
              'Si tu Centro de Salud te entregó un código, canjéalo en tu Perfil.',
              'Tu cuenta se convertirá al instante en Promotor o Personal de Salud.',
              'Si eres voluntario o líder comunitario, solicítalo en tu centro cercano.',
            ],
          ),
        ];
    }
  }

  void _nextPage(int total) {
    if (_currentIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getStepsForRole(_role);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera con título e icono de cierre
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BiomarkColors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: BiomarkColors.blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Guía y Tutorial de la Aplicación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      softWrap: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Carrusel de Pasos
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (ctx, index) {
                  final step = steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge con categoría
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: step.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: step.color.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            step.badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: step.color,
                              letterSpacing: 0.5,
                            ),
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Icono y Título
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: step.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step.icon, color: step.color, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Descripción General
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 16),

                        // Puntos Clave
                        if (step.bulletPoints.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: step.bulletPoints.map((point) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(Icons.check_circle_rounded, color: step.color, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Barra inferior con indicadores y botones de navegación
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  // Indicadores de página
                  Row(
                    children: List.generate(steps.length, (idx) {
                      final isActive = idx == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: isActive ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? BiomarkColors.blue : Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // Botón Anterior
                  if (_currentIndex > 0) ...[
                    TextButton(
                      onPressed: _prevPage,
                      child: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Botón Siguiente / Empezar
                  FilledButton(
                    onPressed: () => _nextPage(steps.length),
                    style: FilledButton.styleFrom(
                      backgroundColor: BiomarkColors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _currentIndex == steps.length - 1 ? '¡Entendido!' : 'Siguiente',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
