import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_shell.dart';
import '../../../biomark_brand.dart';
import '../../../core/notifications/push_notifications_service.dart';
import '../../../core/profile/user_profile_api.dart';
import '../../../health_survey.dart';
import '../../../survey_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  static const String prefKey = 'permissions_onboarding_shown';

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationGranted = false;
  bool _notificationDeniedForever = false;

  bool _locationGranted = false;
  bool _locationDeniedForever = false;

  bool _cameraGranted = false;
  bool _cameraDeniedForever = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // 1. Ubicación
    try {
      final locStatus = await Geolocator.checkPermission();
      setState(() {
        _locationGranted = locStatus == LocationPermission.always ||
            locStatus == LocationPermission.whileInUse;
        _locationDeniedForever = locStatus == LocationPermission.deniedForever;
      });
    } catch (_) {}

    // 2. Notificaciones
    try {
      final prefs = await SharedPreferences.getInstance();
      final pushEnabled = prefs.getBool(PushNotificationsService.pushEnabledKey) ?? false;
      setState(() {
        _notificationGranted = pushEnabled;
      });
    } catch (_) {}
  }

  Future<void> _requestNotification() async {
    final granted = await PushNotificationsService.instance.requestNotificationsPermission();
    if (mounted) {
      setState(() {
        _notificationGranted = granted;
        _notificationDeniedForever = !granted;
      });
    }
  }

  Future<void> _requestLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      final permanent = permission == LocationPermission.deniedForever;

      if (mounted) {
        setState(() {
          _locationGranted = granted;
          _locationDeniedForever = permanent;
        });
      }
    } catch (e) {
      debugPrint('Error solicitando ubicación: $e');
    }
  }

  Future<void> _requestCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (mounted) {
        setState(() {
          _cameraGranted = true;
          _cameraDeniedForever = false;
        });
      }
      if (photo != null) {
        // La foto de prueba no se necesita almacenar
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraGranted = false;
          _cameraDeniedForever = true;
        });
      }
    }
  }

  Future<void> _continuar() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionsScreen.prefKey, true);

    Widget destino = const AppShell();
    try {
      final profile = await UserProfileApi.fetch();
      final entrevistaHecha = profile?.entrevistaCompletada == true ||
          prefs.getBool(SurveyService.prefKeyEntrevistaCompletada) == true ||
          SurveyService.completado;

      if (entrevistaHecha) {
        destino = const AppShell();
      } else {
        destino = const HealthSurveyScreen(editing: false);
      }
    } catch (_) {
      destino = const AppShell();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, _) => destino,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : BiomarkColors.backgroundClaro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BiomarkColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: BiomarkColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Personaliza tu experiencia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Para ofrecerte alertas médicas en tiempo real, localización de hospitales y apoyo diagnóstico, activa estos accesos:',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Lista de permisos
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notificaciones y Alertas',
                      description: 'Recordatorios de tus tratamientos, citas y avisos epidemiológicos del MINSA.',
                      isGranted: _notificationGranted,
                      isPermanentDenied: _notificationDeniedForever,
                      onRequest: _requestNotification,
                      cardBg: cardBg,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 14),
                    _buildPermissionCard(
                      icon: Icons.location_on_rounded,
                      title: 'Ubicación Georreferenciada',
                      description: 'Descubre los hospitales y centros de salud más próximos en Managua con distancias reales.',
                      isGranted: _locationGranted,
                      isPermanentDenied: _locationDeniedForever,
                      onRequest: _requestLocation,
                      cardBg: cardBg,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 14),
                    _buildPermissionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Cámara y Análisis Visual',
                      description: 'Digitaliza recetas médicas, análisis de laboratorio y fotografías para orientación de la IA.',
                      isGranted: _cameraGranted,
                      isPermanentDenied: _cameraDeniedForever,
                      onRequest: _requestCamera,
                      cardBg: cardBg,
                      textDark: textDark,
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botón Continuar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BiomarkColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _continuar,
                  child: Text(
                    'Configurar más tarde',
                    style: TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isPermanentDenied,
    required VoidCallback onRequest,
    required Color cardBg,
    required Color textDark,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted
              ? BiomarkColors.primary.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.05),
          width: isGranted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? BiomarkColors.primary.withValues(alpha: 0.12)
                  : BiomarkColors.blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isGranted ? BiomarkColors.primary : BiomarkColors.blue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ),
                    if (isGranted)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: BiomarkColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isGranted && isPermanentDenied)
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Abrir Ajustes del Teléfono'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BiomarkColors.blue,
                      side: const BorderSide(color: BiomarkColors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else if (!isGranted)
                  ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BiomarkColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Permitir'),
                  )
                else
                  const Text(
                    'Activado correctamente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BiomarkColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
