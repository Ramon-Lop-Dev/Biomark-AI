import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/editar_perfil.dart';
import 'package:flutter_biomark/notifications.dart';
import 'package:flutter_biomark/privacidad.dart';
import 'package:flutter_biomark/apariencia.dart';
import 'package:flutter_biomark/seguridad_screen.dart';
import 'package:flutter_biomark/survey_service.dart';
import 'package:flutter_biomark/main.dart';
import 'package:flutter_biomark/core/auth/auth_api.dart';
import 'package:flutter_biomark/core/auth/auth_session.dart';
import 'package:flutter_biomark/core/config/app_config.dart';
import 'package:flutter_biomark/features/community/promoter_screens.dart';
import 'package:flutter_biomark/core/profile/user_profile_api.dart';
import 'package:flutter_biomark/core/ui/biomark_dialog.dart';
import 'package:flutter_biomark/features/community/recommendations_management_screen.dart';
import 'package:flutter_biomark/health_history.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Antes eran "static const". Ahora son variables de instancia para
  // poder actualizarlas con setState al volver de EditarPerfilScreen.
  String _nombreUsuario = 'Cargando...';
  String _correoUsuario = 'Cargando...';
  DateTime? _fechaNacimientoUsuario;
  int? _edadUsuario; // calculado dinámicamente según fecha de nacimiento
  String? _fotoUrl;
  String? _generoUsuario;
  bool _eliminandoCuenta = false;

  @override
  void initState() {
    super.initState();
    final cachedName = AuthSession.instance.userName;
    final cachedEmail = AuthSession.instance.userEmail;
    if (cachedName != null && cachedName.isNotEmpty) {
      _nombreUsuario = cachedName;
    }
    if (cachedEmail != null && cachedEmail.isNotEmpty) {
      _correoUsuario = cachedEmail;
    }
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final profile = await UserProfileApi.fetch();
      if (profile == null || !mounted) return;
      await AuthSession.instance.updateProfile(
        name: profile.displayName,
        email: profile.email,
      );
      setState(() {
        _nombreUsuario = profile.displayName;
        _correoUsuario = profile.email;
        _generoUsuario = profile.gender;
        _fotoUrl = profile.photoUrl;
        _fechaNacimientoUsuario = profile.birthDate;
        _edadUsuario = profile.birthDate == null
            ? null
            : _calculateAge(profile.birthDate!);
      });
      await SurveyService.cargarDesdeBackend();
    } catch (_) {}
  }

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _actualizarDatos(Map<String, dynamic> values) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    final changes = <String, dynamic>{};
    if (values['nombre'] is String &&
        (values['nombre'] as String).trim().isNotEmpty) {
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
    if (values['fechaNacimiento'] is DateTime) {
      final dt = values['fechaNacimiento'] as DateTime;
      changes['fecha_nacimiento'] = dt.toIso8601String().split('T').first;
    }
    if (changes.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse(
          '${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(changes),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (values['nombre'] is String &&
            (values['nombre'] as String).trim().isNotEmpty) {
          await AuthSession.instance.updateProfile(
            name: (values['nombre'] as String).trim(),
          );
        }
        if (mounted) await _cargarPerfil();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mensajeError(response.body, 'No se pudo actualizar el perfil.'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el perfil: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _subirFotoBytes(Uint8List bytes, String filename) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    final lowerName = filename.toLowerCase();
    MediaType contentType;
    if (lowerName.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (lowerName.endsWith('.webp')) {
      contentType = MediaType('image', 'webp');
    } else {
      contentType = MediaType('image', 'jpeg');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              '${AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/users/profile/photo',
            ),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes(
              'foto',
              bytes,
              filename: filename,
              contentType: contentType,
            ),
          );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _cargarPerfil();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada correctamente.'),
            backgroundColor: BiomarkColors.green,
          ),
        );
      } else {
        String mensaje = 'No se pudo guardar la foto de perfil.';
        try {
          mensaje = _mensajeError(response.body, mensaje);
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo conectar para guardar la foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mensajeError(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['error'] ?? decoded['message'] ?? decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
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
          maxLines: 2,
          softWrap: true,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
            _buildEncabezado(),
            const SizedBox(height: 24),
            _buildSeccion('Cuenta', [
              _ItemPerfil(
                icon: Icons.person_outline_rounded,
                label: 'Mis datos de perfil y cuenta',
                onTap: _abrirEditarPerfil,
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
                label: 'Historial médico y antecedentes (Encuesta)',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AntecedentesScreen(),
                    ),
                  );
                  if (mounted) await _cargarPerfil();
                },
              ),
              if (!AuthSession.instance.isPromoter &&
                  !AuthSession.instance.isAdmin)
                _ItemPerfil(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Solicitar ser promotor',
                  onTap: () => _solicitarPromotor(context),
                ),
              if (AuthSession.instance.isAdmin)
                _ItemPerfil(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Solicitudes de promotor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminRoleRequestsScreen(),
                    ),
                  ),
                ),
              if (AuthSession.instance.isPromoter || AuthSession.instance.isAdmin)
                _ItemPerfil(
                  icon: Icons.verified_user_outlined,
                  label: 'Pautas y Recomendaciones MINSA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecommendationsManagementScreen(),
                    ),
                  ),
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
            const SizedBox(height: 12),
            _buildBotonEliminarCuenta(context),
          ],
        ),
      ),
    ),
  ),
);
  }

  Future<void> _abrirEditarPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(
          nombreActual: _nombreUsuario,
          correo: _correoUsuario,
          edad: _edadUsuario,
          fechaNacimiento: _fechaNacimientoUsuario,
          fotoUrl: _fotoUrl,
          generoActual: _generoUsuario,
        ),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _nombreUsuario = resultado['nombre'] ?? _nombreUsuario;
        _generoUsuario = resultado['genero'] ?? _generoUsuario;
        if (resultado['fechaNacimiento'] is DateTime) {
          _fechaNacimientoUsuario = resultado['fechaNacimiento'] as DateTime;
          _edadUsuario = _calculateAge(_fechaNacimientoUsuario!);
        }
      });
      await _actualizarDatos(resultado);
      final fotoBytes = resultado['fotoBytes'];
      final fotoNombre = resultado['fotoNombre'] as String? ?? 'perfil.jpg';
      if (fotoBytes is Uint8List) {
        await _subirFotoBytes(fotoBytes, fotoNombre);
      }
    }
  }

  Widget _buildEncabezado() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _abrirEditarPerfil,
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
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final current = await http.get(
        Uri.parse('$base/api/auth/promotor/solicitud'),
        headers: headers,
      );
      if (!context.mounted) return;
      final currentBody = current.body.isEmpty
          ? null
          : jsonDecode(current.body);
      final currentStatus = currentBody is Map<String, dynamic>
          ? currentBody['estado'] as String?
          : null;
      if (currentStatus == 'PENDIENTE') {
        _showPromoterMessage(
          context,
          'Tu solicitud está pendiente de revisión administrativa.',
        );
        return;
      }
      final confirmed = await BiomarkDialog.showConfirm(
        context,
        icon: Icons.volunteer_activism_rounded,
        iconColor: BiomarkColors.green,
        title: 'Solicitar rol de promotor',
        message: 'Podrás organizar jornadas y validar reportes comunitarios. Un administrador revisará tu solicitud antes de activar el rol.',
        confirmLabel: 'Enviar solicitud',
        cancelLabel: 'Cancelar',
      );
      if (!confirmed || !context.mounted) return;
      final response = await http.post(
        Uri.parse('$base/api/auth/promotor/solicitud'),
        headers: headers,
      );
      if (!context.mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showPromoterMessage(
          context,
          'Solicitud enviada. Te avisaremos cuando sea revisada.',
        );
      } else {
        final body = response.body.isEmpty ? null : jsonDecode(response.body);
        _showPromoterMessage(
          context,
          body is Map<String, dynamic>
              ? '${body['error'] ?? 'No se pudo enviar la solicitud.'}'
              : 'No se pudo enviar la solicitud.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showPromoterMessage(context, 'No se pudo conectar con el servidor.');
      }
    }
  }

  void _showPromoterMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

  Widget _buildBotonEliminarCuenta(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: _eliminandoCuenta ? null : () => _confirmarEliminarCuenta(context),
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: Colors.redAccent,
          size: 18,
        ),
        label: Text(
          _eliminandoCuenta ? 'Eliminando cuenta...' : 'Eliminar mi cuenta y perfil',
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarCuenta(BuildContext context) async {
    final confirmed = await BiomarkDialog.showConfirm(
      context,
      title: '¿Eliminar tu cuenta y perfil?',
      message: 'Esta acción es permanente e irreversible. Se darán de baja definitivamente '
          'tus credenciales de acceso, tu perfil, tus antecedentes médicos y '
          'todo tu historial en Biomark AI. No se puede deshacer.',
      confirmLabel: 'Eliminar definitivamente',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      _ejecutarEliminarCuenta();
    }
  }

  Future<void> _ejecutarEliminarCuenta() async {
    setState(() => _eliminandoCuenta = true);
    try {
      final token = AuthSession.instance.accessToken;
      if (token == null || token.isEmpty) throw Exception('Sesión expirada.');
      final authApi = AuthApi(baseUrl: AppConfig.apiUrl);
      try {
        await authApi.deleteAccount(accessToken: token);
      } finally {
        authApi.dispose();
      }
      await AuthSession.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _eliminandoCuenta = false);
      await BiomarkDialog.showError(
        context,
        title: 'Error al eliminar',
        message: 'No se pudo eliminar la cuenta: $error',
      );
    }
  }
}

class _ItemPerfil {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  _ItemPerfil({required this.icon, required this.label, this.onTap});
}
