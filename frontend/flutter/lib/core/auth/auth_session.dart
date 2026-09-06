import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._internal();
  static final AuthSession instance = AuthSession._internal();

  static const _storage = FlutterSecureStorage();
  static const _kAccessToken = 'biomark_access_token';
  static const _kRefreshToken = 'biomark_refresh_token';
  static const _kExpiresAt = 'biomark_expires_at';
  static const _kRole = 'biomark_role';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String _role = 'USUARIO';
  bool _ready = false;

  bool get ready => _ready;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  String get role => _role;
  bool get isPromoter => _role == 'PROMOTOR';
  bool get isAdmin => _role == 'ADMIN';
  bool get isExpired => _expiresAt != null &&
      DateTime.now().isAfter(_expiresAt!.subtract(const Duration(seconds: 60)));

  Future<void> init() async {
    _accessToken = await _storage.read(key: _kAccessToken);
    _refreshToken = await _storage.read(key: _kRefreshToken);
    final expiresRaw = await _storage.read(key: _kExpiresAt);
    _expiresAt = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
    _role = await _storage.read(key: _kRole) ?? 'USUARIO';
    _ready = true;
    notifyListeners();
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    String? role,
  }) async {
    _accessToken = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    if (role != null && role.isNotEmpty) _role = role;

    await _storage.write(key: _kAccessToken, value: _accessToken);
    if (_refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: _refreshToken);
    }
    await _storage.write(key: _kExpiresAt, value: _expiresAt!.toIso8601String());
    await _storage.write(key: _kRole, value: _role);
    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _role = 'USUARIO';
    await _storage.deleteAll();
    notifyListeners();
  }
}
