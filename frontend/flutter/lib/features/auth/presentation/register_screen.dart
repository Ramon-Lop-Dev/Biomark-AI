import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_biomark/main.dart';
import 'package:flutter_biomark/core/auth/auth_api.dart';
import 'package:flutter_biomark/core/auth/auth_session.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
import 'package:flutter_biomark/core/ui/loading_service.dart';
import 'package:flutter_biomark/features/onboarding/presentation/permissions_screen.dart';
import '../../community/data/invitations_api.dart';
import '../../../app_shell.dart';
import '../../../biomark_brand.dart';
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgTop => _isDark ? const Color(0xFF0B111E) : const Color.fromARGB(255, 244, 245, 246);
  Color get _bgMid => _isDark ? const Color(0xFF0F172A) : const Color.fromARGB(255, 239, 239, 240);
  Color get _bgBottom => _isDark ? const Color(0xFF050811) : const Color.fromARGB(255, 244, 245, 243);
  Color get _accentBlue => const Color.fromARGB(255, 50, 96, 169);
  Color get _textDark => _isDark ? Colors.white : const Color(0xFF1F2542);
  Color get _textGray => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _cardBg => _isDark ? const Color(0xFF1E293B) : Colors.white;

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
      final result = await LoadingService.instance.wrap(
        context: context,
        message: 'Creando tu cuenta de salud...',
        task: () => _authApi.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          accountType: _accountType,
        ),
      );

      if (result.token != null && result.token!.isNotEmpty) {
        await AuthSession.instance.saveSession(
          accessToken: result.token!,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn ?? 3600,
          userName: _nameController.text.trim(),
          userEmail: _emailController.text.trim(),
        );
      }

      if (!mounted) return;
      final requiresConfirmation = result.requiresEmailConfirmation;
      await _showAuthDialog(
        title: requiresConfirmation ? '¡Cuenta creada!' : '¡Registro exitoso!',
        message: requiresConfirmation
            ? 'Revisa tu correo para confirmar la cuenta antes de iniciar sesión.'
            : 'Tu cuenta de Biomark AI está lista. Ahora comenzaremos el recorrido inicial.',
        icon: Icons.check_circle_outline_rounded,
        actionLabel: requiresConfirmation ? 'Ir a iniciar sesión' : 'Comenzar',
      );

      if (!mounted) return;
      if (requiresConfirmation || result.token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PermissionsScreen()),
        );
      }
    } on AuthApiException catch (error) {
      await _showAuthDialog(
        title: 'No pudimos crear tu cuenta',
        message: error.message,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Entendido',
        isError: true,
      );
    } catch (_) {
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

  // ---------------- PESTAÑAS INICIAR SESIÓN / REGISTRARSE (glassmorfismo) ----------------
  Widget _buildAuthTabs() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.18),
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
          color: activo ? _accentBlue.withValues(alpha: _isDark ? 0.25 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: activo
              ? Border.all(color: _accentBlue.withValues(alpha: 0.45), width: 1)
              : null,
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: _accentBlue.withValues(alpha: 0.08),
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
            color: activo ? (_isDark ? const Color(0xFF60A5FA) : _accentBlue) : _textDark,
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
      style: TextStyle(fontSize: 13.5, color: _textGray),
    );
  }

  // ---------------- TARJETA CON EL FORMULARIO ----------------
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _isDark ? Colors.black.withValues(alpha: 0.4) : _accentBlue.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          if (!_isDark)
            const BoxShadow(
              color: Color.fromARGB(232, 189, 193, 193),
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
                  color: _textGray,
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
                  color: _textGray,
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
            const SizedBox(height: 14),
            _buildInvitationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _openInvitationModal,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _isDark ? const Color(0xFF60A5FA).withValues(alpha: 0.5) : _accentBlue.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: Icon(
          Icons.verified_user_rounded,
          size: 18,
          color: _isDark ? const Color(0xFF60A5FA) : _accentBlue,
        ),
        label: Text(
          'Tengo un código de invitación oficial\n(Personal MINSA / Promotor)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _isDark ? const Color(0xFF60A5FA) : _accentBlue,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  void _openInvitationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InvitationRegistrationSheet(),
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
        color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FB),
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
          color: _isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
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
          floatingLabelStyle: TextStyle(color: _isDark ? const Color(0xFF60A5FA) : _accentBlue),
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

  // Botón principal
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: _accentBlue.withValues(alpha: _isDark ? 0.3 : 0.5),
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

class _InvitationRegistrationSheet extends StatefulWidget {
  const _InvitationRegistrationSheet();

  @override
  State<_InvitationRegistrationSheet> createState() => _InvitationRegistrationSheetState();
}

class _InvitationRegistrationSheetState extends State<_InvitationRegistrationSheet> {
  final _invitationsApi = InvitationsApi();
  final _tokenCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  VerifiedInvitationInfo? _verified;
  bool _verifying = false;
  bool _submitting = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _invitationsApi.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Ingresa el código de invitación recibido.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final info = await _invitationsApi.verifyInvitation(token);
      if (!mounted) return;
      setState(() {
        _verified = info;
        _verifying = false;
        if (info.contacto.isNotEmpty && info.contacto.contains('@')) {
          _emailCtrl.text = info.contacto.trim();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _verifying = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_verified == null) return;

    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await _invitationsApi.acceptInvitation(
        token: _verified!.token,
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );

      final token = res['token'] as String?;
      final refreshToken = res['refresh_token'] as String?;

      if (token != null && token.isNotEmpty) {
        await AuthSession.instance.saveSession(
          accessToken: token,
          refreshToken: refreshToken,
          expiresIn: 3600 * 24 * 7,
          role: _verified!.rolDestino,
          userName: _nameCtrl.text.trim(),
          userEmail: _emailCtrl.text.trim(),
          healthCenterId: _verified!.centroSaludId,
          healthCenterName: _verified!.centroSaludNombre,
        );

        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta activada. Por favor inicia sesión.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: BiomarkColors.blue, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Activación Institucional MINSA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa el código oficial de un solo uso recibido por tu supervisor para validar tu establecimiento.',
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),

              // PASO 1: Ingreso y verificación de Token
              if (_verified == null) ...[
                TextField(
                  controller: _tokenCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código de invitación *',
                    hintText: 'ej. BM-9F2B81',
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _verifying ? null : _verifyToken,
                  icon: _verifying
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_verifying ? 'Verificando...' : 'Verificar código'),
                ),
              ],

              // PASO 2: Token verificado -> Formulario de Registro
              if (_verified != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BiomarkColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BiomarkColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: BiomarkColors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _verified!.rolDestino == 'TRABAJADOR_SALUD'
                                    ? 'Personal de Salud MINSA'
                                    : 'Promotor de Salud Comunitario',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: BiomarkColors.green, fontSize: 13.5),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _verified = null;
                              _emailCtrl.clear();
                            }),
                            child: const Text(
                              'Cambiar código',
                              style: TextStyle(
                                color: BiomarkColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Centro de Salud: ${_verified!.centroSaludNombre}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                      if (_verified!.codigoEstablecimiento != null)
                        Text(
                          'Código Normativa 112: ${_verified!.codigoEstablecimiento}',
                          style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      if (_verified!.contacto.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _verified!.contacto.contains('@') ? Icons.mark_email_read_rounded : Icons.phone_android_rounded,
                              size: 15,
                              color: BiomarkColors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Acreditación emitida para: ${_verified!.contacto}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: BiomarkColors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa tu nombre completo' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: _verified != null && _verified!.contacto.isNotEmpty && _verified!.contacto.contains('@'),
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico *',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                          suffixIcon: (_verified != null && _verified!.contacto.isNotEmpty && _verified!.contacto.contains('@'))
                              ? const Tooltip(
                                  message: 'Correo verificado y vinculado institucionalmente',
                                  child: Icon(Icons.lock_rounded, size: 18, color: BiomarkColors.green),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          helperText: (_verified != null && _verified!.contacto.isNotEmpty && _verified!.contacto.contains('@'))
                              ? 'Vinculado a la acreditación institucional'
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) return 'Correo inválido';
                          if (_verified != null &&
                              _verified!.contacto.isNotEmpty &&
                              _verified!.contacto.contains('@') &&
                              v.trim().toLowerCase() != _verified!.contacto.trim().toLowerCase()) {
                            return 'Debe ser el correo acreditado (${_verified!.contacto})';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Mínimo 8 caracteres';
                          if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Debe incluir al menos una letra';
                          if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe incluir al menos un número';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscurePass,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña *',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.how_to_reg_rounded),
                          label: Text(_submitting ? 'Activando credencial...' : 'Activar Cuenta Institucional'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
