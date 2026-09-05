import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_biomark/main.dart'; // <-- para navegar de vuelta a LoginScreen
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';

/// ---------------------------------------------------------------
/// REGISTER SCREEN — mismo estilo "claymorfismo" que el login,
/// con pestañas Iniciar Sesión / Registrarse arriba (igual que login)
/// ---------------------------------------------------------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
  with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final String _accountType = 'PERSONAL';
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

  // Fondo con más carácter — degradado en tonos azules de marca
  static const Color bgTop = Color.fromARGB(255, 244, 245, 246);
  static const Color bgMid = Color.fromARGB(255, 239, 239, 240);
  static const Color accentBlue = Color.fromARGB(
    255,
    50,
    96,
    169,
  ); // azul de marca
  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color.fromARGB(255, 36, 36, 37);

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          color: isError ? Colors.redAccent : accentBlue,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: isError ? Colors.redAccent : accentBlue,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _irALogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authApi.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        accountType: _accountType,
      );
      if (result.token != null && result.token!.isNotEmpty) {
        await AuthSession.instance.saveSession(
          accessToken: result.token!,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn ?? 3600,
        );
      }
      if (!mounted) return;
      final requiresConfirmation = result.requiresEmailConfirmation;
      await _showAuthDialog(
        title: requiresConfirmation ? '¡Cuenta creada!' : '¡Registro exitoso!',
        message: requiresConfirmation
            ? 'Revisa tu correo para confirmar la cuenta antes de iniciar sesión.'
            : 'Tu cuenta de Biomark AI está lista.',
        icon: Icons.check_circle_outline_rounded,
        actionLabel: 'Ir a iniciar sesión',
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on AuthApiException catch (error) {
      await _showAuthDialog(
        title: 'No pudimos crear tu cuenta',
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
            colors: [bgTop, bgMid, Color.fromARGB(255, 244, 245, 243)],
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGlassTabItem(
                  texto: 'Iniciar Sesión',
                  activo: false,
                  onTap: _irALogin,
                ),
              ),
              Expanded(
                child: _buildGlassTabItem(
                  texto: 'Registrarse',
                  activo: true,
                  onTap: () {},
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
          color: activo ? accentBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: activo
              ? Border.all(color: accentBlue.withValues(alpha: 0.35), width: 1)
              : null,
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: accentBlue.withValues(alpha: 0.08),
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
            color: activo ? accentBlue : textDark,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------- TÍTULO ----------------
  Widget _buildTitle() {
    return Text(
      'Completa tus datos para registrarte',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13.5, color: textGray),
    );
  }

  // ---------------- TARJETA CON EL FORMULARIO ----------------
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 11, 8, 99).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          const BoxShadow(
            color: Color.fromARGB(232, 189, 193, 193),
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
            _buildLabel('Nombre completo'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _nameController,
              hint: 'Tu nombre completo',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu nombre completo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('Correo electrónico'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _emailController,
              hint: 'tunombre123@gmail.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!value.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                  return 'Ingresa una contraseña';
                }
                if (value.length < 8) {
                  return 'Mínimo 8 caracteres';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                  return 'Debe incluir al menos una letra';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Debe incluir al menos un número';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('Confirmar contraseña'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _confirmPasswordController,
              hint: '••••••••••',
              icon: Icons.lock_outline_rounded,
              floatingHint: false,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textGray,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildRegisterButton(),
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

  // Campo de texto con efecto "clay" — idéntico al del login
  Widget _buildClayTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool floatingHint = true,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
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
        readOnly: readOnly,
        onTap: onTap,
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
          floatingLabelStyle: TextStyle(color: accentBlue.withValues(alpha: 0.9)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // Botón principal
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: accentBlue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Registrarme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

}
