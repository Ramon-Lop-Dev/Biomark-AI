// Punto único de configuración del backend y servicios públicos.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'BIOMARK_API_URL',
    defaultValue: 'https://biomark-api.duckdns.org',
  );

  static String get cartoApiKey {
    final value =
        dotenv.env['CARTO_API_KEY'] ??
        const String.fromEnvironment('CARTO_API_KEY');
    return value.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), '');
  }
}
