import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthApi _authApi = AuthApi(baseUrl: AppConfig.apiUrl);
  bool _initialized = false;
  String? _currentToken;
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  Stream<String> get tokenStream => _tokenController.stream;
  String? get currentToken => _currentToken;

  Future<bool> enableForCurrentUser() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    final token = _currentToken ?? await registerToken();
    final accessToken = AuthSession.instance.accessToken;
    if (token == null ||
        token.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      return false;
    }

    await _registerTokenInBackend(token);
    _currentToken = token;
    _tokenController.add(token);
    return true;
  }

  Future<void> disableForCurrentUser() async {
    final token = _currentToken ?? await registerToken();
    final accessToken = AuthSession.instance.accessToken;
    if (token == null ||
        token.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      return;
    }
    await _authApi.deletePushToken(accessToken: accessToken, token: token);
  }

  Future<void> initialize() async {
    if (_initialized) return;

    AuthSession.instance.addListener(_syncTokenWithAuthenticatedUser);

    if (kIsWeb && !FirebaseConfig.webIsConfigured) {
      debugPrint(
        'Firebase Web no está configurado. Push deshabilitado hasta completar variables.',
      );
      _initialized = true;
      return;
    }

    try {
      if (!kIsWeb) {
        const initializationSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
        await _localNotifications.initialize(initializationSettings);
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

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
        debugPrint('FCM RAW notification: ${message.notification}');
        debugPrint('FCM RAW data: ${message.data}');
        debugPrint('FCM RAW messageId: ${message.messageId}');
        _showForegroundNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('FCM tap notification: ${message.data}');
      });

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
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

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }
    await _localNotifications.show(
      message.hashCode,
      title ?? 'Biomark AI',
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'biomark_notifications',
          'Notificaciones de Biomark AI',
          channelDescription: 'Recordatorios y alertas de Biomark AI',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
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
