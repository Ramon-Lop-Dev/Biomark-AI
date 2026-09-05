class HealthCenter {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final double distanceKm;

  const HealthCenter({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.distanceKm,
  });

  factory HealthCenter.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return HealthCenter(
      id: '${json['id'] ?? ''}',
      name: '${json['nombre'] ?? 'Centro de salud'}',
      type: '${json['tipo'] ?? 'CENTRO_SALUD'}',
      latitude: number(json['latitud']),
      longitude: number(json['longitud']),
      address: '${json['direccion'] ?? 'Dirección no disponible'}',
      phone: '${json['telefono'] ?? ''}',
      distanceKm: number(json['distancia_km']),
    );
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

  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return CommunityEvent(
      id: '${json['id'] ?? ''}',
      title: '${json['titulo'] ?? 'Jornada comunitaria'}',
      description: '${json['descripcion'] ?? ''}',
      date: DateTime.tryParse('${json['fecha_evento'] ?? ''}') ?? DateTime.now(),
      location: '${json['ubicacion'] ?? 'Ubicación no disponible'}',
      latitude: number(json['latitud']),
      longitude: number(json['longitud']),
      distanceKm: number(json['distancia_km']),
    );
  }
}

class CommunityReportPoint {
  final double latitude;
  final double longitude;
  final int caseCount;

  const CommunityReportPoint({
    required this.latitude,
    required this.longitude,
    required this.caseCount,
  });

  factory CommunityReportPoint.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return CommunityReportPoint(
      latitude: number(json['latitud']),
      longitude: number(json['longitud']),
      caseCount: (json['cantidad_casos'] as num?)?.toInt() ?? 1,
    );
  }
}
