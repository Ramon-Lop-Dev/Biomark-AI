import 'package:flutter/material.dart';

import 'main.dart'; // <-- ajusta este import al nombre real de tu archivo/clase de login

// ============================================================
// PALETA (reutiliza AppColors si ya la tienes en otro archivo;
// si home_screen.dart ya define AppColors, borra este bloque
// y solo deja el import de ese archivo para no duplicar).
// ============================================================
class SplashColors {
  static const bg = Color(0xFFEEF3FC);
  static const blue = Color(0xFF2D6CDF);
  static const blueDark = Color(0xFF1E4FA3);
  static const textDark = Color(0xFF1E1E2D);
  static const textGrey = Color(0xFF8A8A9A);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: 0.94,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..forward(),
        curve: Curves.easeIn,
      ),
    );

    _irALogin();
  }

  Future<void> _irALogin() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red, // <-- SOLO PARA PROBAR
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---- Logo claymorfismo con pulso ----
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: SplashColors.bg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      // sombra clara arriba-izquierda (relieve)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.95),
                        blurRadius: 16,
                        offset: const Offset(-8, -8),
                      ),
                      // sombra oscura abajo-derecha (hundido)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(8, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [SplashColors.blue, SplashColors.blueDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SplashColors.blue.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Biomark AI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SplashColors.textDark,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuidando tu salud, siempre contigo',
                style: TextStyle(fontSize: 12.5, color: SplashColors.textGrey),
              ),
              const SizedBox(height: 42),
              const _ClayLoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INDICADOR DE CARGA — 3 puntos clay que rebotan en cascada
// ============================================================
class _ClayLoadingDots extends StatefulWidget {
  const _ClayLoadingDots();

  @override
  State<_ClayLoadingDots> createState() => _ClayLoadingDotsState();
}

class _ClayLoadingDotsState extends State<_ClayLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final bounce = (t < 0.5)
                ? Curves.easeOut.transform(t * 2)
                : Curves.easeIn.transform(1 - (t - 0.5) * 2);
            final offsetY = -10.0 * bounce;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SplashColors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: SplashColors.blue.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
