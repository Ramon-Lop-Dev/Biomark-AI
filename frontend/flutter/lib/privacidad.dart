// Pantalla "Privacidad y datos médicos" — Biomark AI
//
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'politicapriv.dart';
import 'terminos_serv.dart';

class PrivacidadScreen extends StatefulWidget {
  const PrivacidadScreen({super.key});

  @override
  State<PrivacidadScreen> createState() => _PrivacidadScreenState();
}

class _PrivacidadScreenState extends State<PrivacidadScreen> {
  // TODO: cargar estos valores reales desde tu backend/SharedPreferences
  // en initState, y guardarlos cada vez que cambien.
  // ignore: unused_field
  bool _compartirConFamiliares = true;
  bool _usoDatosIA = true;
  bool _bloqueoBiometrico = false;

  bool _exportando = false;

  void _alternar(void Function(bool) setter, bool valorActual) {
    setState(() => setter(!valorActual));
    // TODO: persistir el cambio.
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
    final tema = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tema.dialogTheme.backgroundColor ?? tema.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '¿Eliminar tu cuenta?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: tema.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Esta acción es permanente. Se eliminarán tu perfil, tus antecedentes '
          'médicos y todo tu historial con Biomark AI. No se puede deshacer.',
          style: TextStyle(
            color: tema.colorScheme.onSurface.withValues(alpha: .8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              // TODO: llamar al endpoint real de eliminación de cuenta.
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: tema.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: tema.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Privacidad y datos médicos',
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildSeccionTitulo(tema, 'Control de tus datos'),
            const SizedBox(height: 10),
            _buildTarjeta(
              tema: tema,
              child: Column(
                children: [
                  Divider(
                    height: 24,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildFilaSwitch(
                    tema: tema,
                    icono: Icons.psychology_alt_rounded,
                    titulo: 'Uso de datos por BIOMARK AI',
                    subtitulo:
                        'Permite que la IA use tu historial para personalizar consejos',
                    valor: _usoDatosIA,
                    onChanged: (_) =>
                        _alternar((v) => _usoDatosIA = v, _usoDatosIA),
                  ),
                  Divider(
                    height: 24,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildFilaSwitch(
                    tema: tema,
                    icono: Icons.fingerprint_rounded,
                    titulo: 'Bloqueo biométrico',
                    subtitulo:
                        'Pide huella o Face ID antes de mostrar tus datos médicos',
                    valor: _bloqueoBiometrico,
                    deshabilitado: true,
                    onChanged: (_) => _alternar(
                      (v) => _bloqueoBiometrico = v,
                      _bloqueoBiometrico,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo(tema, 'Tus datos'),
            const SizedBox(height: 10),
            _buildTarjeta(
              tema: tema,
              child: Column(
                children: [
                  _buildFilaAccion(
                    tema: tema,
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
                            color: tema.colorScheme.onSurface.withValues(
                              alpha: .35,
                            ),
                          ),
                    onTap: _exportando ? null : _exportarDatos,
                  ),
                  Divider(
                    height: 24,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildFilaAccion(
                    tema: tema,
                    icono: Icons.delete_outline_rounded,
                    titulo: 'Eliminar mi cuenta y datos',
                    subtitulo:
                        'Elimina permanentemente tu perfil y antecedentes',
                    colorIcono: Colors.redAccent,
                    colorTitulo: Colors.redAccent,
                    accion: Icon(
                      Icons.chevron_right_rounded,
                      color: tema.colorScheme.onSurface.withValues(alpha: .35),
                    ),
                    onTap: _confirmarEliminarCuenta,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo(tema, 'Legal'),
            const SizedBox(height: 10),
            _buildTarjeta(
              tema: tema,
              child: Column(
                children: [
                  _buildFilaAccion(
                    tema: tema,
                    icono: Icons.privacy_tip_outlined,
                    titulo: 'Política de privacidad',
                    accion: Icon(
                      Icons.chevron_right_rounded,
                      color: tema.colorScheme.onSurface.withValues(alpha: .35),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PoliticaPrivacidadScreen(),
                      ),
                    ),
                  ),
                  Divider(
                    height: 24,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildFilaAccion(
                    tema: tema,
                    icono: Icons.description_outlined,
                    titulo: 'Términos de servicio',
                    accion: Icon(
                      Icons.chevron_right_rounded,
                      color: tema.colorScheme.onSurface.withValues(alpha: .35),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TerminosServicioScreen(),
                      ),
                    ),
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
    required ThemeData tema,
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
    bool deshabilitado = false,
  }) {
    final colorApagado = tema.colorScheme.onSurface.withValues(alpha: .35);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (deshabilitado ? colorApagado : BiomarkColors.blue)
                .withValues(alpha: .12),
          ),
          child: Icon(
            icono,
            size: 17,
            color: deshabilitado ? colorApagado : BiomarkColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: deshabilitado
                          ? colorApagado
                          : tema.colorScheme.onSurface,
                    ),
                  ),
                  if (deshabilitado) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.onSurface.withValues(
                          alpha: .08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.onSurface.withValues(
                            alpha: .5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: deshabilitado
                      ? colorApagado
                      : tema.colorScheme.onSurface.withValues(alpha: .5),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          onChanged: deshabilitado ? null : onChanged,
          activeThumbColor: BiomarkColors.green,
        ),
      ],
    );
  }

  Widget _buildFilaAccion({
    required ThemeData tema,
    required IconData icono,
    required String titulo,
    String? subtitulo,
    required Widget accion,
    VoidCallback? onTap,
    Color? colorIcono,
    Color? colorTitulo,
  }) {
    final colorIconoFinal = colorIcono ?? BiomarkColors.blue;
    final colorTituloFinal = colorTitulo ?? tema.colorScheme.onSurface;

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
              color: colorIconoFinal.withValues(alpha: .12),
            ),
            child: Icon(icono, size: 17, color: colorIconoFinal),
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
                    color: colorTituloFinal,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: tema.colorScheme.onSurface.withValues(alpha: .5),
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

  Widget _buildSeccionTitulo(ThemeData tema, String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: tema.colorScheme.onSurface.withValues(alpha: .6),
      ),
    );
  }

  Widget _buildTarjeta({required ThemeData tema, required Widget child}) {
    final esOscuro = tema.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .25 : .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
