// Pantalla "Privacidad y datos médicos" — Biomark AI
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'core/auth/auth_session.dart';
import 'core/auth/auth_api.dart';
import 'core/config/app_config.dart';
import 'main.dart';

class PrivacidadScreen extends StatefulWidget {
  const PrivacidadScreen({super.key});

  @override
  State<PrivacidadScreen> createState() => _PrivacidadScreenState();
}

class _PrivacidadScreenState extends State<PrivacidadScreen> {
  bool _usoDatosIA = true;
  final bool _bloqueoBiometrico = false;

  bool _exportando = false;
  bool _guardandoConsentimiento = false;
  bool _eliminandoCuenta = false;

  @override
  void initState() {
    super.initState();
    _cargarConsentimiento();
  }

  Future<void> _cargarConsentimiento() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/consent',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300 || !mounted) {
        return;
      }
      final items = jsonDecode(response.body);
      if (items is! List) return;
      final consent = items
          .whereType<Map<String, dynamic>>()
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (item) => item?['tipo_consentimiento'] == 'CONTEXTO_MEDICO_IA',
            orElse: () => null,
          );
      if (consent != null) {
        setState(() => _usoDatosIA = consent['otorgado'] != false);
      }
    } catch (_) {}
  }

  Future<void> _alternarUsoDatosIA() async {
    if (_guardandoConsentimiento) return;
    final nuevoValor = !_usoDatosIA;
    setState(() {
      _usoDatosIA = nuevoValor;
      _guardandoConsentimiento = true;
    });
    final token = AuthSession.instance.accessToken;
    try {
      if (token == null || token.isEmpty) throw Exception('Sesión expirada.');
      final response = await http.put(
        Uri.parse(
          '${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/consent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipo_consentimiento': 'CONTEXTO_MEDICO_IA',
          'otorgado': nuevoValor,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('El servidor rechazó el consentimiento.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _usoDatosIA = !nuevoValor);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
      }
    } finally {
      if (mounted) setState(() => _guardandoConsentimiento = false);
    }
  }

  Future<void> _exportarDatos() async {
    setState(() => _exportando = true);

    // TODO: llamar al endpoint real que genera y envía el PDF/export, ej:
    // final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
    // await authApi.exportarDatos(accessToken: AuthSession.instance.accessToken!);

    await Future.delayed(const Duration(milliseconds: 700)); // placeholder

    if (!mounted) return;
    setState(() => _exportando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Te enviaremos tus datos por correo en unos minutos'),
      ),
    );
  }

  void _confirmarEliminarCuenta() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '¿Eliminar tu cuenta?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Esta acción es permanente. Se eliminarán tu perfil, tus antecedentes '
          'médicos y todo tu historial con Biomark AI. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: _eliminandoCuenta
                ? null
                : () => _eliminarCuenta(dialogContext),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCuenta(BuildContext dialogContext) async {
    setState(() => _eliminandoCuenta = true);
    try {
      final token = AuthSession.instance.accessToken;
      if (token == null || token.isEmpty) throw Exception('Sesión expirada.');
      await AuthApi(
        baseUrl: AppConfig.apiUrl,
      ).deleteAccount(accessToken: token);
      await AuthSession.instance.clear();
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _eliminandoCuenta = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la cuenta: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BiomarkColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Privacidad y datos médicos',
          style: TextStyle(
            color: BiomarkColors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildSeccionTitulo('Control de tus datos'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                children: [
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.psychology_alt_rounded,
                    titulo: 'Uso de datos por Biomark AI',
                    subtitulo:
                        'Permite que la IA use tu historial para personalizar consejos',
                    valor: _usoDatosIA,
                    onChanged: _guardandoConsentimiento
                        ? null
                        : (_) => _alternarUsoDatosIA(),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaSwitch(
                    icono: Icons.fingerprint_rounded,
                    titulo: 'Bloqueo biométrico (PROXIMAMENTE)',
                    subtitulo:
                        'Pide huella o Face ID antes de mostrar tus datos médicos',
                    valor: _bloqueoBiometrico,
                    onChanged: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo('Tus datos'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                children: [
                  _buildFilaAccion(
                    icono: Icons.download_outlined,
                    titulo: 'Descargar mis datos',
                    subtitulo: 'Recibe una copia de tu historial médico en PDF',
                    accion: _exportando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFBFBFC9),
                          ),
                    onTap: _exportando ? null : _exportarDatos,
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaAccion(
                    icono: Icons.delete_outline_rounded,
                    titulo: 'Eliminar mi cuenta y datos',
                    subtitulo:
                        'Elimina permanentemente tu perfil y antecedentes',
                    colorIcono: Colors.redAccent,
                    colorTitulo: Colors.redAccent,
                    accion: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBFBFC9),
                    ),
                    onTap: _confirmarEliminarCuenta,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo('Legal'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                children: [
                  _buildFilaAccion(
                    icono: Icons.privacy_tip_outlined,
                    titulo: 'Política de privacidad',
                    accion: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBFBFC9),
                    ),
                    onTap: () {
                      // TODO: abrir la URL real, ej. con url_launcher.
                    },
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaAccion(
                    icono: Icons.description_outlined,
                    titulo: 'Términos de servicio',
                    accion: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFBFBFC9),
                    ),
                    onTap: () {
                      // TODO: abrir la URL real, ej. con url_launcher.
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaSwitch({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BiomarkColors.blue.withValues(alpha: .12),
          ),
          child: Icon(icono, size: 17, color: BiomarkColors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: BiomarkColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9C9CA6)),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeThumbColor: BiomarkColors.green,
        ),
      ],
    );
  }

  Widget _buildFilaAccion({
    required IconData icono,
    required String titulo,
    String? subtitulo,
    required Widget accion,
    VoidCallback? onTap,
    Color colorIcono = BiomarkColors.blue,
    Color colorTitulo = BiomarkColors.black,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorIcono.withValues(alpha: .12),
            ),
            child: Icon(icono, size: 17, color: colorIcono),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colorTitulo,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9C9CA6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          accion,
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7A7A85),
      ),
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
