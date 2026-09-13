import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_api.dart';
import '../auth/auth_session.dart';
import '../config/app_config.dart';
import '../config/firebase_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthApi _authApi = AuthApi(baseUrl: AppConfig.apiUrl);
  bool _initialized = false;
  String? _currentToken;
  final StreamController<String> _tokenController = StreamController<String>.broadcast();

  Stream<String> get tokenStream => _tokenController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    AuthSession.instance.addListener(_syncTokenWithAuthenticatedUser);

    if (kIsWeb && !FirebaseConfig.webIsConfigured) {
      debugPrint('Firebase Web no está configurado. Push deshabilitado hasta completar variables.');
      _initialized = true;
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Permiso FCM denegado por el usuario.');
        _initialized = true;
        return;
      }

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FCM foreground message: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM tap notification: ${message.data}');
      });

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      final token = await registerToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _registerTokenInBackend(token);
        _tokenController.add(token);
      }

      _initialized = true;
      debugPrint('Servicio FCM inicializado correctamente.');
    } catch (error) {
      debugPrint('No fue posible inicializar FCM: $error');
      _initialized = true;
    }
  }

  Future<String?> registerToken() async {
    try {
      final token = kIsWeb
          ? await _messaging.getToken(vapidKey: FirebaseConfig.vapidKey)
          : await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('No se obtuvo token FCM.');
        return null;
      }

      debugPrint('FCM token generado: $token');
      return token;
    } catch (error) {
      debugPrint('Error al obtener token FCM: $error');
      return null;
    }
  }

  Future<void> refreshToken() async {
    await _messaging.onTokenRefresh.first;
    final token = await registerToken();
    if (token != null) {
      _currentToken = token;
      await _registerTokenInBackend(token);
      _tokenController.add(token);
    }
  }

  Future<void> _syncTokenWithAuthenticatedUser() async {
    final token = _currentToken;
    if (_initialized && token != null && token.isNotEmpty) {
      await _registerTokenInBackend(token);
    }
  }

  Future<void> _registerTokenInBackend(String token) async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      await _authApi.registerPushToken(
        accessToken: accessToken,
        token: token,
        platform: kIsWeb ? 'WEB' : 'ANDROID',
      );
      debugPrint('Token FCM registrado en el backend.');
    } catch (error) {
      debugPrint('No se pudo registrar el token FCM en el backend: $error');
    }
  }

  Future<void> logout() async {
    AuthSession.instance.removeListener(_syncTokenWithAuthenticatedUser);
    try {
      await _messaging.deleteToken();
      debugPrint('Token FCM eliminado en logout seguro.');
    } catch (error) {
      debugPrint('No se pudo borrar token FCM en logout: $error');
    }

    await AuthSession.instance.clear();
  }
}
