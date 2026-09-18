import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/features/vitals/domain/vital_measurement.dart';
import 'package:flutter_biomark/features/vitals/presentation/ppg_processor.dart';
import 'package:flutter_biomark/features/home/domain/health_recommendation.dart';
import 'package:flutter_biomark/features/home/data/recommendations_service.dart';

void main() {
  group('VitalMeasurement Domain Tests', () {
    test('Correctly classifies normal pulse (60-100 BPM)', () {
      final vital = VitalMeasurement.fromBpm(bpm: 75);
      expect(vital.bpm, 75);
      expect(vital.status, 'NORMAL');
      expect(vital.statusLabel, contains('Ritmo normal'));
    });

    test('Correctly classifies bradycardia (<60 BPM)', () {
      final vital = VitalMeasurement.fromBpm(bpm: 52);
      expect(vital.bpm, 52);
      expect(vital.status, 'BRADICARDIA');
      expect(vital.statusLabel, contains('Pulso bajo'));
    });

    test('Correctly classifies tachycardia (>100 BPM)', () {
      final vital = VitalMeasurement.fromBpm(bpm: 118);
      expect(vital.bpm, 118);
      expect(vital.status, 'TAQUICARDIA');
      expect(vital.statusLabel, contains('Pulso elevado'));
    });

    test('Serializes to and from JSON', () {
      final original = VitalMeasurement.fromBpm(
        bpm: 80,
        qualityScore: 0.95,
        notes: 'Test note',
      );
      final json = original.toJson();
      final restored = VitalMeasurement.fromJson(json);

      expect(restored.bpm, original.bpm);
      expect(restored.status, original.status);
      expect(restored.statusLabel, original.statusLabel);
      expect(restored.qualityScore, original.qualityScore);
      expect(restored.notes, original.notes);
    });
  });

  group('RecommendationsService Tests', () {
    test('Returns MINSA recommendations for dengue, heat, cardio, and treatments', () {
      final recommendations = RecommendationsService.getRecommendations();
      expect(recommendations.length, greaterThanOrEqualTo(4));

      final categories = recommendations.map((r) => r.category).toSet();
      expect(categories, contains(RecommendationCategory.dengue));
      expect(categories, contains(RecommendationCategory.heatWave));
      expect(categories, contains(RecommendationCategory.cardiovascular));
      expect(categories, contains(RecommendationCategory.treatment));

      for (final rec in recommendations) {
        expect(rec.title.isNotEmpty, isTrue);
        expect(rec.summary.isNotEmpty, isTrue);
        expect(rec.details.isNotEmpty, isTrue);
        expect(rec.tag.isNotEmpty, isTrue);
        expect(rec.keyPoints.isNotEmpty, isTrue);
      }
    });

    test('Dengue recommendation includes MINSA Normativa 004', () {
      final recommendations = RecommendationsService.getRecommendations();
      final dengue = recommendations.firstWhere((r) => r.category == RecommendationCategory.dengue);
      expect(dengue.minsaNormative, contains('Normativa 004'));
      expect(dengue.keyPoints.any((p) => p.contains('criaderos') || p.contains('pilas')), isTrue);
    });

    test('Prioritization: Prioritizes cardiovascular when user has chronic hypertension', () {
      final prioritized = RecommendationsService.getPrioritized(
        surveyAnswers: {
          'enfermedadesCronicas': ['Hipertensión Arterial'],
          'medicamentosActuales': 'Enalapril 20mg',
        },
      );

      expect(prioritized.first.category, RecommendationCategory.cardiovascular);
      expect(prioritized.first.dynamicBadge, contains('Prioritario para tu salud'));
    });

    test('Prioritization: Elevates dengue when active epidemiological alert is present', () {
      final prioritized = RecommendationsService.getPrioritized(
        activeAlerts: ['Brote de Dengue Grave'],
        surveyAnswers: {},
      );

      expect(prioritized.first.category, RecommendationCategory.dengue);
      expect(prioritized.first.dynamicBadge, contains('Alerta comunitaria'));
    });

    test('Prioritization: Flags cardiovascular when recent pulse is abnormal (>100 BPM)', () {
      final prioritized = RecommendationsService.getPrioritized(
        latestHeartRate: 115,
        surveyAnswers: {},
      );

      final cardio = prioritized.firstWhere((r) => r.category == RecommendationCategory.cardiovascular);
      expect(cardio.relevanceScore, greaterThan(1));
      expect(cardio.dynamicBadge, contains('Atención a tu pulso reciente'));
    });
  });

  group('PpgProcessor State and Signal Tests', () {
    test('Initializes with empty wave buffer and reset clears buffers', () {
      final processor = PpgProcessor();
      expect(processor.waveData.isEmpty, isTrue);
      expect(processor.beatCount, 0);
      expect(processor.bestBpm, isNull);
      expect(processor.currentBpm, isNull);
      expect(processor.qualityScore, 0.50);

      processor.reset();
      expect(processor.waveData.isEmpty, isTrue);
      expect(processor.beatCount, 0);
      expect(processor.bestBpm, isNull);
    });
  });
}
