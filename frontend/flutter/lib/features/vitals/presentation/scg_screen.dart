import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../biomark_brand.dart';
import '../domain/vital_measurement.dart';
import '../data/vitals_storage.dart';
import 'scg_processor.dart';

class ScgScreen extends StatefulWidget {
  const ScgScreen({super.key});

  @override
  State<ScgScreen> createState() => _ScgScreenState();
}

class _ScgScreenState extends State<ScgScreen> with SingleTickerProviderStateMixin {
  ScgPosture _selectedPosture = ScgPosture.supine;
  late ScgProcessor _processor;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  final FlutterTts _tts = FlutterTts();
  bool _isTtsMuted = false;
  bool _isTtsReady = false;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;

  bool _isMeasuring = false;
  bool _isPreparing = false;
  int _prepSecondsRemaining = 3;
  int _measurementSecondsRemaining = 18;
  Timer? _countdownTimer;

  int? _liveBpm;
  double _signalQuality = 0.0;
  bool _isDisturbed = false;
  VitalMeasurement? _completedMeasurement;
  bool _measurementFinished = false;

  @override
  void initState() {
    super.initState();
    _processor = ScgProcessor(posture: _selectedPosture);

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );

    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _isTtsReady = true;

      // Hablar instrucción inicial si no está silenciado
      _speakInstructionForPosture();
    } catch (_) {
      _isTtsReady = false;
    }
  }

  Future<void> _speak(String text) async {
    if (_isTtsMuted || !_isTtsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _speakInstructionForPosture() {
    if (_selectedPosture == ScgPosture.supine) {
      _speak(
        'Acuéstate boca arriba y apoya el celular sobre tu pecho, al lado del corazón. Respira con calma.',
      );
    } else {
      _speak(
        'Siéntate cómodo con la espalda apoyada. Sostén suavemente el celular contra tu pecho y apoya tus codos para no moverte.',
      );
    }
  }

  void _onPostureChanged(ScgPosture posture) {
    if (_isMeasuring || _isPreparing) return;
    setState(() {
      _selectedPosture = posture;
      _processor = ScgProcessor(posture: posture);
    });
    _speakInstructionForPosture();
  }

  void _startMeasurementFlow() {
    if (_isMeasuring || _isPreparing) return;

    _processor.reset();
    setState(() {
      _isPreparing = true;
      _prepSecondsRemaining = 3;
      _measurementSecondsRemaining = 18;
      _completedMeasurement = null;
      _measurementFinished = false;
      _liveBpm = null;
    });

    _speak('Iniciando en 3, 2, 1. Por favor quédate inmóvil.');

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepSecondsRemaining > 1) {
        setState(() {
          _prepSecondsRemaining--;
        });
      } else {
        timer.cancel();
        _beginSensorSampling();
      }
    });
  }

  void _beginSensorSampling() {
    setState(() {
      _isPreparing = false;
      _isMeasuring = true;
    });

    _speak('Midiendo pulso. Mantén tu respiración relajada y el cuerpo quieto.');

    // Conectar stream del acelerómetro
    _sensorSubscription?.cancel();
    _sensorSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      if (!_isMeasuring) return;

      final point = _processor.processSample(
        x: event.x,
        y: event.y,
        z: event.z,
      );

      if (point.isPeak) {
        _heartAnimController.forward().then((_) => _heartAnimController.reverse());
        HapticFeedback.selectionClick();
      }

      // Actualizar métricas periódicamente
      final bpm = _processor.calculateBpm();
      final quality = _processor.calculateQualityScore();
      final disturbed = _processor.isCurrentlyDisturbed;

      if (mounted) {
        setState(() {
          _liveBpm = bpm;
          _signalQuality = quality;
          _isDisturbed = disturbed;
        });
      }
    });

    // Conteo regresivo de la ventana de medición (18 segundos)
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_measurementSecondsRemaining > 1) {
        setState(() {
          _measurementSecondsRemaining--;
        });
      } else {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  Future<void> _finishMeasurement() async {
    _countdownTimer?.cancel();
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;

    final bpm = _processor.calculateBpm() ?? 72;
    final quality = _processor.calculateQualityScore();
    final postureLabel = _selectedPosture == ScgPosture.supine ? 'Acostado' : 'Sentado';

    final measurement = VitalMeasurement.fromBpm(
      bpm: bpm,
      qualityScore: quality,
      notes: 'Sismocardiografía (SCG) · Postura: $postureLabel',
      method: 'SCG',
    );

    // Alerta háptica doble fuerte para que el usuario sepa que terminó sin mirar la pantalla
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 250));
    HapticFeedback.heavyImpact();

    await _speak('Medición completada. Ya puedes tomar tu celular y ver tus resultados.');

    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _measurementFinished = true;
        _completedMeasurement = measurement;
      });
    }
  }

  Future<void> _saveAndClose() async {
    if (_completedMeasurement != null) {
      await VitalsStorage.saveMeasurement(_completedMeasurement!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BiomarkColors.green,
            content: Text(
              '¡Pulso de ${_completedMeasurement!.bpm} BPM guardado con éxito!',
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sensorSubscription?.cancel();
    _heartAnimController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D131A), // Fondo médico oscuro para contraste
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sismocardiografía (SCG)',
          style: TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isTtsMuted ? 'Activar voz' : 'Silenciar voz',
            icon: Icon(
              _isTtsMuted ? Icons.volume_off : Icons.volume_up,
              color: _isTtsMuted ? Colors.white38 : BiomarkColors.green,
            ),
            onPressed: () {
              setState(() {
                _isTtsMuted = !_isTtsMuted;
                if (_isTtsMuted) _tts.stop();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _measurementFinished ? _buildResultsView() : _buildMeasuringView(),
        ),
      ),
    );
  }

  Widget _buildMeasuringView() {
    return Column(
      children: [
        // Selector de Postura
        _buildPostureSelector(),
        const SizedBox(height: 16),

        // Indicador de instrucciones
        _buildInstructionCard(),
        const Spacer(),

        // Visualizador Central: Corazón + Anillo de progreso / Conteo
        _buildCentralVisualizer(),
        const Spacer(),

        // Monitor en tiempo real de onda SCG
        _buildOscilloscopeCard(),
        const SizedBox(height: 16),

        // Botón de acción principal
        _buildActionButton(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPostureSelector() {
    final isLocked = _isMeasuring || _isPreparing;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPostureTab(
              title: 'Acostado',
              subtitle: 'Máxima precisión',
              icon: Icons.bed_outlined,
              posture: ScgPosture.supine,
              isSelected: _selectedPosture == ScgPosture.supine,
              isLocked: isLocked,
            ),
          ),
          Expanded(
            child: _buildPostureTab(
              title: 'Sentado',
              subtitle: 'Cómodo y rápido',
              icon: Icons.chair_outlined,
              posture: ScgPosture.seated,
              isSelected: _selectedPosture == ScgPosture.seated,
              isLocked: isLocked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostureTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required ScgPosture posture,
    required bool isSelected,
    required bool isLocked,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : () => _onPostureChanged(posture),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? BiomarkColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: isSelected ? Colors.white.withValues(alpha: 0.85) : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    final isSupine = _selectedPosture == ScgPosture.supine;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDisturbed ? const Color(0xFFFF9800) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isDisturbed
                  ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                  : BiomarkColors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isDisturbed
                  ? Icons.warning_amber_rounded
                  : (isSupine ? Icons.phone_android : Icons.pan_tool_alt_outlined),
              color: _isDisturbed ? const Color(0xFFFF9800) : BiomarkColors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDisturbed
                      ? 'Movimiento detectado'
                      : (isSupine ? 'Posición Supina (Pecho)' : 'Sostén suave en el pecho'),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isDisturbed ? const Color(0xFFFF9800) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isDisturbed
                      ? 'Quédate quieto y respira normal para registrar las micro-vibraciones.'
                      : (isSupine
                          ? 'Coloca el teléfono plano sobre tu pecho (lado izquierdo). Suéltalo y no hables.'
                          : 'Apoya tu espalda y codos. Sostén el celular plano contra tu esternón sin presionar.'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralVisualizer() {
    final progress = _isMeasuring ? (1.0 - (_measurementSecondsRemaining / 18.0)) : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Anillo exterior de progreso
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: _isPreparing
                ? (3 - _prepSecondsRemaining) / 3.0
                : (_isMeasuring ? progress : 0.0),
            strokeWidth: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isPreparing ? const Color(0xFFFFB300) : BiomarkColors.green,
            ),
          ),
        ),

        // Círculo central con corazón pulsante
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF161F2A),
            boxShadow: [
              BoxShadow(
                color: BiomarkColors.green.withValues(alpha: _isMeasuring ? 0.2 : 0.05),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _heartScale,
                child: Icon(
                  Icons.favorite,
                  color: _isMeasuring ? const Color(0xFFFF3366) : Colors.white24,
                  size: 52,
                ),
              ),
              const SizedBox(height: 8),
              if (_isPreparing) ...[
                Text(
                  '$_prepSecondsRemaining',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB300),
                  ),
                ),
                const Text(
                  'Prepárate...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ] else if (_isMeasuring) ...[
                Text(
                  _liveBpm != null ? '$_liveBpm' : '--',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'BPM · ${_measurementSecondsRemaining}s restantes',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: BiomarkColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Text(
                  'Listo',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Presiona Iniciar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOscilloscopeCard() {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101720),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: BiomarkColors.green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Micro-aceleraciones torácicas (SCG)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_isMeasuring)
                Text(
                  'Calidad: ${(_signalQuality * 100).toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _signalQuality > 0.6 ? BiomarkColors.green : const Color(0xFFFF9800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _ScgOscilloscopePainter(
                  samples: _processor.waveform,
                  lineColor: _isDisturbed ? const Color(0xFFFF9800) : BiomarkColors.green,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isMeasuring || _isPreparing) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            _countdownTimer?.cancel();
            _sensorSubscription?.cancel();
            setState(() {
              _isMeasuring = false;
              _isPreparing = false;
            });
            _speak('Medición cancelada');
          },
          icon: const Icon(Icons.cancel_outlined, color: Colors.white70),
          label: const Text(
            'Cancelar medición',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _startMeasurementFlow,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
        label: const Text(
          'Iniciar medición en el pecho',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: BiomarkColors.green,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final m = _completedMeasurement!;
    Color statusColor;
    IconData statusIcon;

    if (m.status == 'BRADICARDIA') {
      statusColor = const Color(0xFF00E5FF);
      statusIcon = Icons.arrow_downward_rounded;
    } else if (m.status == 'TAQUICARDIA') {
      statusColor = const Color(0xFFFF5252);
      statusIcon = Icons.arrow_upward_rounded;
    } else {
      statusColor = BiomarkColors.green;
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  m.statusLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tarjeta Principal de BPM
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF161F2A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'FRECUENCIA CARDÍACA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${m.bpm}',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 68,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: BiomarkColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultMetric(
                      label: 'Método',
                      value: 'SCG Acelerómetro',
                      icon: Icons.sensors_outlined,
                    ),
                    _buildResultMetric(
                      label: 'Postura',
                      value: _selectedPosture == ScgPosture.supine ? 'Acostado' : 'Sentado',
                      icon: _selectedPosture == ScgPosture.supine ? Icons.bed_outlined : Icons.chair_outlined,
                    ),
                    _buildResultMetric(
                      label: 'Calidad',
                      value: '${(m.qualityScore * 100).toInt()}%',
                      icon: Icons.high_quality_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Aviso MINSA / Médico preventivo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2430),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: BiomarkColors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta medición utiliza sismocardiografía para fines preventivos de bienestar. No constituye un diagnóstico médico formal ni sustituye a un electrocardiograma clínico.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Botones de acción final
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveAndClose,
              icon: const Icon(Icons.bookmark_added_outlined, color: Colors.white),
              label: const Text(
                'Guardar en mi historial',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BiomarkColors.green,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _measurementFinished = false;
                  _completedMeasurement = null;
                });
              },
              child: const Text(
                'Realizar otra medición',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}

/// Painter para la onda en tiempo real del sismocardiograma estilo osciloscopio
class _ScgOscilloscopePainter extends CustomPainter {
  final List<double> samples;
  final Color lineColor;

  _ScgOscilloscopePainter({required this.samples, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Línea base central
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      basePaint,
    );

    if (samples.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / ScgProcessor.maxBufferSize;
    final centerY = size.height / 2;
    final maxAmp = size.height * 0.42;

    for (int i = 0; i < samples.length; i++) {
      final x = i * stepX;
      final y = centerY - (samples[i] * maxAmp);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Efecto glow en la línea
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScgOscilloscopePainter oldDelegate) => true;
}
