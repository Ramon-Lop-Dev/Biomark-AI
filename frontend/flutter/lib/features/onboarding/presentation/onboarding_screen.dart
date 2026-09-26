import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../biomark_brand.dart';
import '../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefKey = 'onboarding_educativo_visto';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      isLogo: true,
      title: 'BIOMARK AI',
      subtitle: 'Tu Copiloto Clínico y de Bienestar Integral',
      description:
          'Inteligencia artificial médica orientada a Nicaragua para acompañarte a ti y a tu familia en cada síntoma y decisión de salud.',
      badgeText: 'Salud Digital Inteligente',
    ),
    _OnboardingPageData(
      lottieAsset: 'assets/lottie/notificaciones.json',
      title: 'Seguimiento y Recordatorios',
      subtitle: 'Tratamientos y Alertas a Tiempo',
      description:
          'No olvides tus tomas de medicamentos ni tus citas. Recibe notificaciones automáticas y alertas epidemiológicas oficiales de tu zona.',
      badgeText: 'Alertas Médicas',
    ),
    _OnboardingPageData(
      lottieAsset: 'assets/lottie/geolocalizacion.json',
      title: 'Red de Salud en Managua',
      subtitle: 'Hospitales y Centros Cercanos',
      description:
          'Localiza al instante centros de salud y hospitales en Managua según tu proximidad, con rutas directas, horarios y servicios.',
      badgeText: 'Mapa Georreferenciado',
    ),
    _OnboardingPageData(
      lottieAsset: 'assets/lottie/camara.json',
      title: 'Diagnóstico Visual Asistido',
      subtitle: 'Lectura de Recetas y Análisis',
      description:
          'Captura recetas médicas, exámenes o fotografías de signos visibles para obtener una explicación clara e inmediata guiada por IA.',
      badgeText: 'Soporte Visual IA',
    ),
    _OnboardingPageData(
      lottieAsset: 'assets/lottie/doctor.json',
      title: 'Orientación Médica 24/7',
      subtitle: 'Atención Empática y Basada en Evidencia',
      description:
          'Consulta dudas sobre tus síntomas a cualquier hora. Información confiable, empática y segura siempre al alcance de tu mano.',
      badgeText: 'Asistencia Médica',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefKey, true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF0F172A),
              const Color(0xFF090D16),
            ]
          : [
              BiomarkColors.backgroundClaro,
              const Color(0xFFFFFFFF),
            ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior: Indicador y botón Saltar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          height: 6,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? BiomarkColors.primary
                                : Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text(
                          'Saltar',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 48),
                  ],
                ),
              ),

              // Contenido con PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return _buildPage(data, isDark);
                  },
                ),
              ),

              // Barra inferior: Botón Continuar / Empezar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BiomarkColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? 'Empezar ahora'
                              : 'Continuar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
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

  Widget _buildPage(_OnboardingPageData data, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: BiomarkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.badgeText,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: BiomarkColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, end: 0),

          const SizedBox(height: 24),

          // Ilustración: Logo oficial o Lottie animado
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Center(
              child: data.isLogo
                  ? Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: BiomarkColors.primary.withValues(alpha: 0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(
                        'assets/branding/Icono.png',
                        fit: BoxFit.contain,
                      ),
                    )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        duration: 1600.ms,
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1.04, 1.04),
                        curve: Curves.easeInOut,
                      )
                  : Lottie.asset(
                      data.lottieAsset!,
                      fit: BoxFit.contain,
                      width: 250,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: BiomarkColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            size: 64,
                            color: BiomarkColors.primary,
                          ),
                        );
                      },
                    ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

          const SizedBox(height: 28),

          // Título
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          // Subtítulo
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BiomarkColors.blue,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 14),

          // Descripción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final bool isLogo;
  final String? lottieAsset;
  final String title;
  final String subtitle;
  final String description;
  final String badgeText;

  const _OnboardingPageData({
    this.isLogo = false,
    this.lottieAsset,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badgeText,
  });
}
