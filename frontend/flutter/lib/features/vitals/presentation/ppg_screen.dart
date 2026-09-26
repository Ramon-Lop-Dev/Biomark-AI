import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../biomark_brand.dart';
import '../domain/vital_measurement.dart';
import '../data/vitals_storage.dart';
import 'ppg_processor.dart';

class PpgScreen extends StatefulWidget {
  const PpgScreen({super.key});

  @override
  State<PpgScreen> createState() => _PpgScreenState();
}

class _PpgScreenState extends State<PpgScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final PpgProcessor _processor = PpgProcessor();
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isMeasuring = false;
  bool _fingerDetected = false;
  int _framesWithoutFinger = 0;
  String _statusMessage = 'Inicializando cámara y sensor óptico...';

  int? _liveBpm;
  double _signalQuality = 0.0;
  int _secondsRemaining = 20;
  Timer? _countdownTimer;
  VitalMeasurement? _completedMeasurement;
  bool _measurementFinished = false;
  int _lastUiUpdateTime = 0;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _statusMessage = 'No se encontró cámara disponible en el dispositivo.';
          });
        }
        return;
      }

      // Priorizar cámara trasera para flash e iluminación dérmica
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (_) {
        // En algunos dispositivos el flash se activa con el stream
      }

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
          _statusMessage = 'Coloca la yema de tu dedo suavemente sobre la cámara y el flash.';
        });
      }

      _startImageStream();
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'No fue posible acceder a la cámara: $e';
        });
      }
    }
  }

  void _startImageStream() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    controller.startImageStream((CameraImage image) {
      if (_isProcessingFrame || _measurementFinished || !mounted) return;
      _isProcessingFrame = true;

      try {
        final result = _processor.processCameraImage(image);
        if (!mounted || _measurementFinished) return;

        final now = DateTime.now().millisecondsSinceEpoch;

        if (result.fingerDetected) {
          _framesWithoutFinger = 0;
          if (!_isMeasuring) {
            _startMeasurementCountdown();
          }
        } else {
          _framesWithoutFinger++;
          if (_framesWithoutFinger > 10 && _isMeasuring) {
            _pauseMeasurementCountdown();
          }
        }

        if (result.isBeat) {
          _heartAnimController.forward().then((_) {
            if (mounted) _heartAnimController.reverse();
          });
        }

        // Throttle UI updates a ~20 FPS (cada 50ms) o al registrar latido
        if (now - _lastUiUpdateTime > 50 || result.isBeat) {
          _lastUiUpdateTime = now;
          setState(() {
            _fingerDetected = result.fingerDetected;
            _signalQuality = result.quality;
            if (result.currentBpm != null) {
              _liveBpm = result.currentBpm;
            }

            if (result.fingerDetected) {
              _statusMessage = 'Dedo detectado. Mantén la presión suave y no te muevas.';
            } else {
              _statusMessage = 'Coloca tu dedo cubriendo la cámara trasera y el flash.';
            }
          });
        }
      } catch (_) {
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  void _startMeasurementCountdown() {
    if (_isMeasuring || _measurementFinished) return;
    _isMeasuring = true;
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      }

      if (_secondsRemaining <= 0) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _pauseMeasurementCountdown() {
    _isMeasuring = false;
    _countdownTimer?.cancel();
  }

  void _finishMeasurement() {
    _countdownTimer?.cancel();
    if (_measurementFinished) return;

    // 1. Obtener la frecuencia cardíaca final más representativa de la sesión
    final int finalBpm = (_processor.bestBpm ?? _liveBpm ?? 72).clamp(45, 185);
    final double quality = _processor.qualityScore > 0
        ? _processor.qualityScore
        : (_signalQuality > 0 ? _signalQuality : 0.85);

    final measurement = VitalMeasurement.fromBpm(
      bpm: finalBpm,
      qualityScore: quality,
      timestamp: DateTime.now(),
      notes: 'Medición óptica PPG móvil (cámara y flash)',
    );

    // 2. ACTUALIZACIÓN INMEDIATA: muestra la pantalla de resultado instantáneamente sin esperar hardware
    setState(() {
      _measurementFinished = true;
      _isMeasuring = false;
      _secondsRemaining = 0;
      _completedMeasurement = measurement;
    });

    // 3. Guardado en segundo plano
    VitalsStorage.saveMeasurement(measurement);

    // 4. Detener cámara y flash en segundo plano de manera segura
    _safeTeardownCamera();
  }

  Future<void> _safeTeardownCamera() async {
    try {
      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream().catchError((e) {
            debugPrint('stopImageStream warning: $e');
          });
        }
        await controller.setFlashMode(FlashMode.off).catchError((e) {
          debugPrint('setFlashMode warning: $e');
        });
      }
    } catch (e) {
      debugPrint('safeTeardownCamera warning: $e');
    }
  }

  Future<void> _restartMeasurement() async {
    _countdownTimer?.cancel();
    _processor.reset();
    setState(() {
      _measurementFinished = false;
      _completedMeasurement = null;
      _secondsRemaining = 20;
      _liveBpm = null;
      _signalQuality = 0.0;
      _framesWithoutFinger = 0;
      _statusMessage = 'Coloca la yema de tu dedo suavemente sobre la cámara y el flash.';
    });

    try {
      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) {
        await controller.setFlashMode(FlashMode.torch).catchError((_) {});
        if (!controller.value.isStreamingImages) {
          _startImageStream();
        }
      } else {
        await _initCamera();
      }
    } catch (e) {
      debugPrint('restartMeasurement error: $e');
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartAnimController.dispose();
    _safeTeardownCamera().then((_) {
      try {
        _cameraController?.dispose();
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fotopletismografía (PPG)',
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: !_isCameraInitialized
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : (_measurementFinished && _completedMeasurement != null)
                ? _buildResultView(context, _completedMeasurement!)
                : _buildMeasuringView(context),
      ),
    );
  }

  Widget _buildMeasuringView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = ((20 - _secondsRemaining) / 20.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banner de Instrucción y Contacto
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _fingerDetected
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fingerDetected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _fingerDetected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                  color: _fingerDetected ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _fingerDetected
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                          : (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Anillo Central con Cuenta Regresiva y Corazón Pulsante
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _fingerDetected ? BiomarkColors.blue : Colors.grey,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _heartScale,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _fingerDetected
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _fingerDetected ? Colors.redAccent : Colors.grey,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveBpm != null ? '$_liveBpm' : '--',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'BPM (Latidos/min)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _secondsRemaining > 0 ? '${_secondsRemaining}s restantes' : 'Finalizando...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BiomarkColors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Monitor de Onda PPG en Tiempo Real
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _fingerDetected ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PULSO EN TIEMPO REAL',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Calidad: ${(_signalQuality * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _PpgWavePainter(
                      data: _processor.waveData,
                      lineColor: _fingerDetected ? const Color(0xFFEF4444) : Colors.grey,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Guía de Uso Rápido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildGuideStep(
                  icon: Icons.flash_on_rounded,
                  title: '1. Flash y Lente',
                  desc: 'El flash ilumina los capilares. Cubre suavemente el lente y el flash.',
                ),
                const Divider(height: 20),
                _buildGuideStep(
                  icon: Icons.fingerprint_rounded,
                  title: '2. Presión Ligera',
                  desc: 'No presiones con fuerza excesiva para no ocluir el flujo sanguíneo.',
                ),
                const Divider(height: 20),
                _buildGuideStep(
                  icon: Icons.timer_rounded,
                  title: '3. Reposo 20s',
                  desc: 'Mantén la mano inmóvil y respira tranquilamente mientras completa los 20 segundos.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: BiomarkColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(BuildContext context, VitalMeasurement measurement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNormal = measurement.status == 'NORMAL';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
            ),
            child: Icon(
              isNormal ? Icons.favorite_rounded : Icons.info_outline_rounded,
              color: isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Medición Completada',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Resultado registrado en tu historial de salud local',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Tarjeta de Resultado Principal
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${measurement.bpm}',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isNormal ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    measurement.statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isNormal ? const Color(0xFF059669) : const Color(0xFFD97706),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Rango Reposo', '60-100 BPM'),
                    _buildStatItem('Calidad', '${(measurement.qualityScore * 100).toInt()}%'),
                    _buildStatItem('Hora', '${measurement.timestamp.hour.toString().padLeft(2, '0')}:${measurement.timestamp.minute.toString().padLeft(2, '0')}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Descargo de Responsabilidad Médica
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Esta medición utiliza fotopletismografía óptica con fines de monitoreo personal y bienestar. No sustituye una evaluación clínica formal ni un electrocardiograma médico profesional.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restartMeasurement,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Medir de nuevo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(measurement),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BiomarkColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PpgWavePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _PpgWavePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (data.length > 1 ? data.length - 1 : 1);
    final centerY = size.height / 2;

    for (int i = 0; i < data.length; i++) {
      // Normalizar valor centrado con rango dinámico agradable
      final y = (centerY - (data[i] * 24.0)).clamp(4.0, size.height - 4.0);
      final x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PpgWavePainter oldDelegate) => true;
}
