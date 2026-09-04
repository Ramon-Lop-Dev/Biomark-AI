import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_biomark/home_screen.dart';
import 'package:flutter_biomark/main.dart'; // <-- para navegar de vuelta a LoginScreen
import 'package:image_picker/image_picker.dart';

/// ---------------------------------------------------------------
/// REGISTER SCREEN — mismo estilo "claymorfismo" que el login,
/// con pestañas Iniciar Sesión / Registrarse arriba (igual que login)
/// ---------------------------------------------------------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Edad seleccionada con la rueda
  int? _selectedAge;
  static const int _minAge = 13;
  static const int _maxAge = 99;
  static const int _defaultAge = 18;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Foto de perfil seleccionada (guardada en memoria, funciona en web y móvil)
  Uint8List? _profileImageBytes;

  final ImagePicker _imagePicker = ImagePicker();

  // Fondo con más carácter — degradado en tonos azules de marca
  static const Color bgTop = Color.fromARGB(255, 244, 245, 246);
  static const Color bgMid = Color.fromARGB(255, 239, 239, 240);
  static const Color primaryPurple = Color.fromARGB(255, 254, 254, 254);
  static const Color accentBlue = Color.fromARGB(
    255,
    50,
    96,
    169,
  ); // azul de marca
  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color.fromARGB(255, 36, 36, 37);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _irALogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // ---------------- SELECTOR DE EDAD (RUEDA) ----------------
  Future<void> _pickAge() async {
    int tempAge = _selectedAge ?? _defaultAge;

    final int? result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Qué edad tienes?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: tempAge - _minAge,
                  ),
                  itemExtent: 42,
                  useMagnifier: true,
                  magnification: 1.15,
                  // Overlay SIN fondo sólido — solo dos líneas, así no tapa
                  // el número que queda resaltado en el centro.
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: const Color.fromARGB(
                            255,
                            50,
                            96,
                            169,
                          ).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    tempAge = _minAge + index;
                  },
                  children: List.generate(_maxAge - _minAge + 1, (index) {
                    final age = _minAge + index;
                    return Center(
                      child: Text(
                        '$age años',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Devolvemos la edad seleccionada como resultado del
                      // bottom sheet en vez de depender de setState aquí.
                      Navigator.of(sheetContext).pop(tempAge);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 50, 96, 169),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedAge = result;
      _ageController.text = '$_selectedAge años';
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _profileImageBytes = bytes);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: aquí va tu lógica real de registro (Firebase Auth, API REST, etc.)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro de prueba exitoso!')),
    );

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
                        const SizedBox(height: 28),
                        _buildProfilePhotoPicker(),
                        const SizedBox(height: 20),
                        _buildAuthTabs(),
                        const SizedBox(height: 20),
                        _buildTitle(),
                        const SizedBox(height: 28),
                        _buildFormCard(),
                        const SizedBox(height: 24),
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

  // ---------------- FOTO DE PERFIL ----------------
  Widget _buildProfilePhotoPicker() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 242, 242, 242),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    11,
                    56,
                    125,
                  ).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImageBytes != null
                  ? Image.memory(
                      _profileImageBytes!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person_outline_rounded,
                      size: 44,
                      color: const Color.fromARGB(255, 3, 3, 63),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPurple,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 15,
                color: Color.fromARGB(255, 5, 25, 122),
              ),
            ),
          ),
        ],
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
            _buildLabel('Nombre de usuario'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _usernameController,
              hint: '@tunombre',
              icon: Icons.alternate_email_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un nombre de usuario';
                }
                if (value.contains(' ')) {
                  return 'Sin espacios';
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
            _buildLabel('¿Qué edad tienes?'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _ageController,
              hint: 'Selecciona tu edad',
              icon: Icons.cake_outlined,
              readOnly: true,
              onTap: _pickAge,
              validator: (value) {
                if (_selectedAge == null) {
                  return 'Selecciona tu edad';
                }
                if (_selectedAge! < _minAge) {
                  return 'Debes tener al menos $_minAge años';
                }
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
                if (value.length < 6) {
                  return 'Mínimo 6 caracteres';
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

  // Campo de texto con efecto "clay" — idéntico al del login
  Widget _buildClayTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
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
          hintText: hint,
          hintStyle: TextStyle(color: textGray.withValues(alpha: 0.8), fontSize: 14),
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o regístrate con',
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
          child: _socialButton(label: 'Apple', icon: Icons.apple, onTap: () {}),
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
