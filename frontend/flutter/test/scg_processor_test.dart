import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/features/vitals/presentation/scg_processor.dart';

void main() {
  group('ScgProcessor Tests', () {
    late ScgProcessor processor;

    setUp(() {
      processor = ScgProcessor(posture: ScgPosture.supine);
    });

    test('Initial state is clean', () {
      expect(processor.peakCount, equals(0));
      expect(processor.calculateBpm(), isNull);
      expect(processor.isCurrentlyDisturbed, isFalse);
      expect(processor.waveform, isEmpty);
    });

    test('Simulates 75 BPM cardiac signal with accurate BPM estimation', () {
      // 75 BPM -> Intervalo RR de 800 ms (0.8 s)
      // Frecuencia de muestreo 50 Hz (20 ms por muestra) -> 40 muestras por latido
      final startTime = DateTime(2026, 9, 17, 10, 0, 0);
      const samplingDtMs = 20; // 50 Hz
      const totalDurationSec = 16; // 16 segundos de medición
      const totalSamples = (totalDurationSec * 1000) ~/ samplingDtMs;

      int detectedPeaks = 0;

      for (int i = 0; i < totalSamples; i++) {
        final tMs = i * samplingDtMs;
        final timestamp = startTime.add(Duration(milliseconds: tMs));

        // Gravedad estática en Z = 9.81
        double z = 9.80665;
        double x = 0.0;
        double y = 0.0;

        // Modulación respiratoria lenta (0.2 Hz)
        final resp = 0.05 * sin(2 * pi * 0.2 * (tMs / 1000.0));
        z += resp;

        // Pulso cardíaco cada 800 ms (75 BPM)
        // El complejo AO es un pico positivo agudo de aceleración de ~0.25 m/s² que dura ~80 ms
        final phaseMs = tMs % 800;
        if (phaseMs < 80) {
          final cardiacPulse = 0.25 * sin(pi * phaseMs / 80.0);
          z += cardiacPulse;
        }

        final point = processor.processSample(
          x: x,
          y: y,
          z: z,
          timestamp: timestamp,
        );

        if (point.isPeak) {
          detectedPeaks++;
        }
      }

      final bpm = processor.calculateBpm();
      final quality = processor.calculateQualityScore();

      expect(detectedPeaks, greaterThanOrEqualTo(10));
      expect(bpm, isNotNull);
      // Debe estar muy cerca de 75 BPM (+-3 BPM de tolerancia)
      expect(bpm, inInclusiveRange(72, 78));
      expect(quality, greaterThanOrEqualTo(0.7));
    });

    test('Works accurately in seated posture with tilted gravity vector', () {
      // Sentado a 45 grados: gravedad dividida entre Y y Z
      // g_y = 9.81 * sin(45°) ~ 6.93 m/s²
      // g_z = 9.81 * cos(45°) ~ 6.93 m/s²
      final seatedProcessor = ScgProcessor(posture: ScgPosture.seated);
      final startTime = DateTime(2026, 9, 17, 10, 0, 0);
      const samplingDtMs = 20;
      const totalSamples = (16 * 1000) ~/ samplingDtMs;

      for (int i = 0; i < totalSamples; i++) {
        final tMs = i * samplingDtMs;
        final timestamp = startTime.add(Duration(milliseconds: tMs));

        double y = 6.934;
        double z = 6.934;
        double x = 0.0;

        // Pulso a 60 BPM (cada 1000 ms)
        final phaseMs = tMs % 1000;
        if (phaseMs < 80) {
          final pulse = 0.22 * sin(pi * phaseMs / 80.0);
          // El latido empuja en dirección normal al tórax (eje Z e Y)
          z += pulse * 0.707;
          y += pulse * 0.707;
        }

        seatedProcessor.processSample(
          x: x,
          y: y,
          z: z,
          timestamp: timestamp,
        );
      }

      final bpm = seatedProcessor.calculateBpm();
      expect(bpm, isNotNull);
      // Debe estar alrededor de 60 BPM (+-3 BPM)
      expect(bpm, inInclusiveRange(58, 63));
    });

    test('Flags motion artifacts when sudden disturbance occurs', () {
      final startTime = DateTime(2026, 9, 17, 10, 0, 0);

      // Muestra en reposo
      processor.processSample(
        x: 0.0,
        y: 0.0,
        z: 9.81,
        timestamp: startTime,
      );
      expect(processor.isCurrentlyDisturbed, isFalse);

      // Sacudida repentina (tos / movimiento brusco)
      processor.processSample(
        x: 1.5,
        y: 2.0,
        z: 14.0, // Aceleración neta > 4 m/s²
        timestamp: startTime.add(const Duration(milliseconds: 20)),
      );
      expect(processor.isCurrentlyDisturbed, isTrue);
    });

    test('Reset clears all buffers and peak history', () {
      processor.processSample(x: 0, y: 0, z: 9.81);
      processor.reset();

      expect(processor.peakCount, equals(0));
      expect(processor.calculateBpm(), isNull);
      expect(processor.waveform, isEmpty);
    });
  });
}
