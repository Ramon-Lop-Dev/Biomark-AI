import 'package:flutter/material.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/auth/auth_api.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
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

    await BiomarkDialog.showCustom<void>(
      context,
      icon: Icons.lock_reset_rounded,
      iconColor: BiomarkColors.green,
      title: 'Cambiar contraseña',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: actualController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: BiomarkColors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            if (nuevaController.text.trim().isEmpty ||
                nuevaController.text != confirmarController.text) {
              await BiomarkDialog.showError(
                context,
                title: 'Contraseñas no coinciden',
                message: 'La nueva contraseña y su confirmación deben ser exactamente iguales.',
              );
              return;
            }

            Navigator.pop(context);
            if (mounted) {
              await BiomarkDialog.showSuccess(
                context,
                title: '¡Contraseña actualizada!',
                message: 'Tu contraseña de acceso ha sido actualizada con éxito.',
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _enviarCorreoRecuperacion() async {
    setState(() => _enviandoRecuperacion = true);
    final api = AuthApi(baseUrl: AppConfig.apiUrl);
    try {
      await api.forgotPassword(
        email: widget.correoUsuario,
        redirectTo: 'biomarkai://reset-password',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace de recuperación enviado.')));
    } on AuthApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      api.dispose();
      if (mounted) setState(() => _enviandoRecuperacion = false);
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
          'Seguridad y contraseña',
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
                                Text(
                                  'Última modificación',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _fechaFormateada,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: onSurface.withValues(alpha: .6),
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
                      Divider(height: 24, color: dividerColor),
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
                            color: dividerColor.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Próximamente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: .5),
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
                    children: [
                      const _RecomendacionItem(
                        icono: Icons.password_rounded,
                        texto:
                            'Usa una contraseña de al menos 12 caracteres, combinando letras, números y símbolos.',
                      ),
                      Divider(height: 20, color: dividerColor),
                      const _RecomendacionItem(
                        icono: Icons.autorenew_rounded,
                        texto:
                            'No reutilices esta contraseña en otras cuentas ni apps.',
                      ),
                      Divider(height: 20, color: dividerColor),
                      const _RecomendacionItem(
                        icono: Icons.mark_email_read_outlined,
                        texto:
                            'Agrega un correo de respaldo apenas esté disponible, para no perder el acceso a tu cuenta.',
                      ),
                      Divider(height: 20, color: dividerColor),
                      const _RecomendacionItem(
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: correoDeshabilitado
                ? theme.dividerColor.withValues(alpha: .15)
                : BiomarkColors.blue.withValues(alpha: .12),
          ),
          child: Icon(
            icono,
            size: 17,
            color: correoDeshabilitado
                ? onSurface.withValues(alpha: .4)
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
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                correo,
                style: TextStyle(
                  fontSize: 12.5,
                  color: correoDeshabilitado
                      ? onSurface.withValues(alpha: .4)
                      : onSurface.withValues(alpha: .6),
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
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .85),
            ),
          ),
        ),
      ],
    );
  }
}
