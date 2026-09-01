import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/health_center.dart';

class GisApiException implements Exception {
  final String message;
  final int? statusCode;

  const GisApiException(this.message, {this.statusCode});
}

class GisMapData {
  final List<HealthCenter> centers;
  final List<RiskZone> riskZones;

  const GisMapData({required this.centers, required this.riskZones});
}

class GisApi {
  GisApi({http.Client? client}) : _client = client ?? http.Client();

  static const _apiUrl = String.fromEnvironment(
    'BIOMARK_API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const _accessToken = String.fromEnvironment('BIOMARK_ACCESS_TOKEN');
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
    );
  }

  void dispose() => _client.close();
}
