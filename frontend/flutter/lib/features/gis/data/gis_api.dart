import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';

import '../domain/health_center.dart';

class GisApiException implements Exception {
  final String message;
  final int? statusCode;

  const GisApiException(this.message, {this.statusCode});
}

class GisMapData {
  final List<HealthCenter> centers;
  final List<RiskZone> riskZones;
  final List<CommunityEvent> events;
  final List<CommunityReportPoint> reports;

  const GisMapData({required this.centers, required this.riskZones, required this.events, required this.reports});
}

class GisViewportData {
  final List<HealthCenter> centers;
  const GisViewportData({required this.centers});
}

class GisApi {
  GisApi({http.Client? client}) : _client = client ?? http.Client();

  static final _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      };

  Future<GisViewportData> fetchViewport({
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
    required double zoom,
  }) async {
    final uri = Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/gis/centros').replace(
      queryParameters: {
        'min_lon': '$minLon',
        'min_lat': '$minLat',
        'max_lon': '$maxLon',
        'max_lat': '$maxLat',
        'zoom': '$zoom',
      },
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException(
        response.statusCode == 429
            ? 'Demasiadas peticiones. Espera unos minutos.'
            : 'No se pudieron cargar los centros de salud.',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(response.body);
    if (body is! List) throw const GisApiException('Respuesta GIS inválida.');
    return GisViewportData(
      centers: body.whereType<Map<String, dynamic>>().map(HealthCenter.fromJson).toList(),
    );
  }

  Future<HealthCenter> fetchCenterDetails(String id) async {
    final response = await _client.get(
      Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/gis/centros/$id'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException('No se pudo cargar el centro de salud.', statusCode: response.statusCode);
    }
    return HealthCenter.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<GisMapData> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) async {
    final uri =
        Uri.parse(
          '${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/gis/smart-map',
        ).replace(
          queryParameters: {
            'latitude': '$latitude',
            'longitude': '$longitude',
            'radius_km': '$radiusKm',
          },
        );
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException(
        'No se pudieron cargar los centros de salud.',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const GisApiException('Respuesta GIS inválida.');
    }

    List<Map<String, dynamic>> maps(dynamic value) => value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : const [];

    return GisMapData(
      centers: maps(body['centros_salud']).map(HealthCenter.fromJson).toList(),
      riskZones: maps(body['zonas_riesgo']).map(RiskZone.fromJson).toList(),
      events: maps(body['eventos_comunitarios']).map(CommunityEvent.fromJson).where((event) => event.latitude != 0 && event.longitude != 0).toList(),
      reports: const [],
    );
  }

  Future<GisMapData> fetchLayers({required double latitude, required double longitude}) =>
      fetchNearby(latitude: latitude, longitude: longitude);

  Future<List<CommunityReportPoint>> fetchValidatedReports() async {
    final response = await _client.get(
      Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/community/heatmap'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException('No se pudieron cargar los reportes comunitarios.', statusCode: response.statusCode);
    }
    final body = jsonDecode(response.body);
    return body is List
        ? body.whereType<Map<String, dynamic>>().map(CommunityReportPoint.fromJson).toList()
        : const [];
  }

  Future<void> createCommunityReport({
    required double latitude,
    required double longitude,
    required String description,
    int caseCount = 1,
  }) async {
    final response = await _client.post(
      Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/community/reports'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_accessToken'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'case_count': caseCount,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException('No se pudo registrar el reporte comunitario.', statusCode: response.statusCode);
    }
  }

  void dispose() => _client.close();
}
