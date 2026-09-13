// Pantalla de perfil de usuario — Biomark AI
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'biomark_brand.dart';
import 'datos_personales.dart';
import 'editar_perfil.dart';
import 'notifications.dart';
import 'privacidad.dart';
import 'apariencia.dart';
import 'seguridad_screen.dart';
import 'health_survey.dart';
import 'survey_service.dart';
import 'main.dart'; // para poder cerrar sesión y volver a LoginScreen
import 'core/auth/auth_api.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'features/community/promoter_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Antes eran "static const". Ahora son variables de instancia para
  // poder actualizarlas con setState al volver de EditarPerfilScreen.
  String _nombreUsuario = 'Familia';
  String _correoUsuario = 'usuario@correo.com';
  int? _edadUsuario; // viene de la encuesta hecha en el chat
  String? _fotoUrl;
  String? _generoUsuario;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300 || !mounted) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = body['perfiles'] as Map<String, dynamic>? ?? const {};
      final birth = DateTime.tryParse('${profile['fecha_nacimiento'] ?? ''}');
      setState(() {
        _nombreUsuario = '${profile['nombre_completo'] ?? _nombreUsuario}';
        _correoUsuario = '${body['correo'] ?? _correoUsuario}';
        _generoUsuario = profile['sexo'] as String?;
        _fotoUrl = profile['foto_url'] as String?;
        _edadUsuario = birth == null ? null : _calculateAge(birth);
      });
      await SurveyService.cargarDesdeBackend();
    } catch (_) {}
  }

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  Future<void> _actualizarDatos(Map<String, dynamic> values) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    final changes = <String, dynamic>{};
    if (values['nombre'] is String && (values['nombre'] as String).trim().isNotEmpty) {
      changes['nombre_completo'] = (values['nombre'] as String).trim();
    }
    if (values['genero'] is String) {
      const genderMap = {
        'Femenino': 'FEMENINO',
        'Masculino': 'MASCULINO',
        'Otro': 'OTRO',
        'Prefiero no decir': 'NO_ESPECIFICA',
      };
      changes['sexo'] = genderMap[values['genero']] ?? values['genero'];
    }
    if (changes.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/profile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(changes),
      );
      if (response.statusCode >= 200 && response.statusCode < 300 && mounted) await _cargarPerfil();
    } catch (_) {}
  }

  Future<void> _subirFoto(File foto) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/profile/photo'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('foto', foto.path));

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _cargarPerfil();
      } else {
        String mensaje = 'No se pudo guardar la foto de perfil.';
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          final detalle = decoded['error'];
          if (detalle is String && detalle.trim().isNotEmpty) {
            mensaje = detalle;
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar para guardar la foto.')),
        );
      }
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
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
            _buildEncabezado(),
            const SizedBox(height: 24),
            _buildSeccion('Cuenta', [
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
                    await _actualizarDatos(resultado);
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
              _ItemPerfil(
                icon: Icons.assignment_outlined,
                label: 'Editar encuesta clínica',
                onTap: () async {
                  final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const HealthSurveyScreen(editing: true)));
                  if (updated == true && mounted) await _cargarPerfil();
                },
              ),
              if (!AuthSession.instance.isPromoter && !AuthSession.instance.isAdmin)
                _ItemPerfil(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Solicitar ser promotor',
                  onTap: () => _solicitarPromotor(context),
                ),
              if (AuthSession.instance.isAdmin)
                _ItemPerfil(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Solicitudes de promotor',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRoleRequestsScreen())),
                ),
            ]),
            const SizedBox(height: 18),
            _buildSeccion('Preferencias', [
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
            _buildSeccion('Soporte', [
              _ItemPerfil(
                icon: Icons.help_outline_rounded,
                label: 'Centro de ayuda',
              ),
              _ItemPerfil(
                icon: Icons.info_outline_rounded,
                label: 'Acerca de Biomark AI',
              ),
            ]),
            const SizedBox(height: 28),
            _buildBotonCerrarSesion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
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
              fotoUrl: _fotoUrl,
            ),
          ),
        );

        if (resultado != null && mounted) {
          setState(() {
            _nombreUsuario = resultado['nombre'] ?? _nombreUsuario;
          });
          await _actualizarDatos(resultado);
          final foto = resultado['foto'];
          if (foto is File) await _subirFoto(foto);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                image: _fotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_fotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _fotoUrl == null
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _correoUsuario,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<_ItemPerfil> items) {
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
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
                  _buildFila(items[i]),
                  if (!esUltimo)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Theme.of(context).dividerColor,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFila(_ItemPerfil item) {
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
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

  Future<void> _solicitarPromotor(BuildContext context) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    try {
      final current = await http.get(Uri.parse('$base/api/auth/promotor/solicitud'), headers: headers);
      if (!context.mounted) return;
      final currentBody = current.body.isEmpty ? null : jsonDecode(current.body);
      final currentStatus = currentBody is Map<String, dynamic> ? currentBody['estado'] as String? : null;
      if (currentStatus == 'PENDIENTE') {
        _showPromoterMessage(context, 'Tu solicitud está pendiente de revisión administrativa.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.volunteer_activism_rounded, color: BiomarkColors.green, size: 42),
          title: const Text('Solicitar rol de promotor'),
          content: const Text('Podrás organizar jornadas y validar reportes comunitarios. Un administrador revisará tu solicitud antes de activar el rol.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Enviar solicitud')),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final response = await http.post(Uri.parse('$base/api/auth/promotor/solicitud'), headers: headers);
      if (!context.mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showPromoterMessage(context, 'Solicitud enviada. Te avisaremos cuando sea revisada.');
      } else {
        final body = response.body.isEmpty ? null : jsonDecode(response.body);
        _showPromoterMessage(context, body is Map<String, dynamic> ? '${body['error'] ?? 'No se pudo enviar la solicitud.'}' : 'No se pudo enviar la solicitud.');
      }
    } catch (_) {
      if (context.mounted) _showPromoterMessage(context, 'No se pudo conectar con el servidor.');
    }
  }

  void _showPromoterMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
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
