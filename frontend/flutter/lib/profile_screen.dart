// Pantalla de perfil de usuario — Biomark AI
//
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'acercade.dart';
import 'biomark_brand.dart';
import 'datos_personales.dart';
import 'editar_perfil.dart';
import 'notifications.dart';
import 'privacidad.dart';
import 'apariencia.dart';
import 'seguridad_screen.dart';
import 'main.dart'; // para poder cerrar sesión y volver a LoginScreen
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Antes eran "static const". Ahora son variables de instancia para
  // poder actualizarlas con setState al volver de EditarPerfilScreen.
  String _nombreUsuario = 'Familia';
  final String _correoUsuario = 'usuario@correo.com';
  int? _edadUsuario; // viene de la encuesta hecha en el chat
  String? _fotoPath; // ruta local de la foto de perfil, si se cambió
  String? _generoUsuario;

  @override
  void initState() {
    super.initState();
    // TODO: cargar los datos reales del usuario aquí, por ejemplo:
    // _nombreUsuario = AuthSession.instance.nombre ?? 'Familia';
    // _correoUsuario = AuthSession.instance.correo ?? 'usuario@correo.com';
    // _edadUsuario = AuthSession.instance.edad;
    // _fotoPath = AuthSession.instance.fotoPath;
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
          'Mi Perfil',
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildEncabezado(tema),
            const SizedBox(height: 24),
            _buildSeccion(tema, 'Cuenta', [
              _ItemPerfil(
                icon: Icons.person_outline_rounded,
                label: 'Mis datos personales',
                onTap: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DatosPersonalesScreen(
                        nombreActual: _nombreUsuario,
                        generoActual: _generoUsuario,
                      ),
                    ),
                  );

                  if (resultado != null && mounted) {
                    setState(() {
                      _nombreUsuario = resultado['nombre'] ?? _nombreUsuario;
                      _generoUsuario = resultado['genero'] ?? _generoUsuario;
                    });
                    // TODO: persistir también aquí si aplica.
                  }
                },
              ),
              _ItemPerfil(
                icon: Icons.lock_outline_rounded,
                label: 'Seguridad y contraseña',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SeguridadScreen(correoUsuario: _correoUsuario),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 18),
            _buildSeccion(tema, 'Preferencias', [
              _ItemPerfil(
                icon: Icons.notifications_none_rounded,
                label: 'Notificaciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _ItemPerfil(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacidad y datos médicos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacidadScreen(),
                    ),
                  );
                },
              ),
              _ItemPerfil(
                icon: Icons.palette_rounded,
                label: 'Aspecto de la app',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AparienciaScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 18),
            _buildSeccion(tema, 'Soporte', [
              _ItemPerfil(
                icon: Icons.help_outline_rounded,
                label: 'Centro de ayuda',
                onTap: _abrirCentroDeAyuda,
              ),
              _ItemPerfil(
                icon: Icons.info_outline_rounded,
                label: 'Acerca de Biomark AI',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AcercaScreen(),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 28),
            _buildBotonCerrarSesion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado(ThemeData tema) {
    final esOscuro = tema.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarPerfilScreen(
              nombreActual: _nombreUsuario,
              correo: _correoUsuario,
              edad: _edadUsuario,
              fotoPath: _fotoPath,
            ),
          ),
        );

        if (resultado != null && mounted) {
          setState(() {
            _nombreUsuario = resultado['nombre'] ?? _nombreUsuario;
            _fotoPath = resultado['fotoPath'] ?? _fotoPath;
          });
          // TODO: persistir el cambio, por ejemplo:
          // await AuthSession.instance.actualizarNombre(_nombreUsuario);
          // await AuthSession.instance.actualizarFoto(_fotoPath);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tema.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: esOscuro ? .3 : .06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            if (!esOscuro)
              const BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                offset: Offset(-4, -4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BiomarkColors.blue.withValues(alpha: .12),
                image: _fotoPath != null
                    ? DecorationImage(
                        image: FileImage(File(_fotoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _fotoPath == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: BiomarkColors.blue,
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreUsuario,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _correoUsuario,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: tema.colorScheme.onSurface.withValues(alpha: .6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(ThemeData tema, String titulo, List<_ItemPerfil> items) {
    final esOscuro = tema.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tema.colorScheme.onSurface.withValues(alpha: .6),
            ),
          ),
        ),
        Container(
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
          child: Column(
            children: List.generate(items.length, (i) {
              final esUltimo = i == items.length - 1;
              return Column(
                children: [
                  _buildFila(tema, items[i]),
                  if (!esUltimo)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: tema.colorScheme.onSurface.withValues(alpha: .08),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFila(ThemeData tema, _ItemPerfil item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: BiomarkColors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tema.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: tema.colorScheme.onSurface.withValues(alpha: .35),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: si luego prefieres una sección específica de tu landing (por
  // ejemplo un ancla como #soporte), cambia esta URL.
  static const String _urlCentroDeAyuda =
      'https://biomark-landing-p.vercel.app';

  Future<void> _abrirCentroDeAyuda() async {
    final uri = Uri.parse(_urlCentroDeAyuda);
    final abierto =
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el enlace')),
      );
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final token = AuthSession.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
      try {
        await authApi.logout(accessToken: token);
      } catch (_) {
        // El cierre local debe funcionar aunque el backend no responda.
      } finally {
        authApi.dispose();
      }
    }
    await AuthSession.instance.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildBotonCerrarSesion(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cerrarSesion(context),
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 18,
        ),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ItemPerfil {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  _ItemPerfil({required this.icon, required this.label, this.onTap});
}
