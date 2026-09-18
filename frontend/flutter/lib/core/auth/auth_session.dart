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
  static const _kUserName = 'biomark_user_name';
  static const _kUserEmail = 'biomark_user_email';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String _role = 'USUARIO';
  String? _userName;
  String? _userEmail;
  bool _ready = false;

  bool get ready => _ready;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;
  String get role => _role;
  bool get isPromoter => _role == 'PROMOTOR';
  bool get isAdmin => _role == 'ADMIN';
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isExpired => _expiresAt != null &&
      DateTime.now().isAfter(_expiresAt!.subtract(const Duration(seconds: 60)));

  Future<void> init() async {
    _accessToken = await _storage.read(key: _kAccessToken);
    _refreshToken = await _storage.read(key: _kRefreshToken);
    final expiresRaw = await _storage.read(key: _kExpiresAt);
    _expiresAt = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
    _role = await _storage.read(key: _kRole) ?? 'USUARIO';
    _userName = await _storage.read(key: _kUserName);
    _userEmail = await _storage.read(key: _kUserEmail);
    _ready = true;
    notifyListeners();
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    String? role,
    String? userName,
    String? userEmail,
  }) async {
    _accessToken = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    if (role != null && role.isNotEmpty) _role = role;
    if (userName != null && userName.isNotEmpty) _userName = userName;
    if (userEmail != null && userEmail.isNotEmpty) _userEmail = userEmail;

    await _storage.write(key: _kAccessToken, value: _accessToken);
    if (_refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: _refreshToken);
    }
    await _storage.write(key: _kExpiresAt, value: _expiresAt!.toIso8601String());
    await _storage.write(key: _kRole, value: _role);
    if (_userName != null) {
      await _storage.write(key: _kUserName, value: _userName!);
    }
    if (_userEmail != null) {
      await _storage.write(key: _kUserEmail, value: _userEmail!);
    }
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (name != null && name.isNotEmpty) {
      _userName = name;
      await _storage.write(key: _kUserName, value: name);
    }
    if (email != null && email.isNotEmpty) {
      _userEmail = email;
      await _storage.write(key: _kUserEmail, value: email);
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _role = 'USUARIO';
    _userName = null;
    _userEmail = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
