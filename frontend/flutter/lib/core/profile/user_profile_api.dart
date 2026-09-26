import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../config/app_config.dart';

class UserProfile {
  const UserProfile({
    required this.email,
    this.fullName,
    this.photoUrl,
    this.birthDate,
    this.gender,
    this.entrevistaCompletada = false,
    this.peso,
    this.altura,
    this.fuma,
    this.alcohol,
    this.actividadFisica,
    this.telefono,
    this.direccion,
    this.municipio,
  });

  final String email;
  final String? fullName;
  final String? photoUrl;
  final DateTime? birthDate;
  final String? gender;
  final bool entrevistaCompletada;
  final double? peso;
  final double? altura;
  final String? fuma;
  final String? alcohol;
  final String? actividadFisica;
  final String? telefono;
  final String? direccion;
  final String? municipio;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final localPart = email.split('@').first.trim();
    return localPart.isNotEmpty ? localPart : 'usuario';
  }
}

class UserProfileApi {
  const UserProfileApi._();

  static Future<UserProfile?> fetch() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return null;

    final base = AppConfig.apiUrl.replaceFirst(RegExp(r'/$'), '');
    final response = await http.get(
      Uri.parse('$base/api/users/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final rawProfile = decoded['perfiles'];
    final profile = rawProfile is Map<String, dynamic>
        ? rawProfile
        : rawProfile is List && rawProfile.isNotEmpty && rawProfile.first is Map
            ? Map<String, dynamic>.from(rawProfile.first as Map)
            : const <String, dynamic>{};
    final email = '${decoded['correo'] ?? ''}'.trim();
    if (email.isEmpty) return null;

    return UserProfile(
      email: email,
      fullName: _text(profile['nombre_completo']),
      photoUrl: _text(profile['foto_url']),
      birthDate: DateTime.tryParse('${profile['fecha_nacimiento'] ?? ''}'),
      gender: _text(profile['sexo']),
      entrevistaCompletada: profile['entrevista_completada'] == true,
      peso: (profile['peso'] as num?)?.toDouble(),
      altura: (profile['altura'] as num?)?.toDouble(),
      fuma: _text(profile['fuma']),
      alcohol: _text(profile['alcohol']),
      actividadFisica: _text(profile['actividad_fisica']),
      telefono: _text(profile['telefono']),
      direccion: _text(profile['direccion']),
      municipio: _text(profile['municipio']),
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}