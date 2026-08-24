import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// ---------------------------------------------------------------
/// REGISTER SCREEN — mismo estilo "claymorfismo" que el login
/// ---------------------------------------------------------------
/// Cómo usarlo:
/// 1. Agrega en pubspec.yaml, dentro de dependencies:
///    image_picker: ^1.1.2
///    y corre flutter pub get
/// 2. Copia este archivo a lib/register_screen.dart
/// 3. En tu main.dart, arriba del todo agrega:
///    import 'register_screen.dart';
/// 4. En el "Registrarse" de tu LoginScreen (_buildFooter), navega así:
///    onTap: () {
///      Navigator.push(
///        context,
///        MaterialPageRoute(builder: (context) => const RegisterScreen()),
///      );
///    },
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
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedBirthDate;
  int? _calculatedAge;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Foto de perfil seleccionada (guardada en memoria, funciona en web y móvil)
  Uint8List? _profileImageBytes;

  final ImagePicker _imagePicker = ImagePicker();

  // Fondo con más carácter — degradado en tonos azules de marca
  static const Color bgTop = Color(0xFFE0E7F2);
  static const Color bgMid = Color(0xFF8EA8D0);
  static const Color bgBottom = Color(0xFF46AB39);
  static const Color primaryPurple = Color(0xFF46AB39);
  static const Color textDark = Color(0xFF1F2542);
  static const Color textGray = Color.fromARGB(255, 36, 36, 37);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final hasHadBirthdayThisYear = (today.month > birthDate.month) ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hasHadBirthdayThisYear) age--;
    return age;
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedBirthDate = picked;
      _calculatedAge = _calculateAge(picked);
      _birthDateController.text =
          '${_formatDate(picked)}  •  ${_calculatedAge} años';
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
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
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
  child: Stack(
    children: [
      LayoutBuilder(
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
                    const SizedBox(height: 40),
                    _buildProfilePhotoPicker(),
                    const SizedBox(height: 20),
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
      // Botón de regreso — va AL FINAL para quedar encima y ser tocable
      Positioned(
        top: 8,
        left: 8,
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    ],
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
              child: _profileImageBytes != null
                  ? Image.memory(
                      _profileImageBytes!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.person_outline_rounded,
                      size: 44, color: textGray),
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
              child: const Icon(Icons.camera_alt_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TÍTULO ----------------
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Completa tus datos para registrarte',
          style: TextStyle(fontSize: 13, color: textGray),
        ),
      ],
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
            color: Colors.grey.withOpacity(0.25),
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
                  return 'Ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('Nombre de usuario'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _usernameController,
              hint: '@usuario',
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
              hint: 'biomark2026@gmail.com',
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
            const SizedBox(height: 16),
            _buildLabel('Fecha de nacimiento'),
            const SizedBox(height: 8),
            _buildClayTextField(
              controller: _birthDateController,
              hint: 'Selecciona tu fecha de nacimiento',
              icon: Icons.cake_outlined,
              readOnly: true,
              onTap: _pickBirthDate,
              validator: (value) {
                if (_selectedBirthDate == null) {
                  return 'Selecciona tu fecha de nacimiento';
                }
                if (_calculatedAge != null && _calculatedAge! < 13) {
                  return 'Debes tener al menos 13 años';
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
                  setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword);
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
            color: Colors.grey.withOpacity(0.15),
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
          hintStyle: TextStyle(color: textGray.withOpacity(0.8), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryPurple.withOpacity(0.5),
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
                'Registrarme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o regístrate con',
              style: TextStyle(color: textGray, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
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
            label: 'Apple',
            icon: Icons.apple,
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
      label: Text(label,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tienes una cuenta? ',
            style: TextStyle(color: textGray, fontSize: 13)),
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // regresa al login
          },
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(
              color: primaryPurple,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}