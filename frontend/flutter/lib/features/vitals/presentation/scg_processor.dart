import 'dart:math';

/// Postura de medición para calibrar el umbral y guiar al usuario
enum ScgPosture {
  supine, // Acostado boca arriba
  seated, // Sentado con apoyo
}

/// Estado de cada muestra procesada
class ScgPoint {
  final double rawMagnitude;
  final double filteredValue;
  final bool isPeak;
  final DateTime timestamp;

  const ScgPoint({
    required this.rawMagnitude,
    required this.filteredValue,
    required this.isPeak,
    required this.timestamp,
  });
}

/// Procesador de señal digital para Sismocardiografía (SCG) mediante acelerómetro MEMS.
/// Diseñado para operar con el stream de 50-100 Hz de `sensors_plus`.
class ScgProcessor {
  final ScgPosture posture;

  ScgProcessor({this.posture = ScgPosture.supine});

  // Constantes de filtrado digital IIR
  // Frecuencia respiratoria: 0.15 - 0.4 Hz -> HPF a 1.0 Hz para eliminarla
  static const double _fHp = 1.0;
  // Temblor muscular / ruido electrónico: > 20 Hz -> LPF a 20.0 Hz
  static const double _fLp = 20.0;

  // Estado del filtro
  double _gravityBaseline = 9.80665;
  double _prevNetAcc = 0.0;
  double _prevHpOut = 0.0;
  double _filteredSignal = 0.0;
  DateTime? _prevTimestamp;

  // Historial de muestras para detección de picos
  double _sampleMinus2 = 0.0;
  double _sampleMinus1 = 0.0;
  DateTime? _timeMinus1;

  // Detección de picos AO (Apertura Aórtica)
  DateTime? _lastPeakTime;
  double _runningPeakAvg = 0.08;
  final List<int> _rrIntervalsMs = [];

  // Calidad y movimiento
  int _disturbedFrames = 0;
  int _totalFrames = 0;
  bool _isCurrentlyDisturbed = false;

  // Buffer de visualización para osciloscopio (últimos 150 puntos)
  final List<double> _waveformBuffer = [];
  static const int maxBufferSize = 150;

  // Getters
  List<double> get waveform => List.unmodifiable(_waveformBuffer);
  bool get isCurrentlyDisturbed => _isCurrentlyDisturbed;
  int get peakCount => _rrIntervalsMs.length;

  /// Procesa una muestra instantánea de aceleración (x, y, z en m/s²)
  ScgPoint processSample({
    required double x,
    required double y,
    required double z,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    _totalFrames++;

    // 1. Magnitud Euclidiana 3D: invariante a la orientación e inclinación del teléfono
    final rawMag = sqrt(x * x + y * y + z * z);

    // 2. Intervalo de tiempo delta t
    double dt = 0.02; // Default 50 Hz (20 ms)
    if (_prevTimestamp != null) {
      final diffMs = now.difference(_prevTimestamp!).inMicroseconds / 1000000.0;
      if (diffMs > 0.002 && diffMs < 0.2) {
        dt = diffMs;
      }
    }
    _prevTimestamp = now;

    // 3. Estimador dinámico de gravedad (Filtro pasa-bajas muy lento para DC)
    // alpha = dt / (tau + dt), con tau ~ 2.0 s
    final alphaGravity = dt / (2.0 + dt);
    _gravityBaseline += alphaGravity * (rawMag - _gravityBaseline);
    final netAcc = rawMag - _gravityBaseline;

    // 4. Detección de artefactos de movimiento brusco (tos, hablar, acomodarse)
    // Estando acostado el umbral de movimiento es menor; sentado se tolera leve apoyo
    final motionThreshold = (posture == ScgPosture.supine) ? 1.2 : 1.8;
    if (netAcc.abs() > motionThreshold) {
      _isCurrentlyDisturbed = true;
      _disturbedFrames++;
    } else {
      _isCurrentlyDisturbed = false;
    }

    // 5. Filtro Pasa-Altas (HPF) a 1.0 Hz para eliminar respiración torácica
    final rcHp = 1.0 / (2.0 * pi * _fHp);
    final alphaHp = rcHp / (rcHp + dt);
    final hpOut = alphaHp * (_prevHpOut + netAcc - _prevNetAcc);
    _prevNetAcc = netAcc;
    _prevHpOut = hpOut;

    // 6. Filtro Pasa-Bajas (LPF) a 20.0 Hz para eliminar temblores de mano y ruido MEMS
    final rcLp = 1.0 / (2.0 * pi * _fLp);
    final alphaLp = dt / (rcLp + dt);
    _filteredSignal = _filteredSignal + alphaLp * (hpOut - _filteredSignal);

    // 7. Actualización del buffer de onda (normalizado entre -1.0 y 1.0 aprox para gráfico)
    final clampedWave = (_filteredSignal * 5.0).clamp(-1.0, 1.0);
    _waveformBuffer.add(clampedWave);
    if (_waveformBuffer.length > maxBufferSize) {
      _waveformBuffer.removeAt(0);
    }

    // 8. Detección de picos AO (Apertura Aórtica)
    // Se busca un máximo local: sampleMinus1 > sampleMinus2 y sampleMinus1 > _filteredSignal
    bool isPeak = false;
    if (_sampleMinus1 > _sampleMinus2 &&
        _sampleMinus1 > _filteredSignal &&
        _timeMinus1 != null) {
      // Umbral adaptativo: al menos 40% del promedio de picos recientes, mínimo 0.03 m/s²
      final dynamicThreshold = max(_runningPeakAvg * 0.45, 0.03);

      if (_sampleMinus1 > dynamicThreshold && !_isCurrentlyDisturbed) {
        if (_lastPeakTime == null) {
          _lastPeakTime = _timeMinus1;
          _runningPeakAvg = _sampleMinus1;
          isPeak = true;
        } else {
          final intervalMs = _timeMinus1!.difference(_lastPeakTime!).inMilliseconds;
          // Período refractario fisiológico: 330 ms (181 BPM) a 1500 ms (40 BPM)
          // Esto evita contar dos veces la onda de cierre aórtico (AC)
          if (intervalMs >= 330 && intervalMs <= 1500) {
            _rrIntervalsMs.add(intervalMs);
            if (_rrIntervalsMs.length > 15) {
              _rrIntervalsMs.removeAt(0);
            }
            _lastPeakTime = _timeMinus1;
            // Actualizar promedio móvil del pico
            _runningPeakAvg = 0.8 * _runningPeakAvg + 0.2 * _sampleMinus1;
            isPeak = true;
          } else if (intervalMs > 1500) {
            // Se perdió el ritmo (demasiado tiempo sin pico), reiniciar referencia
            _lastPeakTime = _timeMinus1;
          }
        }
      }
    }

    // Rotar muestras para el siguiente ciclo
    _sampleMinus2 = _sampleMinus1;
    _sampleMinus1 = _filteredSignal;
    _timeMinus1 = now;

    return ScgPoint(
      rawMagnitude: rawMag,
      filteredValue: _filteredSignal,
      isPeak: isPeak,
      timestamp: now,
    );
  }

  /// Calcula la frecuencia cardíaca actual en Latidos por Minuto (BPM)
  /// mediante la mediana de los intervalos RR para máxima robustez ante outliers.
  int? calculateBpm() {
    if (_rrIntervalsMs.length < 3) return null;

    final sorted = List<int>.from(_rrIntervalsMs)..sort();
    final medianRr = sorted[sorted.length ~/ 2];

    if (medianRr <= 0) return null;
    final bpm = (60000 / medianRr).round();

    // Rango fisiológico seguro de reposo
    if (bpm < 40 || bpm > 190) return null;
    return bpm;
  }

  /// Calcula la calidad de la señal (0.0 a 1.0)
  /// Penaliza movimiento brusco y dispersión anormal de intervalos RR
  double calculateQualityScore() {
    if (_totalFrames == 0) return 0.0;

    // Proporción de tramos limpios sin sacudidas
    final disturbanceRatio = _disturbedFrames / _totalFrames;
    double quality = (1.0 - disturbanceRatio * 2.0).clamp(0.1, 1.0);

    // Si tenemos suficientes latidos, evaluamos la regularidad del ritmo
    if (_rrIntervalsMs.length >= 4) {
      final mean = _rrIntervalsMs.reduce((a, b) => a + b) / _rrIntervalsMs.length;
      double variance = 0.0;
      for (final rr in _rrIntervalsMs) {
        variance += (rr - mean) * (rr - mean);
      }
      final stdDev = sqrt(variance / _rrIntervalsMs.length);
      // Un ritmo en reposo tiene stdDev entre 20ms y 120ms. Si supera 250ms es señal ruidosa
      final rhythmCoherence = (1.0 - (stdDev / 250.0)).clamp(0.2, 1.0);
      quality = (quality * 0.5 + rhythmCoherence * 0.5);
    }

    return double.parse(quality.toStringAsFixed(2));
  }

  /// Limpia buffers y reinicia el procesador
  void reset() {
    _gravityBaseline = 9.80665;
    _prevNetAcc = 0.0;
    _prevHpOut = 0.0;
    _filteredSignal = 0.0;
    _prevTimestamp = null;
    _sampleMinus2 = 0.0;
    _sampleMinus1 = 0.0;
    _timeMinus1 = null;
    _lastPeakTime = null;
    _runningPeakAvg = 0.08;
    _rrIntervalsMs.clear();
    _disturbedFrames = 0;
    _totalFrames = 0;
    _isCurrentlyDisturbed = false;
    _waveformBuffer.clear();
  }
}
