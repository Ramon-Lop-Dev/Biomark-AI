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

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  const _CacheEntry(this.data, this.timestamp);

  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}

class GisApi {
  GisApi({http.Client? client}) : _client = client ?? http.Client();

  static final _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';
  final http.Client _client;

  // Caché en memoria para evitar saturar el backend al mover el mapa o reingresar a la pantalla
  static final Map<String, _CacheEntry<GisViewportData>> _viewportCache = {};
  static final Map<String, _CacheEntry<GisMapData>> _layersCache = {};
  static _CacheEntry<List<CommunityReportPoint>>? _reportsCache;
  static final Map<String, _CacheEntry<HealthCenter>> _centerDetailsCache = {};

  static void clearCache() {
    _viewportCache.clear();
    _layersCache.clear();
    _reportsCache = null;
    _centerDetailsCache.clear();
  }

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
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${minLon.toStringAsFixed(2)}_${minLat.toStringAsFixed(2)}_${maxLon.toStringAsFixed(2)}_${maxLat.toStringAsFixed(2)}_${zoom.round()}';

    if (!forceRefresh) {
      final cached = _viewportCache[cacheKey];
      if (cached != null && !cached.isExpired(const Duration(minutes: 5))) {
        return cached.data;
      }
    }

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
    final result = GisViewportData(
      centers: body.whereType<Map<String, dynamic>>().map(HealthCenter.fromJson).toList(),
    );
    _viewportCache[cacheKey] = _CacheEntry(result, DateTime.now());
    if (_viewportCache.length > 60) {
      _viewportCache.remove(_viewportCache.keys.first);
    }
    return result;
  }

  Future<HealthCenter> fetchCenterDetails(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _centerDetailsCache[id];
      if (cached != null && !cached.isExpired(const Duration(minutes: 10))) {
        return cached.data;
      }
    }

    final response = await _client.get(
      Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/gis/centros/$id'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException('No se pudo cargar el centro de salud.', statusCode: response.statusCode);
    }
    final result = HealthCenter.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    _centerDetailsCache[id] = _CacheEntry(result, DateTime.now());
    return result;
  }

  Future<GisMapData> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_${radiusKm.round()}';

    if (!forceRefresh) {
      final cached = _layersCache[cacheKey];
      if (cached != null && !cached.isExpired(const Duration(minutes: 5))) {
        return cached.data;
      }
    }

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

    final result = GisMapData(
      centers: maps(body['centros_salud']).map(HealthCenter.fromJson).toList(),
      riskZones: maps(body['zonas_riesgo']).map(RiskZone.fromJson).toList(),
      events: maps(body['eventos_comunitarios']).map(CommunityEvent.fromJson).where((event) => event.latitude != 0 && event.longitude != 0).toList(),
      reports: const [],
    );
    _layersCache[cacheKey] = _CacheEntry(result, DateTime.now());
    if (_layersCache.length > 30) {
      _layersCache.remove(_layersCache.keys.first);
    }
    return result;
  }

  Future<GisMapData> fetchLayers({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) =>
      fetchNearby(latitude: latitude, longitude: longitude, forceRefresh: forceRefresh);

  Future<List<CommunityReportPoint>> fetchValidatedReports({bool forceRefresh = false}) async {
    if (!forceRefresh && _reportsCache != null && !_reportsCache!.isExpired(const Duration(minutes: 5))) {
      return _reportsCache!.data;
    }

    final response = await _client.get(
      Uri.parse('${_apiUrl.replaceFirst(RegExp(r'/$'), '')}/api/community/heatmap'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GisApiException('No se pudieron cargar los reportes comunitarios.', statusCode: response.statusCode);
    }
    final body = jsonDecode(response.body);
    final result = body is List
        ? body.whereType<Map<String, dynamic>>().map(CommunityReportPoint.fromJson).toList()
        : const <CommunityReportPoint>[];
    _reportsCache = _CacheEntry(result, DateTime.now());
    return result;
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
    // Invalidar caché de reportes para ver el nuevo reporte
    _reportsCache = null;
  }

  void dispose() => _client.close();
}
