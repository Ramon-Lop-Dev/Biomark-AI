import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthSessionResult {
  final String token;
  final String? refreshToken;
  final int expiresIn;
  final bool isNewUser;

  const AuthSessionResult({
    required this.token,
    this.refreshToken,
    required this.expiresIn,
    this.isNewUser = false,
  });
}

class RegisterResult {
  final String userId;
  final String? token;
  final String? refreshToken;
  final int? expiresIn;

  const RegisterResult({required this.userId, this.token, this.refreshToken, this.expiresIn});

  bool get requiresEmailConfirmation => token == null;
}

class AuthApi {
  AuthApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String get _base => baseUrl.replaceFirst(RegExp(r'/$'), '');

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? bearerToken,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_base$path'),
            headers: {
              'Content-Type': 'application/json',
              if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> decoded = const {};
      if (response.body.isNotEmpty) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'] ?? decoded['message'] ?? decoded['detail'];
        throw AuthApiException(
          error is String
              ? error
              : 'Ocurrió un error inesperado (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on AuthApiException {
      rethrow;
    } on FormatException {
      throw const AuthApiException('El servidor devolvió una respuesta inválida.');
    } catch (error) {
      throw AuthApiException('No se pudo conectar con el servidor: $error');
    }
  }

  Future<RegisterResult> register({
    required String email,
    required String password,
    required String fullName,
    String accountType = 'PERSONAL',
  }) async {
    final json = await _post('/api/auth/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
        'tipo_cuenta': accountType,
    });
    return RegisterResult(
      userId: json['user_id'] as String? ?? '',
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
    );
  }

  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    final json = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthSessionResult(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
    );
  }

  Future<AuthSessionResult> loginWithGoogle({
    required String idToken,
    String? accessToken,
    String? fullName,
  }) async {
    final json = await _post('/api/auth/google', {
      'id_token': idToken,
      'access_token': ?accessToken,
      'full_name': ?fullName,
    });
    return AuthSessionResult(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Future<AuthSessionResult> refresh({required String refreshToken}) async {
    final json = await _post('/api/auth/refresh', {
      'refresh_token': refreshToken,
    });
    return AuthSessionResult(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
    );
  }

  Future<String> forgotPassword({required String email, required String redirectTo}) async {
    final json = await _post('/api/auth/forgot-password', {
      'email': email,
      'redirect_to': redirectTo,
    });
    return json['message'] as String? ??
        'Si existe una cuenta con ese correo, se enviaron instrucciones para restablecer la contraseña.';
  }

  Future<String> resetPassword({
    required String accessToken,
    required String newPassword,
  }) async {
    final json = await _post('/api/auth/reset-password', {
      'access_token': accessToken,
      'new_password': newPassword,
    });
    return json['message'] as String? ?? 'Contraseña actualizada correctamente';
  }

  Future<void> logout({required String accessToken}) async {
    await _post('/api/auth/logout', const {}, bearerToken: accessToken);
  }

  void dispose() => _client.close();
}
