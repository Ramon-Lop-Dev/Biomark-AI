// Arranca la aplicación y define la pantalla de autenticación inicial.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
import 'core/config/firebase_config.dart';
import 'core/design/app_themecontroller.dart';
import 'core/notifications/push_notifications_service.dart';
import 'core/profile/user_profile_api.dart';
import 'core/ui/biomark_dialog.dart';
import 'core/ui/loading_service.dart';
import 'features/onboarding/presentation/permissions_screen.dart';
import 'health_survey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'survey_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseConfig.initialize();
  await AuthSession.instance.init();
  await PushNotificationsService.instance.initialize();
  await SurveyService.cargarDesdeBackend();
  await ResetPasswordLinkListener.instance.init();
  await AppThemeController.instance.cargarGuardado();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder reconstruye el MaterialApp cada vez que el
    // usuario cambia de apariencia (claro/oscuro/sistema) en
    // AparienciaScreen, sin necesidad de un paquete externo como provider.
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Login Biomark',
          debugShowCheckedModeBanner: false,
          theme: AppThemeController.instance.currentLightTheme,
          darkTheme: biomarkDarkTheme,
          highContrastTheme: biomarkHighContrastTheme,
          themeMode: AppThemeController.instance.themeMode,
          builder: (context, child) => LoadingOverlay(child: child ?? const SizedBox.shrink()),
          home: const SplashScreen(),
        );
      },
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

  Animation<double> get _safeContentFade =>
      _animationsReady ? _contentFade : const AlwaysStoppedAnimation<double>(1);
  Animation<Offset> get _safeContentSlide => _animationsReady
      ? _contentSlide
      : const AlwaysStoppedAnimation<Offset>(Offset.zero);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgTop => _isDark ? const Color(0xFF0B111E) : BiomarkColors.backgroundClaro;
  Color get _bgMid => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get _bgBottom => _isDark ? const Color(0xFF050811) : BiomarkColors.backgroundClaro;
  Color get _primaryGreen => BiomarkColors.blue;
  Color get _textDark => _isDark ? Colors.white : BiomarkColors.black;
  Color get _textGray => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : BiomarkColors.white;

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
    if (isError) {
      await BiomarkDialog.showError(
        context,
        title: title,
        message: message,
        actionLabel: actionLabel,
      );
    } else {
      await BiomarkDialog.showSuccess(
        context,
        title: title,
        message: message,
        actionLabel: actionLabel,
      );
    }
  }

  Future<void> _navegarPostLogin() async {
    try {
      final profile = await UserProfileApi.fetch();
      final prefs = await SharedPreferences.getInstance();
      final permissionsShown = prefs.getBool(PermissionsScreen.prefKey) ?? false;
      final entrevistaHecha = profile?.entrevistaCompletada == true ||
          prefs.getBool(SurveyService.prefKeyEntrevistaCompletada) == true ||
          SurveyService.completado;

      if (!mounted) return;
      if (entrevistaHecha) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else if (!permissionsShown) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PermissionsScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HealthSurveyScreen(editing: false)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    BiomarkDialog.showLoading(
      context,
      title: 'Iniciando sesión',
      message: 'Verificando tus credenciales...',
    );
    try {
      final session = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await AuthSession.instance.saveSession(
        accessToken: session.token,
        refreshToken: session.refreshToken,
        expiresIn: session.expiresIn,
        role: session.role,
        userName: session.fullName,
        userEmail: session.email ?? _emailController.text.trim(),
      );

      if (!mounted) return;
      BiomarkDialog.hideLoading(context);
      await _navegarPostLogin();
    } on AuthApiException catch (error) {
      if (mounted) BiomarkDialog.hideLoading(context);
      await _showAuthDialog(
        title: 'No pudimos iniciar sesión',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } catch (_) {
      if (mounted) BiomarkDialog.hideLoading(context);
      await _showAuthDialog(
        title: 'No pudimos iniciar sesión',
        message: 'Ocurrió un error inesperado al iniciar sesión.',
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final google = await GoogleAuthHelper.signIn();
      if (google == null) return;
      if (!mounted) return;

      BiomarkDialog.showLoading(
        context,
        title: 'Iniciando sesión',
        message: 'Conectando con Google de forma segura...',
      );

      final session = await _authApi.loginWithGoogle(
        idToken: google.idToken,
        accessToken: google.accessToken,
        fullName: google.fullName,
      );
      await AuthSession.instance.saveSession(
        accessToken: session.token,
        refreshToken: session.refreshToken,
        expiresIn: session.expiresIn,
        role: session.role,
        userName: session.fullName,
        userEmail: session.email,
      );

      if (!mounted) return;
      BiomarkDialog.hideLoading(context);
      await _navegarPostLogin();
    } on AuthApiException catch (error) {
      if (mounted) BiomarkDialog.hideLoading(context);
      await _showAuthDialog(
        title: 'No pudimos conectar con Google',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } on GoogleAuthException catch (error) {
      if (mounted) BiomarkDialog.hideLoading(context);
      await _showAuthDialog(
        title: 'No pudimos conectar con Google',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } catch (_) {
      if (mounted) BiomarkDialog.hideLoading(context);
      await _showAuthDialog(
        title: 'No pudimos conectar con Google',
        message: 'Ocurrió un error inesperado al conectar con Google.',
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
            stops: const [0.0, 0.55, 1.0],
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
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
            color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
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
              ? _primaryGreen.withValues(alpha: _isDark ? 0.25 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: activo
              ? Border.all(
                  color: _primaryGreen.withValues(alpha: 0.35),
                  width: 1,
                )
              : null,
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.08),
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
            color: activo ? (_isDark ? const Color(0xFF60A5FA) : _primaryGreen) : _textDark,
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
        color: _isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.4 : 0.15),
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
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa tus credenciales para continuar',
          style: TextStyle(fontSize: 13, color: _textGray),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _isDark ? Colors.black.withValues(alpha: 0.4) : _primaryGreen.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          if (!_isDark)
            const BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              offset: Offset(-6, -6),
            ),
        ],
        border: Border.all(
          color: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.75),
        ),
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
                  color: _textGray,
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
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: _isDark ? const Color(0xFF60A5FA) : _primaryGreen,
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
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textDark,
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
        color: _isDark ? const Color(0xFF0F172A) : BiomarkColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
          if (!_isDark)
            const BoxShadow(
              color: Colors.white,
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
        ],
        border: Border.all(
          color: _isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: _textDark, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _textGray, size: 20),
          suffixIcon: suffixIcon,
          hintText: floatingHint ? null : hint,
          hintStyle: TextStyle(color: _textGray.withValues(alpha: 0.6)),
          floatingLabelBehavior: floatingHint
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
          labelText: floatingHint ? hint : null,
          floatingLabelStyle: TextStyle(
            color: _isDark ? const Color(0xFF60A5FA) : _primaryGreen,
          ),
          labelStyle: TextStyle(color: _textGray),
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
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _primaryGreen.withValues(alpha: _isDark ? 0.3 : 0.5),
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
        Expanded(child: Divider(color: _isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o continúa con',
            style: TextStyle(color: _textGray, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: _isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3))),
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
      icon: Icon(icon, size: 20, color: _textDark),
      label: Text(
        label,
        style: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: _isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
