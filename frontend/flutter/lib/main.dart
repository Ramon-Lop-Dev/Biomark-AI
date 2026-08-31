import 'package:flutter/material.dart';

import 'loading.dart';
import 'home_screen.dart';
import 'register_screen.dart';

void main() {
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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Colores base del diseño (ajusta a tu marca)
  static const Color bgTop = Color(0xFFE0E7F2);
  static const Color bgMid = Color.fromARGB(255, 243, 243, 244);
  static const Color bgBottom = Color.fromARGB(255, 228, 229, 232);
  static const Color primaryGreen = Color.fromARGB(255, 9, 61, 107);
  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color.fromARGB(255, 36, 36, 37);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: aquí va tu lógica real (Firebase Auth, API REST, etc.)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Login de prueba exitoso')));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
                        const SizedBox(height: 28),
                        _buildLogo(),
                        const SizedBox(height: 24),
                        _buildTitle(),
                        const SizedBox(height: 28),
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildFooter(),
                        const SizedBox(height: 12),
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
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
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
        color: const Color.fromARGB(255, 241, 238, 238),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // sombra oscura abajo-derecha
          BoxShadow(
            color: const Color.fromARGB(
              255,
              33,
              45,
              122,
            ).withValues(alpha: 0.25),
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
              hint: 'ejemplo@gmail.com',
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
                  // TODO: navegar a recuperación de contraseña
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Color.fromARGB(255, 59, 58, 58),
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
          hintText: hint,
          hintStyle: TextStyle(
            color: textGray.withValues(alpha: 0.8),
            fontSize: 14,
          ),
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
            onTap: () {},
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
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes una cuenta? ',
          style: TextStyle(color: textGray, fontSize: 13),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            ' Registrarse',
            style: TextStyle(
              color: Color.fromRGBO(70, 171, 57, 1), // verde de marca
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
