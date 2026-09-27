import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';

class VerifiedInvitationInfo {
  final String token;
  final String contacto;
  final String rolDestino;
  final String centroSaludId;
  final String centroSaludNombre;
  final String? centroSaludMunicipio;
  final String? codigoEstablecimiento;
  final DateTime expiraEn;

  const VerifiedInvitationInfo({
    required this.token,
    this.contacto = '',
    required this.rolDestino,
    required this.centroSaludId,
    required this.centroSaludNombre,
    this.centroSaludMunicipio,
    this.codigoEstablecimiento,
    required this.expiraEn,
  });

  factory VerifiedInvitationInfo.fromJson(Map<String, dynamic> json) {
    final centro = json['centro_salud'] is Map<String, dynamic>
        ? json['centro_salud'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return VerifiedInvitationInfo(
      token: '${json['token'] ?? ''}',
      contacto: '${json['contacto'] ?? ''}',
      rolDestino: '${json['rol_destino'] ?? ''}',
      centroSaludId: '${centro['id'] ?? ''}',
      centroSaludNombre: '${centro['nombre'] ?? 'Centro de Salud'}',
      centroSaludMunicipio: centro['municipio'] as String?,
      codigoEstablecimiento: centro['codigo_establecimiento'] as String?,
      expiraEn: DateTime.tryParse('${json['expira_en'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class PromoterItem {
  final String id;
  final String email;
  final String fullName;
  final String estadoCuenta;
  final DateTime? fechaCreacion;

  const PromoterItem({
    required this.id,
    required this.email,
    required this.fullName,
    required this.estadoCuenta,
    this.fechaCreacion,
  });

  bool get isActivo => estadoCuenta == 'ACTIVO';

  factory PromoterItem.fromJson(Map<String, dynamic> json) {
    final perfil = json['perfiles'] is Map<String, dynamic>
        ? json['perfiles'] as Map<String, dynamic>
        : (json['perfiles'] is List && (json['perfiles'] as List).isNotEmpty)
            ? (json['perfiles'] as List).first as Map<String, dynamic>
            : null;

    return PromoterItem(
      id: '${json['id'] ?? ''}',
      email: '${json['correo'] ?? ''}',
      fullName: '${perfil?['nombre_completo'] ?? json['correo'] ?? 'Sin nombre'}',
      estadoCuenta: '${json['estado_cuenta'] ?? 'ACTIVO'}',
      fechaCreacion: DateTime.tryParse('${json['fecha_creacion'] ?? ''}'),
    );
  }
}

class InvitationsApi {
  InvitationsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  String get _base => AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthSession.instance.accessToken ?? ''}',
      };

  Future<Map<String, dynamic>> _jsonRequest(Future<http.Response> request) async {
    final response = await request;
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['error'] ?? body['message'] : null;
      throw Exception(message ?? 'Error al procesar la solicitud de invitación.');
    }
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  /// Verifica un token público de invitación
  Future<VerifiedInvitationInfo> verifyInvitation(String token) async {
    final cleanToken = token.trim().toUpperCase();
    final res = await _jsonRequest(
      _client.get(Uri.parse('$_base/api/invitations/verify/$cleanToken')),
    );
    return VerifiedInvitationInfo.fromJson(res);
  }

  /// Canjea el token de invitación para registrar y activar la cuenta con su rol
  Future<Map<String, dynamic>> acceptInvitation({
    required String token,
    required String email,
    required String password,
    required String fullName,
  }) async {
    return _jsonRequest(
      _client.post(
        Uri.parse('$_base/api/invitations/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token.trim().toUpperCase(),
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
        }),
      ),
    );
  }

  /// El Trabajador de Salud o Admin invita a un Promotor (con centro opcional para Admin)
  Future<Map<String, dynamic>> createPromoterInvitation({
    required String contacto,
    String? centroSaludId,
    int expiraDias = 7,
  }) async {
    final payload = <String, dynamic>{
      'contacto': contacto.trim(),
      'expira_dias': expiraDias,
    };
    if (centroSaludId != null) {
      payload['centro_salud_id'] = centroSaludId;
    }

    return _jsonRequest(
      _client.post(
        Uri.parse('$_base/api/invitations/promoter'),
        headers: _headers,
        body: jsonEncode(payload),
      ),
    );
  }

  /// El Administrador invita a un Trabajador de Salud para un Centro de Salud
  Future<Map<String, dynamic>> createHealthWorkerInvitation({
    required String contacto,
    required String centroSaludId,
    int expiraDias = 7,
  }) async {
    return _jsonRequest(
      _client.post(
        Uri.parse('$_base/api/invitations/health-worker'),
        headers: _headers,
        body: jsonEncode({
          'contacto': contacto.trim(),
          'centro_salud_id': centroSaludId,
          'expira_dias': expiraDias,
        }),
      ),
    );
  }

  /// Lista los promotores asignados al centro de salud del Trabajador de Salud
  Future<List<PromoterItem>> getMyPromoters() async {
    final response = await _client.get(
      Uri.parse('$_base/api/invitations/my-promoters'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar la red de promotores.');
    }
    final data = jsonDecode(response.body);
    return data is List
        ? data.whereType<Map<String, dynamic>>().map(PromoterItem.fromJson).toList()
        : const [];
  }

  /// Cambia el estado de un promotor (ACTIVO o SUSPENDIDO)
  Future<void> updatePromoterStatus(String promoterId, String estado) async {
    await _jsonRequest(
      _client.patch(
        Uri.parse('$_base/api/invitations/promoters/$promoterId/status'),
        headers: _headers,
        body: jsonEncode({'estado': estado}),
      ),
    );
  }

  void dispose() => _client.close();
}
