// Arranca la aplicación y define la pantalla de autenticación inicial.
import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'biomark_brand.dart';
import 'register_screen.dart';
import 'dart:ui';
import 'loading.dart';
import 'forgot_password.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/auth/google_auth_helper.dart';
import 'core/auth/reset_password_link_listener.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.init();
  await ResetPasswordLinkListener.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Biomark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Syne', // opcional: agrega la fuente en pubspec.yaml
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
  with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final _authApi = AuthApi(baseUrl: AppConfig.apiUrl);
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
    bool _animationsReady = false;

    Animation<double> get _safeContentFade => _animationsReady
      ? _contentFade
      : const AlwaysStoppedAnimation<double>(1);
    Animation<Offset> get _safeContentSlide => _animationsReady
      ? _contentSlide
      : const AlwaysStoppedAnimation<Offset>(Offset.zero);

  static const Color bgTop = BiomarkColors.white;
  static const Color bgMid = BiomarkColors.white;
  static const Color bgBottom = BiomarkColors.white;
  static const Color primaryGreen = BiomarkColors.blue;
  static const Color textDark = BiomarkColors.black;
  static const Color textGray = BiomarkColors.black;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    final curve = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _contentFade = curve;
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);
    _animationsReady = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authApi.dispose();
    if (_animationsReady) _entranceController.dispose();
    super.dispose();
  }

  Future<void> _showAuthDialog({
    required String title,
    required String message,
    required IconData icon,
    String actionLabel = 'Continuar',
    bool isError = false,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        surfaceTintColor: Colors.white,
        icon: Icon(
          icon,
          size: 46,
          color: isError ? Colors.redAccent : primaryGreen,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: isError ? Colors.redAccent : primaryGreen,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await AuthSession.instance.saveSession(
        accessToken: session.token,
        refreshToken: session.refreshToken,
        expiresIn: session.expiresIn,
      );
      if (!mounted) return;
      await _showAuthDialog(
        title: '¡Bienvenido!',
        message: 'Has iniciado sesión correctamente en Biomark AI.',
        icon: Icons.check_circle_outline_rounded,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } on AuthApiException catch (error) {
      await _showAuthDialog(
        title: 'No pudimos iniciar sesión',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final google = await GoogleAuthHelper.signIn();
      if (google == null) return;
      final session = await _authApi.loginWithGoogle(
        idToken: google.idToken,
        accessToken: google.accessToken,
        fullName: google.fullName,
      );
      await AuthSession.instance.saveSession(
        accessToken: session.token,
        refreshToken: session.refreshToken,
        expiresIn: session.expiresIn,
      );
      if (!mounted) return;
      await _showAuthDialog(
        title: '¡Bienvenido!',
        message: 'Tu cuenta de Google está lista para usar Biomark AI.',
        icon: Icons.check_circle_outline_rounded,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } on AuthApiException catch (error) {
      await _showAuthDialog(
        title: 'No pudimos conectar Google',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } on GoogleAuthException catch (error) {
      await _showAuthDialog(
        title: 'No pudimos conectar Google',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgMid, bgBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            children: [
                              const SizedBox(height: 28),
                              FadeTransition(
                                opacity: _safeContentFade,
                                child: _buildLogo(),
                              ),
                              const SizedBox(height: 20),
                              FadeTransition(
                                opacity: _safeContentFade,
                                child: _buildAuthTabs(),
                              ),
                              const SizedBox(height: 20),
                              SlideTransition(
                                position: _safeContentSlide,
                                child: FadeTransition(
                                  opacity: _safeContentFade,
                                  child: _buildTitle(),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SlideTransition(
                                position: _safeContentSlide,
                                child: FadeTransition(
                                  opacity: _safeContentFade,
                                  child: _buildFormCard(),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- PESTAÑAS INICIAR SESIÓN / REGISTRARSE (glassmorfismo) ----------------
  Widget _buildAuthTabs() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGlassTabItem(
                  texto: 'Iniciar Sesión',
                  activo: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _buildGlassTabItem(
                  texto: 'Registrarse',
                  activo: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTabItem({
    required String texto,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo
              ? primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: activo
              ? Border.all(
                  color: primaryGreen.withValues(alpha: 0.35),
                  width: 1,
                )
              : null,
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: activo ? primaryGreen : textDark,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------- LOGO ----------------
  Widget _buildLogo() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/branding/Icono.png',
          width: 90,
          height: 96,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ---------------- TÍTULO ----------------
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Iniciar Sesión ',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa tus credenciales para continuar',
          style: TextStyle(fontSize: 13, color: textGray),
        ),
      ],
    );
  }

  // ---------------- TARJETA CON EL FORMULARIO (efecto clay) ----------------
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BiomarkColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // sombra oscura abajo-derecha
          BoxShadow(
            color: BiomarkColors.blue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          // "luz" arriba-izquierda (lo que da el efecto clay)
          const BoxShadow(
            color: Colors.white,
            blurRadius: 20,
            offset: Offset(-6, -6),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Correo electrónico'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _emailController,
              hint: 'tunombre123@gmail.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!value.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('Contraseña'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _passwordController,
              hint: '••••••••••',
              icon: Icons.lock_outline_rounded,
              floatingHint: false,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textGray,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ), //
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: BiomarkColors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLoginButton(),
            const SizedBox(height: 22),
            _buildDivider(),
            const SizedBox(height: 18),
            _buildSocialButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    );
  }

  // Campo de texto con efecto "clay" (relieve suave)
  Widget _buildClayTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool floatingHint = true,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BiomarkColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-2, -2),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: textDark, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: textGray, size: 20),
          suffixIcon: suffixIcon,
            hintText: floatingHint ? null : hint,
            floatingLabelBehavior: floatingHint
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
            labelText: floatingHint ? hint : null,
          floatingLabelStyle: TextStyle(color: primaryGreen.withValues(alpha: 0.9)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // Botón principal (degradado + sombra tipo "pill")
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Iniciar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continúa con',
            style: TextStyle(color: textGray, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: _handleGoogleLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _socialButton(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: textDark),
      label: Text(
        label,
        style: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
