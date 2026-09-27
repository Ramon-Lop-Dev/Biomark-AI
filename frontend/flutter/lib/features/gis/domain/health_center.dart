class HealthCenter {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final double distanceKm;
  final int level;
  final bool approximateLocation;
  final List<String> specialties;

  const HealthCenter({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.distanceKm,
    this.level = 2,
    this.approximateLocation = true,
    this.specialties = const [],
  });

  factory HealthCenter.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return HealthCenter(
      id: '${json['id'] ?? ''}',
      name: '${json['nombre'] ?? 'Centro de salud'}',
      type: '${json['tipo'] ?? 'CENTRO_SALUD'}',
      latitude: number(json['latitud'] ?? json['lat']),
      longitude: number(json['longitud'] ?? json['lon']),
      address: '${json['direccion'] ?? 'Dirección no disponible'}',
      phone: '${json['telefono'] ?? ''}',
      distanceKm: number(json['distancia_km'] ?? (json['metros'] != null ? (number(json['metros']) / 1000) : 0)),
      level: (json['nivel'] ?? json['nivel_atencion'] ?? 2) is num
          ? ((json['nivel'] ?? json['nivel_atencion'] ?? 2) as num).toInt()
          : int.tryParse('${json['nivel'] ?? json['nivel_atencion'] ?? 2}') ??
                2,
      approximateLocation:
          json['ubicacion_aproximada'] == true ||
          '${json['fuente_coordenada'] ?? ''}' == 'aproximada',
      specialties: _specialties(json),
    );
  }

  static List<String> _specialties(Map<String, dynamic> json) {
    final legacy = json['especialidades'];
    final values = <String>[];
    if (legacy is List) values.addAll(legacy.whereType<String>());
    final relations = json['centro_servicios'];
    if (relations is List) {
      for (final relation in relations.whereType<Map<String, dynamic>>()) {
        final catalog = relation['catalogo_servicios'];
        if (catalog is Map<String, dynamic>) {
          final label = catalog['etiqueta'];
          if (label is String) values.add(label);
        }
      }
    }
    return values.toSet().toList();
  }
}

class RiskZone {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  const RiskZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  factory RiskZone.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return RiskZone(
      name: '${json['nombre'] ?? json['tipo'] ?? 'Zona de riesgo'}',
      latitude: number(json['latitud']),
      longitude: number(json['longitud']),
      radiusKm: number(json['radio_km']),
    );
  }
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String type;

  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.type = '',
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return CommunityEvent(
      id: '${json['id'] ?? ''}',
      title: '${json['titulo'] ?? 'Jornada comunitaria'}',
      description: '${json['descripcion'] ?? ''}',
      date:
          DateTime.tryParse('${json['fecha_evento'] ?? ''}') ?? DateTime.now(),
      location: '${json['ubicacion'] ?? 'Ubicación no disponible'}',
      latitude: number(json['latitud']),
      longitude: number(json['longitud']),
      distanceKm: number(json['distancia_km']),
      type: '${json['tipo'] ?? json['categoria'] ?? ''}',
    );
  }
}

class CommunityReportPoint {
  final String id;
  final double latitude;
  final double longitude;
  final int caseCount;
  final String description;
  final String? tipoEnfermedad;
  final String? direccionExacta;
  final String? clasificacionCcm;
  final DateTime? fechaCreacion;

  const CommunityReportPoint({
    this.id = '',
    required this.latitude,
    required this.longitude,
    required this.caseCount,
    this.description = '',
    this.tipoEnfermedad,
    this.direccionExacta,
    this.clasificacionCcm,
    this.fechaCreacion,
  });

  factory CommunityReportPoint.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    final lat = number(json['latitud']);
    final lon = number(json['longitud']);

    final rawDesc = '${json['descripcion'] ?? ''}'.trim();
    String? illness = json['tipo_enfermedad'] as String?;
    if (illness == null || illness.trim().isEmpty) {
      final lower = rawDesc.toLowerCase();
      if (lower.contains('lepto')) {
        illness = 'Leptospirosis';
      } else if (lower.contains('chikung') || lower.contains('chicung')) {
        illness = 'Chikungunya';
      } else if (lower.contains('dengue')) {
        illness = 'Dengue';
      } else if (lower.contains('zika')) {
        illness = 'Zika';
      } else if (lower.contains('malaria') || lower.contains('paludismo')) {
        illness = 'Malaria';
      } else if (lower.contains('vomito') || lower.contains('vómito') || lower.contains('diarrea') || lower.contains('gastro')) {
        illness = 'Gastroenteritis Aguda';
      } else {
        illness = 'Alerta Sanitaria Comunitaria';
      }
    }

    String? address = json['direccion_exacta'] as String?;
    if (address == null || address.trim().isEmpty || address.trim().toLowerCase() == 'managua') {
      final lower = rawDesc.toLowerCase();
      if (lower.contains('morazan') || lower.contains('morazán')) {
        address = 'Barrio Morazán, Distrito II, Managua';
      } else if (lower.contains('lezcano') || lower.contains('monseñor')) {
        address = 'Barrio Monseñor Lezcano, Distrito II, Managua';
      } else if (lower.contains('altagracia')) {
        address = 'Barrio Altagracia, Distrito III, Managua';
      } else if (lower.contains('san judas')) {
        address = 'Barrio San Judas, Distrito III, Managua';
      } else if (lower.contains('bello horizonte')) {
        address = 'Barrio Bello Horizonte, Distrito IV, Managua';
      } else if (lat != 0 && lon != 0) {
        // Encontrar el barrio o distrito de Managua geográficamente más cercano
        const landmarks = <String, (double, double)>{
          'Barrio Morazán, Distrito II, Managua': (12.1485, -86.2912),
          'Barrio Monseñor Lezcano, Distrito II, Managua': (12.1520, -86.2865),
          'Barrio Altagracia, Distrito III, Managua': (12.1320, -86.2890),
          'Barrio San Judas, Distrito III, Managua': (12.1080, -86.2880),
          'Distrito V, Managua': (12.1150, -86.2300),
          'Barrio Bello Horizonte, Distrito IV, Managua': (12.1450, -86.2350),
        };

        String closestBarrio = 'Distrito II, Managua';
        double minDistanceSq = double.infinity;
        for (final entry in landmarks.entries) {
          final dLat = lat - entry.value.$1;
          final dLon = lon - entry.value.$2;
          final distSq = (dLat * dLat) + (dLon * dLon);
          if (distSq < minDistanceSq) {
            minDistanceSq = distSq;
            closestBarrio = entry.key;
          }
        }
        address = closestBarrio;
      } else {
        address = 'Distrito Sanitario Managua';
      }
    }

    return CommunityReportPoint(
      id: '${json['id'] ?? ''}',
      latitude: lat,
      longitude: lon,
      caseCount: (json['cantidad_casos'] as num?)?.toInt() ?? 1,
      description: rawDesc,
      tipoEnfermedad: illness,
      direccionExacta: address,
      clasificacionCcm: json['clasificacion_ccm'] as String?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse('${json['fecha_creacion']}')
          : null,
    );
  }

  String get displayAddress =>
      (direccionExacta != null && direccionExacta!.trim().isNotEmpty)
          ? direccionExacta!.trim()
          : 'Distrito Sanitario Managua';

  String get displayIllness =>
      (tipoEnfermedad != null && tipoEnfermedad!.trim().isNotEmpty)
          ? tipoEnfermedad!.trim()
          : 'Alerta Epidemiológica';
}
