import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static String get webApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';

  static String get webAppId => dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';

  static String get messagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get authDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';

  static String get projectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'biomark-ai-prod';

  static String get storageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'biomark-ai-prod.firebasestorage.app';

  static String get vapidKey => dotenv.env['FIREBASE_VAPID_KEY'] ?? '';

  static bool get webIsConfigured =>
      kIsWeb &&
      webApiKey.isNotEmpty &&
      webAppId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      authDomain.isNotEmpty;

  static Future<void> initialize() async {
    if (kIsWeb) {
      if (!webIsConfigured) {
        debugPrint(
          'Firebase Web no está configurado. Define FIREBASE_WEB_API_KEY, '
          'FIREBASE_WEB_APP_ID, FIREBASE_MESSAGING_SENDER_ID y FIREBASE_AUTH_DOMAIN.',
        );
        return;
      }

      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: webApiKey,
          appId: webAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: authDomain,
          storageBucket: storageBucket,
        ),
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      debugPrint('Firebase inicializado para Android con configuración de proyecto.');
    } on FirebaseException catch (error) {
      debugPrint('Firebase no pudo inicializarse en Android: ${error.message ?? error.code}');
    } catch (error) {
      debugPrint('Firebase no pudo inicializarse: $error');
    }
  }
}
