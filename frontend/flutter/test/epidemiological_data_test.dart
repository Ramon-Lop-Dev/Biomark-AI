import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/features/gis/domain/health_center.dart';
import 'package:flutter_biomark/features/gis/domain/disease_epidemiology_info.dart';

void main() {
  group('CommunityReportPoint Domain & Barrio Resolution Tests', () {
    test('Resolves explicit barrio correctly without generic fallbacks', () {
      final json = {
        'id': 'rpt-001',
        'latitud': 12.1485,
        'longitud': -86.2912,
        'cantidad_casos': 41,
        'descripcion': 'Brote activo con síntomas febriles y mialgias.',
        'tipo_enfermedad': 'Leptospirosis',
        'direccion_exacta': 'Barrio Morazán, Managua',
        'clasificacion_ccm': 'AMARILLO',
        'fecha_creacion': '2026-09-24T10:00:00Z',
      };

      final point = CommunityReportPoint.fromJson(json);

      expect(point.displayIllness, 'Leptospirosis');
      expect(point.displayAddress, 'Barrio Morazán, Managua');
      expect(point.caseCount, 41);
      expect(point.clasificacionCcm, 'AMARILLO');
      expect(point.displayAddress.contains('Sector Georreferenciado'), isFalse);
    });

    test('Infers real Managua neighborhood from coordinates when address is missing or generic', () {
      // Coordenadas en Barrio Monseñor Lezcano
      final jsonLezcano = {
        'id': 'rpt-002',
        'latitud': 12.1520,
        'longitud': -86.2865,
        'cantidad_casos': 19,
        'descripcion': 'Casos sospechosos reportados por brigada de salud.',
        'tipo_enfermedad': null,
        'direccion_exacta': 'Managua',
        'clasificacion_ccm': 'VERDE',
      };

      final pointLezcano = CommunityReportPoint.fromJson(jsonLezcano);
      expect(pointLezcano.displayAddress, contains('Barrio Monseñor Lezcano'));
      expect(pointLezcano.displayAddress.contains('Sector Georreferenciado'), isFalse);

      // Coordenadas en Barrio San Judas
      final jsonSanJudas = {
        'id': 'rpt-003',
        'latitud': 12.1080,
        'longitud': -86.2880,
        'cantidad_casos': 5,
        'descripcion': 'Reporte comunitario tras jornada de abatización.',
        'direccion_exacta': null,
      };

      final pointSanJudas = CommunityReportPoint.fromJson(jsonSanJudas);
      expect(pointSanJudas.displayAddress, contains('Barrio San Judas'));
      expect(pointSanJudas.displayAddress.contains('Sector Georreferenciado'), isFalse);
    });

    test('Infers disease pathology accurately from description text', () {
      final json = {
        'id': 'rpt-004',
        'latitud': 12.132,
        'longitud': -86.289,
        'cantidad_casos': 9,
        'descripcion': 'Pacientes con sospecha de chikungunya y artralgias severas.',
        'tipo_enfermedad': null,
      };

      final point = CommunityReportPoint.fromJson(json);
      expect(point.displayIllness, 'Chikungunya');
    });
  });

  group('DiseaseEpidemiologyInfo MINSA Contextual Tests', () {
    test('Resolves Leptospirosis with official transmission and prevention measures', () {
      final info = DiseaseEpidemiologyInfo.forDisease('Leptospirosis');

      expect(info.diseaseName, 'Leptospirosis');
      expect(info.officialClassification, contains('SILAIS / MINSA'));
      expect(info.transmissionMechanism, contains('orina de roedores'));
      expect(info.commonSymptoms, isNotEmpty);
      expect(info.commonSymptoms.any((s) => s.toLowerCase().contains('pantorrillas')), isTrue);
      expect(info.minsaPreventionMeasures.any((m) => m.toLowerCase().contains('charcas')), isTrue);
    });

    test('Resolves Dengue with Aedes aegypti vector and warning signs', () {
      final info = DiseaseEpidemiologyInfo.forDisease('Dengue');

      expect(info.diseaseName, 'Dengue');
      expect(info.transmissionMechanism, contains('Aedes aegypti'));
      expect(info.minsaPreventionMeasures.any((m) => m.toLowerCase().contains('abate') || m.toLowerCase().contains('bti')), isTrue);
      expect(info.minsaPreventionMeasures.any((m) => m.toLowerCase().contains('aspirina')), isTrue);
      expect(info.warningSigns, contains('Dolor abdominal'));
    });

    test('Resolves Chikungunya with articular symptoms', () {
      final info = DiseaseEpidemiologyInfo.forDisease('Chikungunya');

      expect(info.diseaseName, 'Chikungunya');
      expect(info.commonSymptoms.any((s) => s.toLowerCase().contains('articular')), isTrue);
    });
  });
}
