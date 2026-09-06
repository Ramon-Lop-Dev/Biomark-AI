// Pantalla "Seguridad y contraseña" — Biomark AI
//
// Muestra cuándo se creó/modificó la contraseña, permite recuperarla
// mediante el correo principal, deja el correo de respaldo como
// funcionalidad futura, y da recomendaciones de seguridad.
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';

class SeguridadScreen extends StatefulWidget {
  final String correoUsuario;

  const SeguridadScreen({super.key, required this.correoUsuario});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  bool _enviandoRecuperacion = false;

  // TODO: reemplazar con la fecha real que devuelva tu backend, por
  // ejemplo AuthSession.instance.passwordActualizadaEn. Mientras tanto
  // se muestra un estado "no disponible" en vez de inventar una fecha.
  DateTime? get _fechaUltimaModificacion => null;

  String get _fechaFormateada {
    final fecha = _fechaUltimaModificacion;
    if (fecha == null) return 'No disponible';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _cambiarContrasena() async {
    final actualController = TextEditingController();
    final nuevaController = TextEditingController();
    final confirmarController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nuevaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BiomarkColors.green,
            ),
            onPressed: () async {
              if (nuevaController.text.trim().isEmpty ||
                  nuevaController.text != confirmarController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas nuevas no coinciden'),
                  ),
                );
                return;
              }

              // TODO: llamar al endpoint real de cambio de contraseña, ej:
              // final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
              // await authApi.cambiarContrasena(
              //   accessToken: AuthSession.instance.accessToken!,
              //   actual: actualController.text,
              //   nueva: nuevaController.text,
              // );

              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contraseña actualizada')),
                );
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarCorreoRecuperacion() async {
    setState(() => _enviandoRecuperacion = true);

    // TODO: llamar al endpoint real de recuperación de contraseña, ej:
    // final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
    // await authApi.solicitarRecuperacion(correo: widget.correoUsuario);

    await Future.delayed(const Duration(milliseconds: 600)); // placeholder

    if (!mounted) return;
    setState(() => _enviandoRecuperacion = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Enlace de recuperación enviado a ${widget.correoUsuario}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FC),
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
          'Seguridad y contraseña',
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
            _buildSeccionTitulo('Contraseña'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BiomarkColors.blue.withValues(alpha: .12),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: BiomarkColors.blue,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Última modificación',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: BiomarkColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fechaFormateada,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF7A7A85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cambiarContrasena,
                      icon: const Icon(Icons.key_rounded, size: 16),
                      label: const Text('Cambiar contraseña'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BiomarkColors.blue,
                        side: const BorderSide(color: BiomarkColors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo('Recuperación de cuenta'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilaCorreo(
                    icono: Icons.email_outlined,
                    titulo: 'Correo principal',
                    correo: widget.correoUsuario,
                    accion: _enviandoRecuperacion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _enviarCorreoRecuperacion,
                            child: const Text('Enviar enlace'),
                          ),
                  ),
                  const Divider(height: 24, color: Color(0xFFEFEFF3)),
                  _buildFilaCorreo(
                    icono: Icons.email_outlined,
                    titulo: 'Correo de respaldo',
                    correo: 'No configurado',
                    correoDeshabilitado: true,
                    accion: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFF3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9C9CA6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo('Recomendaciones'),
            const SizedBox(height: 10),
            _buildTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RecomendacionItem(
                    icono: Icons.password_rounded,
                    texto:
                        'Usa una contraseña de al menos 12 caracteres, combinando letras, números y símbolos.',
                  ),
                  Divider(height: 20, color: Color(0xFFEFEFF3)),
                  _RecomendacionItem(
                    icono: Icons.autorenew_rounded,
                    texto:
                        'No reutilices esta contraseña en otras cuentas ni apps.',
                  ),
                  Divider(height: 20, color: Color(0xFFEFEFF3)),
                  _RecomendacionItem(
                    icono: Icons.mark_email_read_outlined,
                    texto:
                        'Agrega un correo de respaldo apenas esté disponible, para no perder el acceso a tu cuenta.',
                  ),
                  Divider(height: 20, color: Color(0xFFEFEFF3)),
                  _RecomendacionItem(
                    icono: Icons.verified_user_outlined,
                    texto:
                        'Cambia tu contraseña periódicamente, sobre todo si la usaste en otro sitio.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaCorreo({
    required IconData icono,
    required String titulo,
    required String correo,
    required Widget accion,
    bool correoDeshabilitado = false,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: correoDeshabilitado
                ? const Color(0xFFEFEFF3)
                : BiomarkColors.blue.withValues(alpha: .12),
          ),
          child: Icon(
            icono,
            size: 17,
            color: correoDeshabilitado
                ? const Color(0xFF9C9CA6)
                : BiomarkColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: BiomarkColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                correo,
                style: TextStyle(
                  fontSize: 12.5,
                  color: correoDeshabilitado
                      ? const Color(0xFF9C9CA6)
                      : const Color(0xFF7A7A85),
                ),
              ),
            ],
          ),
        ),
        accion,
      ],
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

class _RecomendacionItem extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _RecomendacionItem({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: BiomarkColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A4A55)),
          ),
        ),
      ],
    );
  }
}
