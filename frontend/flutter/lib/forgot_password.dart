import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/reset_password_link_listener.dart';
import 'core/config/app_config.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Paso { correo, esperandoCorreo, nuevaClave }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Paso _paso = _Paso.correo;
  bool _isLoading = false;
  final _authApi = AuthApi(baseUrl: AppConfig.apiUrl);
  String? _recoveryAccessToken;

  // ---- Colores (idénticos a LoginScreen) ----
  static const Color bgTop = Color(0xFFE0E7F2);
  static const Color bgMid = Color.fromARGB(255, 243, 243, 244);
  static const Color bgBottom = Color.fromARGB(255, 228, 229, 232);
  static const Color primaryGreen = Color.fromARGB(255, 9, 61, 107);
  static const Color accentGreen = Color.fromRGBO(70, 171, 57, 1);
  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color.fromARGB(255, 36, 36, 37);

  // ---- Controladores ----
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _passFormKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    ResetPasswordLinkListener.instance.listen(_onRecoveryLink);
    final pendingToken = ResetPasswordLinkListener.instance.pendingAccessToken;
    if (pendingToken != null) _onRecoveryLink(pendingToken);
  }

  void _onRecoveryLink(String accessToken) {
      if (!mounted) return;
      setState(() {
        _recoveryAccessToken = accessToken;
        _paso = _Paso.nuevaClave;
      });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _authApi.dispose();
    ResetPasswordLinkListener.instance.removeListener(_onRecoveryLink);
    super.dispose();
  }

  // ------------------------------------------------------------
  // ACCIONES
  // ------------------------------------------------------------
  Future<void> _enviarCodigo() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final message = await _authApi.forgotPassword(
        email: _emailController.text.trim(),
        redirectTo: kIsWeb
        ? 'https://biomark-api.duckdns.org/reset-password'
        : 'biomarkai://reset-password',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _paso = _Paso.esperandoCorreo;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    } on AuthApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _reenviarCodigo() async {
    try {
      await _authApi.forgotPassword(
        email: _emailController.text.trim(),
        redirectTo: kIsWeb
        ? 'https://biomark-api.duckdns.org/reset-password'
        : 'biomarkai://reset-password',
      );
    } on AuthApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reenviando código a ${_emailController.text}...'),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _guardarNuevaClave() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_recoveryAccessToken == null || _recoveryAccessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abre el enlace recibido por correo.')));
      return;
    }

    try {
      await _authApi.resetPassword(
        accessToken: _recoveryAccessToken!,
        newPassword: _newPassController.text,
      );
    } on AuthApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildExitoDialog(),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 8),
                        _buildIcono(),
                        const SizedBox(height: 22),
                        _buildTitulos(),
                        const SizedBox(height: 24),
                        _buildPasosIndicador(),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _buildTarjetaSegunPaso(),
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

  // ---- Botón atrás ----
  Widget _buildTopBar() {
    return Row(
      children: [
        _buildClayIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (_paso == _Paso.correo) {
              Navigator.pop(context);
            } else if (_paso == _Paso.esperandoCorreo) {
              setState(() => _paso = _Paso.correo);
            } else {
              setState(() => _paso = _Paso.esperandoCorreo);
            }
          },
        ),
      ],
    );
  }

  Widget _buildClayIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgMid,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 8,
              offset: Offset(-3, -3),
            ),
          ],
        ),
        child: Icon(icon, color: textDark, size: 20),
      ),
    );
  }

  // ---- Ícono superior (cambia según el paso) ----
  Widget _buildIcono() {
    IconData icon;
    switch (_paso) {
      case _Paso.correo:
        icon = Icons.mail_lock_outlined;
        break;
      case _Paso.esperandoCorreo:
        icon = Icons.password_rounded;
        break;
      case _Paso.nuevaClave:
        icon = Icons.lock_reset_rounded;
        break;
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgMid,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(6, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 14,
            offset: Offset(-6, -6),
          ),
        ],
      ),
      child: Icon(icon, color: primaryGreen, size: 34),
    );
  }

  // ---- Títulos según paso ----
  Widget _buildTitulos() {
    String titulo;
    String subtitulo;
    switch (_paso) {
      case _Paso.correo:
        titulo = 'Recuperar contraseña';
        subtitulo = 'Ingresa tu correo y te enviaremos un código';
        break;
      case _Paso.esperandoCorreo:
        titulo = 'Revisa tu correo';
        subtitulo = 'Enviamos un enlace a ${_emailController.text.isEmpty ? "tu correo" : _emailController.text}. Ábrelo para continuar.';
        break;
      case _Paso.nuevaClave:
        titulo = 'Nueva contraseña';
        subtitulo = 'Crea una contraseña segura para tu cuenta';
        break;
    }

    return Column(
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textGray),
          ),
        ),
      ],
    );
  }

  // ---- Indicador de pasos (puntitos tipo clay) ----
  Widget _buildPasosIndicador() {
    final pasos = [_Paso.correo, _Paso.esperandoCorreo, _Paso.nuevaClave];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pasos.length, (i) {
        final activo = pasos.indexOf(_paso) >= i;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: pasos.indexOf(_paso) == i ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: activo ? primaryGreen : bgBottom,
              borderRadius: BorderRadius.circular(8),
              boxShadow: activo
                  ? [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  // ---- Tarjeta principal según paso ----
  Widget _buildTarjetaSegunPaso() {
    switch (_paso) {
      case _Paso.correo:
        return _buildTarjetaCorreo();
      case _Paso.esperandoCorreo:
        return _buildTarjetaOtp();
      case _Paso.nuevaClave:
        return _buildTarjetaNuevaClave();
    }
  }

  Widget _buildClayCard({required Widget child}) {
    return Container(
      key: ValueKey(_paso),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgMid,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 33, 45, 122).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 20,
            offset: Offset(-6, -6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---- PASO 1: correo ----
  Widget _buildTarjetaCorreo() {
    return _buildClayCard(
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Correo electrónico'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _emailController,
              hint: 'tunombre13@gmail.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa tu correo';
                if (!value.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildBotonPrincipal(
              texto: 'Enviar enlace',
              color: primaryGreen,
              onPressed: _enviarCodigo,
            ),
          ],
        ),
      ),
    );
  }

  // ---- PASO 2: espera del enlace ----
  Widget _buildTarjetaOtp() {
    return _buildClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 42, color: primaryGreen),
          const SizedBox(height: 18),
          Text(
            'Abre el enlace que enviamos a tu correo. La app continuará automáticamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGray, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿No recibiste el enlace? ', style: TextStyle(color: textGray, fontSize: 13)),
              GestureDetector(
                onTap: _reenviarCodigo,
                child: const Text(
                  'Reenviar',
                  style: TextStyle(color: accentGreen, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- PASO 3: nueva contraseña ----
  Widget _buildTarjetaNuevaClave() {
    return _buildClayCard(
      child: Form(
        key: _passFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nueva contraseña'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _newPassController,
              hint: '••••••••••',
              icon: Icons.lock_outline_rounded,
              floatingHint: false,
              obscureText: _obscureNew,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: textGray,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                if (value.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('Confirmar nueva contraseña'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _confirmPassController,
              hint: '••••••••••',
              icon: Icons.lock_outline_rounded,
              floatingHint: false,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: textGray,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (value) {
                if (value != _newPassController.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildBotonPrincipal(
              texto: 'Guardar',
              color: accentGreen,
              onPressed: _guardarNuevaClave,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WIDGETS REUTILIZABLES
  // ------------------------------------------------------------
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
    );
  }

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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBotonPrincipal({
    required String texto,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ---- Diálogo de éxito al final ----
  Widget _buildExitoDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bgMid,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(color: accentGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Contraseña actualizada!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Ya puedes iniciar sesión con tu nueva contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textGray),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context); // cierra el diálogo
                  Navigator.pop(context); // regresa al login
                },
                child: const Text('Ir a Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}