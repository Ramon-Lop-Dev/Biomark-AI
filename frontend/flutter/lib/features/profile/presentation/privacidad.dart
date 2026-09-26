import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/auth/auth_session.dart';
import 'package:flutter_biomark/core/auth/auth_api.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
import 'package:flutter_biomark/main.dart';
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

  Future<void> _confirmarEliminarCuenta() async {
    final confirmed = await BiomarkDialog.showConfirm(
      context,
      title: '¿Eliminar tu cuenta?',
      message: 'Esta acción es permanente. Se eliminarán tu perfil, tus antecedentes '
          'médicos y todo tu historial con Biomark AI. No se puede deshacer.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      _eliminarCuenta();
    }
  }

  Future<void> _eliminarCuenta() async {
    BiomarkDialog.showLoading(context, message: 'Eliminando cuenta...');
    try {
      final token = AuthSession.instance.accessToken;
      if (token == null || token.isEmpty) throw Exception('Sesión expirada.');
      await AuthApi(
        baseUrl: AppConfig.apiUrl,
      ).deleteAccount(accessToken: token);
      await AuthSession.instance.clear();
      if (!mounted) return;
      BiomarkDialog.hideLoading(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      BiomarkDialog.hideLoading(context);
      await BiomarkDialog.showError(
        context,
        title: 'Error al eliminar',
        message: 'No se pudo eliminar la cuenta: $error',
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Privacidad y datos médicos',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildSeccionTitulo('Control de tus datos'),
                const SizedBox(height: 10),
                _buildTarjeta(
                  child: Column(
                    children: [
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
                      Divider(height: 24, color: dividerColor),
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
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: onSurface.withValues(alpha: .35),
                              ),
                        onTap: _exportando ? null : _exportarDatos,
                      ),
                      Divider(height: 24, color: dividerColor),
                      _buildFilaAccion(
                        icono: Icons.delete_outline_rounded,
                        titulo: 'Eliminar mi cuenta y datos',
                        subtitulo:
                            'Elimina permanentemente tu perfil y antecedentes',
                        colorIcono: Colors.redAccent,
                        colorTitulo: Colors.redAccent,
                        accion: Icon(
                          Icons.chevron_right_rounded,
                          color: onSurface.withValues(alpha: .35),
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
                        accion: Icon(
                          Icons.chevron_right_rounded,
                          color: onSurface.withValues(alpha: .35),
                        ),
                        onTap: () {
                          // TODO: abrir la URL real, ej. con url_launcher.
                        },
                      ),
                      Divider(height: 24, color: dividerColor),
                      _buildFilaAccion(
                        icono: Icons.description_outlined,
                        titulo: 'Términos de servicio',
                        accion: Icon(
                          Icons.chevron_right_rounded,
                          color: onSurface.withValues(alpha: .35),
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: .5),
                ),
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
    Color? colorTitulo,
  }) {
    final theme = Theme.of(context);
    final effectiveTitleColor = colorTitulo ?? theme.colorScheme.onSurface;

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
                    color: effectiveTitleColor,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: .5),
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
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
      ),
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .25 : .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
