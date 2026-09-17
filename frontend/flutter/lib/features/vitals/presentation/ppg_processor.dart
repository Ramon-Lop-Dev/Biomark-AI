import 'dart:math';
import 'package:camera/camera.dart';

class PpgFrameResult {
  final bool fingerDetected;
  final double rawValue;
  final double smoothedValue;
  final bool isBeat;
  final int? currentBpm;
  final double quality;
  final int totalBeats;

  const PpgFrameResult({
    required this.fingerDetected,
    required this.rawValue,
    required this.smoothedValue,
    required this.isBeat,
    this.currentBpm,
    required this.quality,
    this.totalBeats = 0,
  });
}

class PpgProcessor {
  final List<double> _smoothedBuffer = [];
  final List<int> _recentBpmHistory = [];
  final List<int> _allSessionBpms = [];

  double _previousSmoothed = 0.0;
  double _previousSlope = 0.0;
  int _lastBeatTime = 0;
  double _runningDc = 120.0;
  double _runningAmplitude = 0.5;
  int _beatCount = 0;

  List<double> get waveData => List.unmodifiable(_smoothedBuffer);
  int get beatCount => _beatCount;

  /// Retorna el pulso más representativo de la sesión mediante la mediana
  int? get bestBpm {
    final list = _allSessionBpms.isNotEmpty ? _allSessionBpms : _recentBpmHistory;
    if (list.isEmpty) return null;
    final sorted = List<int>.from(list)..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Retorna el pulso instantáneo reciente
  int? get currentBpm {
    if (_recentBpmHistory.isEmpty) return null;
    final sorted = List<int>.from(_recentBpmHistory)..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Puntuación de calidad de la señal (0.0 a 1.0)
  double get qualityScore {
    if (_allSessionBpms.length >= 8) return 0.95;
    if (_allSessionBpms.length >= 4) return 0.85;
    if (_allSessionBpms.length >= 2) return 0.70;
    return 0.50;
  }

  void reset() {
    _smoothedBuffer.clear();
    _recentBpmHistory.clear();
    _allSessionBpms.clear();
    _previousSmoothed = 0.0;
    _previousSlope = 0.0;
    _lastBeatTime = 0;
    _runningDc = 120.0;
    _runningAmplitude = 0.5;
    _beatCount = 0;
  }

  PpgFrameResult processCameraImage(CameraImage image) {
    final now = DateTime.now().millisecondsSinceEpoch;
    double intensitySum = 0.0;
    int sampleCount = 0;
    bool isRedPredominant = false;

    // Procesar según formato de cámara (Android YUV420 o iOS BGRA)
    if (image.format.group == ImageFormatGroup.yuv420 && image.planes.length >= 3) {
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final step = max(1, (yPlane.length / 400).floor());
      double vSum = 0.0;
      double uSum = 0.0;

      for (int i = 0; i < yPlane.length; i += step) {
        final y = yPlane[i];
        final uvIndex = (i ~/ 4).clamp(0, vPlane.length - 1);
        final v = vPlane[uvIndex];
        final u = uPlane[(uvIndex).clamp(0, uPlane.length - 1)];

        // Reconstrucción del canal rojo: R = Y + 1.402 * (V - 128)
        final r = (y + 1.402 * (v - 128)).clamp(0.0, 255.0);
        intensitySum += r;
        vSum += v;
        uSum += u;
        sampleCount++;
      }

      if (sampleCount > 0) {
        final avgV = vSum / sampleCount;
        final avgU = uSum / sampleCount;
        // En tejido humano con flash, V (componente roja) es significativamente mayor que U (azul)
        isRedPredominant = avgV > 132.0 || (avgV > avgU);
      }
    } else if (image.planes.isNotEmpty) {
      final plane = image.planes[0].bytes;
      // Para BGRA en iOS o RGBA genérico: salto de 4 bytes por pixel
      final step = max(4, ((plane.length / 400).floor() ~/ 4) * 4);
      for (int i = 0; i + 2 < plane.length; i += step) {
        // Asumir formato con canal rojo predominante (índice 2 en BGRA o 0 en RGBA)
        final r = plane[i + (image.format.group == ImageFormatGroup.bgra8888 ? 2 : 0)];
        intensitySum += r;
        sampleCount++;
      }
      isRedPredominant = true;
    }

    if (sampleCount == 0) {
      return PpgFrameResult(
        fingerDetected: false,
        rawValue: 0.0,
        smoothedValue: 0.0,
        isBeat: false,
        quality: 0.0,
        totalBeats: _beatCount,
      );
    }

    final avgIntensity = intensitySum / sampleCount;

    // Validación de contacto dérmico:
    // El dedo cubriendo el lente y flash produce alta intensidad lumínica y predominancia del rojo
    final bool fingerDetected = avgIntensity > 75.0 && isRedPredominant;

    if (!fingerDetected) {
      return PpgFrameResult(
        fingerDetected: false,
        rawValue: avgIntensity,
        smoothedValue: 0.0,
        isBeat: false,
        quality: 0.0,
        totalBeats: _beatCount,
      );
    }

    // 1. Filtro Paso-Alto dinámico / Eliminación de componente continua (DC)
    // tau ~ 2.0 segundos a 30 FPS para no atenuar la onda de pulso (0.8 Hz a 2.5 Hz)
    _runningDc = (_runningDc * 0.984) + (avgIntensity * 0.016);
    final acSignal = avgIntensity - _runningDc;

    // 2. Filtro Paso-Bajo IIR para atenuar ruido y jitter de sensor
    final smoothed = (_previousSmoothed * 0.65) + (acSignal * 0.35);
    final slope = smoothed - _previousSmoothed;

    // 3. Seguimiento de envolvente de amplitud para umbral adaptativo
    _runningAmplitude = (_runningAmplitude * 0.95) + (smoothed.abs() * 0.05);
    final dynamicThreshold = max(0.04, _runningAmplitude * 0.40);

    _smoothedBuffer.add(smoothed);
    if (_smoothedBuffer.length > 80) {
      _smoothedBuffer.removeAt(0);
    }

    bool isBeat = false;
    // 4. Detección de pico sistólico: inversión de pendiente con valor sobre umbral adaptativo
    if (_previousSlope > 0 && slope <= 0 && smoothed > dynamicThreshold) {
      final elapsed = now - _lastBeatTime;
      // Período refractario fisiológico humano: 330 ms (181 BPM) a 1500 ms (40 BPM)
      if (elapsed >= 330 && elapsed <= 1500) {
        isBeat = true;
        _lastBeatTime = now;
        _beatCount++;

        final instantBpm = (60000.0 / elapsed).round();
        if (instantBpm >= 42 && instantBpm <= 185) {
          _recentBpmHistory.add(instantBpm);
          if (_recentBpmHistory.length > 6) {
            _recentBpmHistory.removeAt(0);
          }
          _allSessionBpms.add(instantBpm);
        }
      } else if (elapsed > 1500) {
        _lastBeatTime = now;
      }
    }

    _previousSmoothed = smoothed;
    _previousSlope = slope;

    final bpm = currentBpm;
    final quality = (_recentBpmHistory.length / 5.0).clamp(0.0, 1.0);

    return PpgFrameResult(
      fingerDetected: true,
      rawValue: avgIntensity,
      smoothedValue: smoothed,
      isBeat: isBeat,
      currentBpm: bpm,
      quality: quality,
      totalBeats: _beatCount,
    );
  }
}
