// Punto único de configuración del backend.
class AppConfig {
  AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'BIOMARK_API_URL',
    defaultValue: 'https://biomark-api.duckdns.org',
  );
}
