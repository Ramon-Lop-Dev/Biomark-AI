import 'package:flutter/material.dart';

import 'main.dart'; 
import 'app_shell.dart';
import 'forgot_password.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'core/auth/reset_password_link_listener.dart';

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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _fadeController;
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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _irALogin();
  }

  Future<void> _irALogin() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    if (ResetPasswordLinkListener.instance.pendingAccessToken != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
      );
      return;
    }
    var hasSession = AuthSession.instance.isLoggedIn;
    if (hasSession && AuthSession.instance.isExpired) {
      final refreshToken = AuthSession.instance.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        await AuthSession.instance.clear();
        hasSession = false;
      } else {
        final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
        try {
          final session = await authApi.refresh(refreshToken: refreshToken);
          await AuthSession.instance.saveSession(
            accessToken: session.token,
            refreshToken: session.refreshToken,
            expiresIn: session.expiresIn,
          );
        } catch (_) {
          await AuthSession.instance.clear();
          hasSession = false;
        } finally {
          authApi.dispose();
        }
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) => hasSession ? const AppShell() : const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 221, 229, 234),
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
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: SplashColors.bg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      // sombra clara arriba-izquierda (relieve)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        blurRadius: 16,
                        offset: const Offset(-8, -8),
                      ),
                      // sombra oscura abajo-derecha (hundido)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(8, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/branding/Logo_Vertical.png',
                      width: 180,
                      fit: BoxFit.contain,
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
                  color: Color.fromARGB(255, 11, 145, 27),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuidando tu salud, siempre contigo',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color.fromARGB(255, 88, 83, 83),
                ),
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
                        color: SplashColors.blue.withValues(alpha: 0.35),
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
