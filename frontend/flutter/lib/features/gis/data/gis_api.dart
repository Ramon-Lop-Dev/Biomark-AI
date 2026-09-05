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

class GisApi {
  GisApi({http.Client? client}) : _client = client ?? http.Client();

  static const _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';
  final http.Client _client;

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
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
      },
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
