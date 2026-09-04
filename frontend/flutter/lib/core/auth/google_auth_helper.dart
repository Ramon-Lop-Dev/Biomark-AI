import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);

  @override
  String toString() => message;
}

class GoogleAuthResult {
  final String idToken;
  final String? accessToken;
  final String? fullName;

  const GoogleAuthResult({
    required this.idToken,
    this.accessToken,
    this.fullName,
  });
}

class GoogleAuthHelper {
  GoogleAuthHelper._();

  static const _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '780734083560-ab3t99hnitsm0l98mbhgpi23orqu8d1j.apps.googleusercontent.com',
  );
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId.isNotEmpty ? _webClientId : null,
    scopes: const ['email', 'profile'],
  );

  static Future<GoogleAuthResult?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const GoogleAuthException(
          'Google no devolvió un id_token. Revisa GOOGLE_WEB_CLIENT_ID.',
        );
      }
      return GoogleAuthResult(
        idToken: idToken,
        accessToken: auth.accessToken,
        fullName: account.displayName,
      );
    } on GoogleAuthException {
      rethrow;
    } catch (error) {
      throw GoogleAuthException('No se pudo iniciar sesión con Google: $error');
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();
}
