import 'dart:math';
import 'package:camera/camera.dart';

class PpgFrameResult {
  final bool fingerDetected;
  final double rawValue;
  final double smoothedValue;
  final bool isBeat;
  final int? currentBpm;
  final double quality;

  const PpgFrameResult({
    required this.fingerDetected,
    required this.rawValue,
    required this.smoothedValue,
    required this.isBeat,
    this.currentBpm,
    required this.quality,
  });
}

class PpgProcessor {
  final List<double> _rawBuffer = [];
  final List<double> _smoothedBuffer = [];
  final List<int> _peakTimes = [];
  final List<int> _bpmHistory = [];

  double _previousSmoothed = 0.0;
  double _previousSlope = 0.0;
  int _lastBeatTime = 0;
  double _runningDc = 128.0;

  List<double> get waveData => List.unmodifiable(_smoothedBuffer);

  void reset() {
    _rawBuffer.clear();
    _smoothedBuffer.clear();
    _peakTimes.clear();
    _bpmHistory.clear();
    _previousSmoothed = 0.0;
    _previousSlope = 0.0;
    _lastBeatTime = 0;
    _runningDc = 128.0;
  }

  PpgFrameResult processCameraImage(CameraImage image) {
    final now = DateTime.now().millisecondsSinceEpoch;
    double redSum = 0.0;
    int sampleCount = 0;

    // Procesar según formato de cámara (Android YUV420 o iOS BGRA)
    if (image.format.group == ImageFormatGroup.yuv420 && image.planes.length >= 3) {
      final yPlane = image.planes[0].bytes;
      final vPlane = image.planes[2].bytes;
      final step = max(1, (yPlane.length / 500).floor());

      for (int i = 0; i < yPlane.length; i += step) {
        final y = yPlane[i];
        final vIndex = (i ~/ 4).clamp(0, vPlane.length - 1);
        final v = vPlane[vIndex];
        // Aproximación canal rojo: R = Y + 1.402 * (V - 128)
        final r = (y + 1.402 * (v - 128)).clamp(0.0, 255.0);
        redSum += r;
        sampleCount++;
      }
    } else if (image.planes.isNotEmpty) {
      final plane = image.planes[0].bytes;
      final step = max(1, (plane.length / 500).floor());
      for (int i = 0; i < plane.length; i += step) {
        redSum += plane[i];
        sampleCount++;
      }
    }

    if (sampleCount == 0) {
      return const PpgFrameResult(
        fingerDetected: false,
        rawValue: 0.0,
        smoothedValue: 0.0,
        isBeat: false,
        quality: 0.0,
      );
    }

    final avgRed = redSum / sampleCount;

    // Validación de contacto: el dedo sobre el flash produce un canal rojo dominante (> 100)
    final bool fingerDetected = avgRed > 95.0;

    if (!fingerDetected) {
      _rawBuffer.clear();
      _smoothedBuffer.clear();
      return PpgFrameResult(
        fingerDetected: false,
        rawValue: avgRed,
        smoothedValue: 0.0,
        isBeat: false,
        quality: 0.0,
      );
    }

    // Filtro paso alto / eliminación de componente continua (DC)
    _runningDc = (_runningDc * 0.95) + (avgRed * 0.05);
    final acSignal = avgRed - _runningDc;

    // Filtro paso bajo (IIR) para suavizar ruido de sensor
    final smoothed = (_previousSmoothed * 0.70) + (acSignal * 0.30);
    final slope = smoothed - _previousSmoothed;

    _smoothedBuffer.add(smoothed);
    if (_smoothedBuffer.length > 70) {
      _smoothedBuffer.removeAt(0);
    }

    bool isBeat = false;
    // Detección de pico cuando la pendiente cambia de positiva a negativa
    if (_previousSlope > 0 && slope <= 0 && smoothed > 0.4) {
      final elapsed = now - _lastBeatTime;
      // Período refractario fisiológico (330 ms = 180 BPM máx, 1500 ms = 40 BPM mín)
      if (elapsed >= 330 && elapsed <= 1500) {
        isBeat = true;
        _lastBeatTime = now;
        _peakTimes.add(now);

        final instantBpm = (60000.0 / elapsed).round();
        if (instantBpm >= 45 && instantBpm <= 185) {
          _bpmHistory.add(instantBpm);
          if (_bpmHistory.length > 8) {
            _bpmHistory.removeAt(0);
          }
        }
      } else if (elapsed > 1500) {
        _lastBeatTime = now;
      }
    }

    _previousSmoothed = smoothed;
    _previousSlope = slope;

    int? computedBpm;
    if (_bpmHistory.length >= 3) {
      final sorted = List<int>.from(_bpmHistory)..sort();
      computedBpm = sorted[sorted.length ~/ 2]; // Mediana
    }

    final quality = (_bpmHistory.length / 6.0).clamp(0.0, 1.0);

    return PpgFrameResult(
      fingerDetected: true,
      rawValue: avgRed,
      smoothedValue: smoothed,
      isBeat: isBeat,
      currentBpm: computedBpm,
      quality: quality,
    );
  }
}
