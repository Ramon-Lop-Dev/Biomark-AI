// Construye la pantalla de chat y coordina su interacción con el cliente de datos.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../biomark_brand.dart';
import '../../../core/design/biomark_clay.dart';
import '../data/chat_api.dart';
import '../../progress/data/progress_api.dart';
import '../data/vision_api.dart';
import '../data/voice_api.dart';
import '../domain/chat_message.dart';

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
  late final ProgressApi _progressApi;
  final _recorder = AudioRecorder();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      '¡Hola! Soy Biomark AI. ¿En qué puedo ayudarte hoy con tu salud?',
      false,
    ),
  ];

  static const _apiUrl = String.fromEnvironment(
    'BIOMARK_API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const _accessToken = String.fromEnvironment('BIOMARK_ACCESS_TOKEN');
  String? _sessionId;
  String? _errorMessage;
  bool _isSending = false;
  bool _isRecording = false;
  bool _audioDraftReady = false;
  bool _audioDraftPaused = false;
  String? _audioDraftPath;
  double _audioLevel = 0.0;
  StreamSubscription<Amplitude>? _amplitudeSub;
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

  Future<void> _showClosestCenterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BiomarkColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: BiomarkColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Centro de salud más cercano',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Centro de Salud Villa Libertad',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Consulta general · Atención rápida · 2.4 km',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: BiomarkColors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Calle Principal 120, próximo al parque central',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Ir ahora'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // TODO: conectar con /api/gis/nearby para obtener el centro real más cercano.
  }

  Future<void> _showProgressDialog() async {
    final symptomController = TextEditingController();
    final notesController = TextEditingController();
    var status = 'MEJORO';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar evolución'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symptomController,
                decoration: const InputDecoration(
                  labelText: '¿Qué síntoma estás siguiendo?',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'MEJORO', child: Text('Mejoré')),
                  DropdownMenuItem(value: 'IGUAL', child: Text('Sigo igual')),
                  DropdownMenuItem(value: 'EMPEORO', child: Text('Empeoré')),
                  DropdownMenuItem(
                    value: 'NO_SEGURO',
                    child: Text('No estoy seguro'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => status = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || shouldSave != true) {
      symptomController.dispose();
      notesController.dispose();
      return;
    }
    if (symptomController.text.trim().isEmpty) {
      symptomController.dispose();
      notesController.dispose();
      _showMessage('Escribe el síntoma que quieres seguir.');
      return;
    }

    try {
      await _progressApi.createProgress(
        symptom: symptomController.text,
        status: status,
        notes: notesController.text,
      );
      if (mounted) _showMessage('Evolución registrada correctamente.');
    } catch (_) {
      if (mounted) _showMessage('No se pudo registrar la evolución.');
    } finally {
      symptomController.dispose();
      notesController.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _chatApi = ChatApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _voiceApi = VoiceApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _visionApi = VisionApi(baseUrl: _apiUrl, accessToken: _accessToken);
    _progressApi = ProgressApi();
    _entryController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showHealthDisclaimer();
    });
  }

  Future<void> _showHealthDisclaimer() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Image(
              image: AssetImage('assets/branding/Icono.png'),
              width: 52,
              height: 52,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Antes de comenzar',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        content: const Text(
          'Biomark AI orienta tu salud, pero no reemplaza el diagnóstico de un profesional. Consulta siempre a tu médico.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _chooseVisionType() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tipo de análisis visual'),
          content: const Text(
            'Selecciona qué parte del cuerpo quieres analizar con la imagen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'piel'),
              child: const Text('Piel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'garganta'),
              child: const Text('Garganta'),
            ),
          ],
        );
      },
    );

    return result;
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
    _scrollToBottom();

    try {
      final response = await _visionApi.sendImage(
        path: path,
        tipo: tipo,
        sessionId: _sessionId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            'Análisis de ${tipo == 'piel' ? 'piel' : 'garganta'}: ${response.condicionDetectada}. ${response.reply}',
            false,
            riskLevel: response.riskLevel,
            sources: response.sources,
          ),
        );
        _isSending = false;
      });
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
    _scrollToBottom();

    try {
      final response = await _chatApi.sendMessage(
        message: text,
        sessionId: _sessionId,
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
          ),
        );
        _isSending = false;
      });
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo conectar con Biomark AI.';
        _isSending = false;
      });
    }
    _scrollToBottom();
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
          ),
        );
        _isSending = false;
      });
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSending = false;
      });
    }
    _scrollToBottom();
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
          body: Column(
            children: [
              //InfoBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return const _TypingBubble();
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
              if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
              _ChatInput(
                controller: _controller,
                enabled: !_isSending,
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _amplitudeSub?.cancel();
    _chatApi.dispose();
    _voiceApi.dispose();
    _visionApi.dispose();
    _recorder.dispose();
    _entryController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!message.isUser && message.actionType != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: _FollowUpActionCard(actionType: message.actionType!),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: BiomarkClaySurface(
          color: message.isUser ? BiomarkColors.blue : BiomarkColors.white,
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
                if (message.text.isNotEmpty)
                  Padding(
                    padding: message.imagePath != null
                        ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
                        : EdgeInsets.zero,
                    child: Text(
                      message.text,
                      style: textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? BiomarkColors.white
                            : BiomarkColors.black,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowUpActionCard extends StatelessWidget {
  final String actionType;

  const _FollowUpActionCard({required this.actionType});

  @override
  Widget build(BuildContext context) {
    final isRegisterProgress = actionType == 'register_progress';
    final isNearestCenter = actionType == 'nearest_center';

    return Container(
      width: MediaQuery.sizeOf(context).width * 0.78,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isRegisterProgress) ...[
            const Icon(
              Icons.insights_rounded,
              size: 28,
              color: BiomarkColors.blue,
            ),
            const SizedBox(height: 8),
            const Text(
              'Podemos registrar cómo ha evolucionado este síntoma.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context
                    .findAncestorStateOfType<_ChatScreenState>()
                    ?._showProgressDialog(),
                style: FilledButton.styleFrom(
                  backgroundColor: BiomarkColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Registrar evolución'),
              ),
            ),
          ] else if (isNearestCenter) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BiomarkColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: BiomarkColors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recomendación de Biomark AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hospital Alemán Nicaragüense\n1.2 km',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context
                    .findAncestorStateOfType<_ChatScreenState>()
                    ?._showClosestCenterDialog(),
                style: FilledButton.styleFrom(
                  backgroundColor: BiomarkColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Ver en mapa'),
              ),
            ),
          ] else ...[
            const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: BiomarkColors.blue,
            ),
            const SizedBox(height: 8),
            const Text(
              'Biomark AI detectó una acción para tu seguimiento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Subir imagen',
                        onPressed: enabled ? onOpenImagePicker : null,
                        icon: const Icon(Icons.camera_alt_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: enabled,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: const InputDecoration(
                            hintText: 'Describe cómo te sientes...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        tooltip: 'Grabar audio',
                        onPressed: enabled ? onVoice : null,
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        tooltip: 'Enviar mensaje',
                        onPressed: enabled ? onSend : null,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _VoiceRecordingPanel extends StatefulWidget {
  final VoidCallback onVoice;
  final double audioLevel;

  const _VoiceRecordingPanel({required this.onVoice, required this.audioLevel});

  @override
  State<_VoiceRecordingPanel> createState() => _VoiceRecordingPanelState();
}

class _VoiceRecordingPanelState extends State<_VoiceRecordingPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  late final AnimationController _barsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
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
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF8C6),
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
          const Expanded(
            child: Text(
              'Grabando audio...',
              style: TextStyle(
                color: Color(0xFF1F2A1F),
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
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF8C6),
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
          const Expanded(
            child: Text(
              'Audio listo',
              style: TextStyle(
                color: Color(0xFF1F2A1F),
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
