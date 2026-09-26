// Construye la pantalla de chat y coordina su interacción con el cliente de datos.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';

import '../../../biomark_brand.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/biomark_clay.dart';
import '../../../core/ui/biomark_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/chat_api.dart';
import '../data/chat_storage.dart';
import '../data/vision_api.dart';
import '../data/voice_api.dart';
import '../data/offline_chat_engine.dart';
import '../domain/chat_message.dart';
import '../../gis/presentation/gis_map_screen.dart';
import '../../gis/domain/health_center.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late final ChatApi _chatApi;
  late final VoiceApi _voiceApi;
  late final VisionApi _visionApi;
  final _recorder = AudioRecorder();
  late final AudioPlayer _audioPlayer;
  final List<ChatMessage> _messages = [
    const ChatMessage(
      '¡Hola! Soy Biomark AI. ¿En qué puedo ayudarte hoy con tu salud?',
      false,
    ),
  ];

  static const _apiUrl = AppConfig.apiUrl;
  static String get _accessToken => AuthSession.instance.accessToken ?? '';
  String? _sessionId;
  String? _errorMessage;
  bool _isSending = false;
  bool _hasText = false;
  bool _isRecording = false;
  bool _audioDraftReady = false;
  bool _audioDraftPaused = false;
  String? _audioDraftPath;
  double _audioLevel = 0.0;
  StreamSubscription<Amplitude>? _amplitudeSub;

  void _persistMessages() {
    ChatStorage.saveMessages(_messages, sessionId: _sessionId);
  }
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  String? _mapSuggestedAction(String? action) {
    switch (action) {
      case 'REGISTER_PROGRESS':
        return 'register_progress';
      case 'REGISTER_MEDICATION':
        return 'register_medication';
      case 'REGISTER_REMINDER':
        return 'register_reminder';
      case 'SHOW_NEAREST_CENTER':
        return 'nearest_center';
      default:
        return null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<Position?> _getChatLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) _showMessage('Activa la ubicación del teléfono para buscar el centro más cercano.');
        await Geolocator.openLocationSettings();
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage('Activa el permiso de ubicación para recomendarte centros cercanos.');
        }
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _showClosestCenterDialog({
    HealthCenterRecommendation? center,
  }) async {
    final recommendedCenter = center ??
        (_messages.lastWhere(
          (message) => message.recommendedCenter != null,
          orElse: () => const ChatMessage('', false),
        ).recommendedCenter);

    if (recommendedCenter == null) return;

    final mapCenter = HealthCenter(
      id: recommendedCenter.id ?? 'recommended-center',
      name: recommendedCenter.name,
      type: 'CENTRO_SALUD',
      latitude: recommendedCenter.latitude ?? 12.1364,
      longitude: recommendedCenter.longitude ?? -86.2514,
      address: recommendedCenter.address ?? 'Dirección no disponible',
      phone: '',
      distanceKm: recommendedCenter.distanceKm,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GisMapScreen(initialCenter: mapCenter),
      ),
    );
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText && mounted) {
      setState(() => _hasText = has);
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _chatApi = ChatApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _voiceApi = VoiceApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _visionApi = VisionApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _controller.addListener(_onTextChanged);
    _entryController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadChatHistory();
        _showHealthDisclaimer();
        _getChatLocation();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    // 1. Cargar caché persistente local de inmediato para que el usuario no pierda su historial
    final cached = await ChatStorage.loadMessages();
    if (cached.messages.isNotEmpty && mounted) {
      setState(() {
        if (cached.sessionId != null) _sessionId = cached.sessionId;
        _messages
          ..clear()
          ..addAll(cached.messages);
      });
      _scrollToBottom();
    }

    // 2. Sincronizar con el historial remoto del backend si está disponible
    try {
      final history = await _chatApi.loadHistory();
      if (!mounted) return;
      if (history.messages.isNotEmpty) {
        setState(() {
          if (history.sessionId != null) _sessionId = history.sessionId;
          _messages
            ..clear()
            ..addAll(history.messages.map((message) => ChatMessage(
                  message.text,
                  message.isUser,
                  riskLevel: message.riskLevel,
                )));
          if (_messages.isEmpty) {
            _messages.add(const ChatMessage(
              '¡Hola! Soy Biomark AI. ¿En qué puedo ayudarte hoy con tu salud?',
              false,
            ));
          }
        });
        _persistMessages();
        _scrollToBottom();
      }
    } catch (_) {
      // El chat sigue disponible con el historial local aunque no haya conexión.
    }
  }

  Future<void> _showHealthDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAccepted = prefs.getBool('biomark_health_disclaimer_accepted') ?? false;
    if (alreadyAccepted || !mounted) return;

    await BiomarkDialog.showCustom<void>(
      context,
      barrierDismissible: false,
      iconWidget: const Image(
        image: AssetImage('assets/branding/Icono.png'),
        width: 48,
        height: 48,
      ),
      title: 'Antes de comenzar',
      message: 'Biomark AI orienta tu salud, pero no reemplaza el diagnóstico de un profesional. Consulta siempre a tu médico.',
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: BiomarkColors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
          onPressed: () {
            prefs.setBool('biomark_health_disclaimer_accepted', true);
            Navigator.pop(context);
          },
          child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<String?> _chooseVisionType() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: isDark ? 0.35 : 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipo de Análisis Visual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selecciona qué deseas que interprete Biomark AI:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildVisionOptionTile(
                  ctx: ctx,
                  icon: Icons.healing_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'Lesión o Síntoma en la Piel',
                  subtitle: 'Erupciones, manchas, golpes o irritaciones cutáneas.',
                  value: 'piel',
                ),
                const SizedBox(height: 10),
                _buildVisionOptionTile(
                  ctx: ctx,
                  icon: Icons.face_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Garganta y Faringe',
                  subtitle: 'Enrojecimiento, amígdalas o placas visibles.',
                  value: 'garganta',
                ),
                const SizedBox(height: 10),
                _buildVisionOptionTile(
                  ctx: ctx,
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Receta Médica',
                  subtitle: 'Orientación de medicamentos y cuidados (no prescribe).',
                  value: 'receta',
                ),
                const SizedBox(height: 10),
                _buildVisionOptionTile(
                  ctx: ctx,
                  icon: Icons.biotech_rounded,
                  color: const Color(0xFF3B82F6),
                  title: 'Examen de Laboratorio',
                  subtitle: 'Explicación de rangos normales y parámetros analíticos.',
                  value: 'examen',
                ),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }

  Widget _buildVisionOptionTile({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.pop(ctx, value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 90,
    );

    if (pickedFile == null || !mounted) return;

    final tipo = await _chooseVisionType();
    if (tipo == null || !mounted) return;
    await _sendImageAnalysis(path: pickedFile.path, tipo: tipo);
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Elegir de la galería'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;
    await _pickImageFromSource(source);
  }

  Future<void> _sendImageAnalysis({
    required String path,
    required String tipo,
  }) async {
    if (_isSending) return;

    setState(() {
      _messages.add(ChatMessage('', true, imagePath: path));
      _errorMessage = null;
      _isSending = true;
    });
    _persistMessages();
    _scrollToBottom();

    try {
      final response = await _visionApi.sendImage(
        path: path,
        tipo: tipo,
        sessionId: _sessionId,
      );

      if (!mounted) return;

      final String tipoEtiqueta;
      switch (tipo) {
        case 'piel':
          tipoEtiqueta = 'lesión en piel';
          break;
        case 'garganta':
          tipoEtiqueta = 'garganta';
          break;
        case 'receta':
          tipoEtiqueta = 'receta médica';
          break;
        case 'examen':
          tipoEtiqueta = 'examen de laboratorio';
          break;
        default:
          tipoEtiqueta = 'imagen';
      }

      setState(() {
        _messages.add(
          ChatMessage(
            'Interpretación de $tipoEtiqueta: ${response.condicionDetectada.isNotEmpty ? "${response.condicionDetectada}. " : ""}${response.reply}',
            false,
            riskLevel: response.riskLevel,
            sources: response.sources,
          ),
        );
        _isSending = false;
      });
      _persistMessages();
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo enviar la imagen al backend/AI Service.';
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _controller.clear();
      _errorMessage = null;
      _isSending = true;
    });
    _persistMessages();
    _scrollToBottom();

    try {
      final position = await _getChatLocation();
      final response = await _chatApi.sendMessage(
        message: text,
        sessionId: _sessionId,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = response.sessionId;
        final actionType = _mapSuggestedAction(response.suggestedAction);
        _messages.add(
          ChatMessage(
            response.reply,
            false,
            riskLevel: response.riskLevel,
            sources: response.sources,
            actionType: actionType,
            recommendedCenter: response.recommendedCenter,
          ),
        );
        if (response.locationRequired && response.recommendedCenter == null) {
          _showMessage('Activa la ubicación para ver el centro u hospital más cercano a tu caso.');
        }
        _isSending = false;
      });
      _persistMessages();
    } on ChatApiException catch (_) {
      if (!mounted) return;
      _handleOfflineFallback(text);
    } catch (_) {
      if (!mounted) return;
      _handleOfflineFallback(text);
    }
    _scrollToBottom();
  }

  void _handleOfflineFallback(String userText) {
    final offlineReply = OfflineChatEngine.processOfflineQuery(
      query: userText,
      sessionId: _sessionId,
    );
    final actionType = _mapSuggestedAction(offlineReply.suggestedAction);
    setState(() {
      _sessionId = offlineReply.sessionId;
      _messages.add(
        ChatMessage(
          offlineReply.reply,
          false,
          riskLevel: offlineReply.riskLevel,
          sources: offlineReply.sources,
          actionType: actionType,
          recommendedCenter: offlineReply.recommendedCenter,
        ),
      );
      _errorMessage = null;
      _isSending = false;
    });
    _persistMessages();
    _showMessage('Respondido con la Guía Clínica Offline del MINSA (Sin Conexión).');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearAudioDraft() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    setState(() {
      _audioDraftReady = false;
      _audioDraftPaused = false;
      _audioDraftPath = null;
      _audioLevel = 0.0;
    });
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 90))
        .listen((event) {
          if (!mounted) return;
          final current = event.current.toDouble();
          final normalized = (current / 160).clamp(0.0, 1.0);
          setState(() => _audioLevel = normalized);
        });
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;

    if (_isRecording) {
      final path = await _recorder.stop();
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      setState(() {
        _isRecording = false;
        _audioDraftReady = path != null;
        _audioDraftPath = path;
        _audioDraftPaused = false;
        _audioLevel = 0.0;
      });
      return;
    }

    if (_audioDraftReady && _audioDraftPath != null) {
      _clearAudioDraft();
      return;
    }

    if (!await _recorder.hasPermission()) return;
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/biomark_voice.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _startAmplitudeMonitoring();
    setState(() {
      _isRecording = true;
      _audioLevel = 0.0;
    });
  }

  Future<void> _sendRecording(String path) async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _audioDraftReady = false;
      _audioDraftPaused = false;
    });
    try {
      final response = await _voiceApi.sendRecording(
        path: path,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      final directory = await getTemporaryDirectory();
      final audioPath = response.audioBytes.isEmpty
          ? null
          : '${directory.path}/biomark-response-${DateTime.now().millisecondsSinceEpoch}.wav';
      if (audioPath != null) {
        await File(audioPath).writeAsBytes(response.audioBytes, flush: true);
      }
      setState(() {
        _sessionId = response.sessionId;
        _messages.add(ChatMessage(response.transcription, true));
        final String? actionType = null;
        _messages.add(
          ChatMessage(
            response.reply,
            false,
            riskLevel: response.riskLevel,
            sources: response.sources,
            actionType: actionType,
            audioPath: audioPath,
          ),
        );
        _isSending = false;
      });
      _persistMessages();
      if (audioPath != null) await _playAudioFile(audioPath);
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _playAudioFile(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) _showMessage('No se pudo reproducir la respuesta de voz.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _entryController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/Icono.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  semanticLabel: 'Biomark AI',
                ),
                const SizedBox(width: 8),
                Text('Chat', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  //InfoBar(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) return const _TypingBubble();
                        return _MessageBubble(
                          message: _messages[index],
                          onPlayAudio: _messages[index].audioPath == null
                              ? null
                              : () => _playAudioFile(_messages[index].audioPath!),
                        );
                      },
                    ),
                  ),
                  if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
                  _ChatInput(
                    controller: _controller,
                    enabled: !_isSending,
                    hasText: _hasText,
                    isRecording: _isRecording,
                    isAudioDraftReady: _audioDraftReady,
                    audioDraftPaused: _audioDraftPaused,
                    audioLevel: _audioLevel,
                    onSend: _sendMessage,
                    onVoice: _toggleRecording,
                    onOpenImagePicker: _chooseImageSource,
                    onSendAudio: _audioDraftPath == null
                        ? null
                        : () => _sendRecording(_audioDraftPath!),
                    onDeleteAudio: _clearAudioDraft,
                    onPauseAudio: () {
                      setState(() => _audioDraftPaused = !_audioDraftPaused);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _amplitudeSub?.cancel();
    _chatApi.dispose();
    _voiceApi.dispose();
    _audioPlayer.dispose();
    _visionApi.dispose();
    _recorder.dispose();
    _entryController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onPlayAudio;

  const _MessageBubble({required this.message, this.onPlayAudio});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: BiomarkClaySurface(
          color: message.isUser ? BiomarkColors.blue : Theme.of(context).cardColor,
          radius: 18,
          padding: message.imagePath != null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/branding/Icono.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          semanticLabel: 'Avatar de Biomark AI',
                        ),
                        const SizedBox(width: 8),
                        Text('Biomark AI', style: textTheme.labelLarge),
                      ],
                    ),
                  ),
                if (message.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      File(message.imagePath!),
                      width: MediaQuery.sizeOf(context).width * 0.6,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.audioPath != null)
                  _WhatsAppAudioBubble(
                    audioPath: message.audioPath!,
                    isUser: message.isUser,
                  ),
                if (!message.isUser && message.sources.any((s) => s.contains('Sin Conexión')))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 13, color: Color(0xFFD97706)),
                        const SizedBox(width: 5),
                        Text(
                          'Modo Sin Conexión · Guía Oficial MINSA',
                          style: textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.text.isNotEmpty)
                  Padding(
                    padding: message.imagePath != null
                        ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
                        : EdgeInsets.zero,
                    child: _FormattedMessageText(
                      text: message.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? BiomarkColors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                if (!message.isUser && message.audioPath == null && onPlayAudio != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Escuchar respuesta',
                      onPressed: onPlayAudio,
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ),
                if (!message.isUser && message.riskLevel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Riesgo: ${message.riskLevel}',
                      style: textTheme.labelLarge?.copyWith(
                        color: BiomarkColors.green,
                      ),
                    ),
                  ),
                if (message.sources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Fuentes: ${message.sources.join(', ')}',
                      style: textTheme.bodySmall,
                    ),
                  ),
                if (!message.isUser && message.recommendedCenter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _RecommendedCenter(center: message.recommendedCenter!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renderiza texto con formato limpio, convirtiendo markdown de negrita (** o ***) en
/// texto enriquecido real y eliminando cualquier asterisco o símbolo residual.
class _FormattedMessageText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _FormattedMessageText({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = _parseSpans(text, baseStyle);
    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  static List<InlineSpan> _parseSpans(String rawText, TextStyle baseStyle) {
    if (rawText.isEmpty) return const [];

    // Limpiar secuencias accidentales o defectuosas como /**, /**/, */
    var cleanText = rawText
        .replaceAll('/**', '')
        .replaceAll('/**/', '')
        .replaceAll('*/', '');

    // Expresión regular que detecta negritas marcadas con ***...*** o **...**
    final regex = RegExp(r'(\*{2,3})([^\*]+?)(\1)');
    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final match in regex.allMatches(cleanText)) {
      if (match.start > currentIndex) {
        final normalChunk = cleanText.substring(currentIndex, match.start);
        // Eliminar asteriscos sueltos o residuales
        final sanitizedNormal = normalChunk.replaceAll(RegExp(r'\*{2,}'), '');
        if (sanitizedNormal.isNotEmpty) {
          spans.add(TextSpan(text: sanitizedNormal, style: baseStyle));
        }
      }

      final boldContent = match.group(2) ?? '';
      spans.add(TextSpan(
        text: boldContent,
        style: baseStyle.copyWith(fontWeight: FontWeight.w800),
      ));

      currentIndex = match.end;
    }

    if (currentIndex < cleanText.length) {
      final remaining = cleanText.substring(currentIndex);
      final sanitizedRemaining = remaining.replaceAll(RegExp(r'\*{2,}'), '');
      if (sanitizedRemaining.isNotEmpty) {
        spans.add(TextSpan(text: sanitizedRemaining, style: baseStyle));
      }
    }

    return spans;
  }
}

// ignore: unused_element
class _RecommendedCenter extends StatelessWidget {
  final HealthCenterRecommendation center;

  const _RecommendedCenter({required this.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BiomarkColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BiomarkColors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_hospital_rounded, color: BiomarkColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Centro recomendado',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      center.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (center.specialty != null) Text('Área: ${center.specialty}'),
                    Text('Distancia aproximada: ${center.distanceKm} km'),
                    if (center.address != null && center.address!.isNotEmpty)
                      Text(center.address!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final state = context.findAncestorStateOfType<_ChatScreenState>();
                state?._showClosestCenterDialog(center: center);
              },
              icon: const Icon(Icons.map_rounded),
              label: const Text('Ver en mapa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppAudioBubble extends StatefulWidget {
  final String audioPath;
  final bool isUser;

  const _WhatsAppAudioBubble({
    required this.audioPath,
    required this.isUser,
  });

  @override
  State<_WhatsAppAudioBubble> createState() => _WhatsAppAudioBubbleState();
}

class _WhatsAppAudioBubbleState extends State<_WhatsAppAudioBubble> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  double _speed = 1.0;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setSource(DeviceFileSource(widget.audioPath));
      final dur = await _player.getDuration();
      if (dur != null && mounted) {
        setState(() => _duration = dur);
      }
    } catch (_) {}

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted && dur > Duration.zero) {
        setState(() => _duration = dur);
      }
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else {
        await _player.setPlaybackRate(_speed);
        await _player.play(DeviceFileSource(widget.audioPath));
      }
    } catch (_) {}
  }

  Future<void> _cycleSpeed() async {
    final nextSpeed = _speed == 1.0
        ? 1.5
        : _speed == 1.5
            ? 2.0
            : 1.0;
    setState(() => _speed = nextSpeed);
    try {
      await _player.setPlaybackRate(nextSpeed);
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);
    final sliderVal = maxMs > 0 ? posMs : 0.0;
    final maxVal = maxMs > 0 ? maxMs : 1.0;

    final primaryColor = widget.isUser ? Colors.white : const Color(0xFF1B8E44);
    final trackColor = widget.isUser ? Colors.white54 : const Color(0xFFC5E3CE);
    final textColor = widget.isUser ? Colors.white70 : const Color(0xFF5F6D63);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isUser
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isUser
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFFDFEAE1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar con insignia de micrófono estilo WhatsApp
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: widget.isUser
                    ? Colors.white24
                    : const Color(0xFFD4EBD9),
                child: widget.isUser
                    ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
                    : Image.asset(
                        'assets/branding/Icono.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B8E44),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Botón Play / Pause
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isUser ? Colors.white : const Color(0xFF1B8E44),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isUser ? const Color(0xFF1E88E5) : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Barra de progreso y tiempos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: trackColor,
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: sliderVal,
                    min: 0.0,
                    max: maxVal,
                    onChanged: (val) {
                      _player.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPlaying || _position > Duration.zero
                            ? _formatDuration(_position)
                            : _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: _cycleSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isUser
                                ? Colors.white24
                                : const Color(0xFFE2EEE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_speed == 1.0 ? '1' : _speed == 1.5 ? '1.5' : '2'}x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: BiomarkClaySurface(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Analizando...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return BiomarkClaySurface(
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: BiomarkColors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool hasText;
  final bool isRecording;
  final bool isAudioDraftReady;
  final bool audioDraftPaused;
  final double audioLevel;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onOpenImagePicker;
  final VoidCallback? onSendAudio;
  final VoidCallback? onDeleteAudio;
  final VoidCallback? onPauseAudio;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.hasText,
    required this.isRecording,
    required this.isAudioDraftReady,
    required this.audioDraftPaused,
    required this.audioLevel,
    required this.onSend,
    required this.onVoice,
    required this.onOpenImagePicker,
    this.onSendAudio,
    this.onDeleteAudio,
    this.onPauseAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: isRecording
              ? _VoiceRecordingPanel(onVoice: onVoice, audioLevel: audioLevel)
              : isAudioDraftReady
                  ? _VoiceDraftPreview(
                      paused: audioDraftPaused,
                      onPause: onPauseAudio ?? () {},
                      onDelete: onDeleteAudio ?? () {},
                      onSend: onSendAudio ?? () {},
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cápsula estilo WhatsApp para el campo de texto y adjuntos
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.05,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    enabled: enabled,
                                    textInputAction: TextInputAction.send,
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 4,
                                    onSubmitted: (_) {
                                      if (hasText) onSend();
                                    },
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Mensaje',
                                      hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        fontSize: 15,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 12,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tomar o adjuntar foto',
                                  onPressed:
                                      enabled ? onOpenImagePicker : null,
                                  icon: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 22,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Botón circular independiente estilo WhatsApp (Micrófono <-> Enviar según haya texto)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884), // WhatsApp green
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A884)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: enabled
                                  ? (hasText ? onSend : onVoice)
                                  : null,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                  child: hasText
                                      ? const Icon(
                                          Icons.send_rounded,
                                          key: ValueKey('chat_send_icon'),
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : const Icon(
                                          Icons.mic_rounded,
                                          key: ValueKey('chat_mic_icon'),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _VoiceRecordingPanel extends StatefulWidget {
  final VoidCallback onVoice;
  final double audioLevel;

  const _VoiceRecordingPanel({
    required this.onVoice,
    required this.audioLevel,
  });

  @override
  State<_VoiceRecordingPanel> createState() => _VoiceRecordingPanelState();
}

class _VoiceRecordingPanelState extends State<_VoiceRecordingPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  late final AnimationController _barsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  double _getBarHeight(int index, double time) {
    final baseLevel = widget.audioLevel.clamp(0.0, 1.0);
    final phase = (time * 5 + index) % 1;
    final wave = ((1 - (phase - 0.5).abs() * 2) * 18).clamp(0.0, 18.0);
    final levelBoost = (baseLevel * 24) + 4;
    return (wave * (0.45 + baseLevel * 0.9)) + levelBoost;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _barsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3822) : const Color(0xFFDCF8C6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 0.9 + (_pulseController.value * 0.16);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: BiomarkColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Grabando audio...',
              style: TextStyle(
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1F2A1F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _barsController,
            builder: (context, _) {
              final base = _barsController.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final height = _getBarHeight(
                    index,
                    base,
                  ).clamp(8.0, 34.0).toDouble();
                  return Container(
                    width: 4,
                    height: height,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: BiomarkColors.green,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cancelar grabación',
            onPressed: widget.onVoice,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _VoiceDraftPreview extends StatelessWidget {
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const _VoiceDraftPreview({
    required this.paused,
    required this.onPause,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3822) : const Color(0xFFDCF8C6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: paused ? 'Reproducir audio' : 'Pausar audio',
            onPressed: onPause,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
              color: BiomarkColors.green,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Audio listo',
              style: TextStyle(
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1F2A1F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Quitar audio',
            onPressed: onDelete,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: 'Enviar audio',
            onPressed: onSend,
            style: IconButton.styleFrom(
              backgroundColor: BiomarkColors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}