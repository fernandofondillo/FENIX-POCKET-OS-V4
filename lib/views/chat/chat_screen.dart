// lib/views/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/app_config.dart';
import '../../models/payload_request.dart';
import '../../services/api_service.dart';
import '../../services/capsule_detector.dart';
import '../../services/emotion_detector.dart';
import '../../services/local_embedding_service.dart';
import '../../services/memory_service.dart';
import '../../services/perfil_db_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final _memoryService = MemoryService();
  final _emotionDetector = EmotionDetector();
  final _embeddingService = LocalEmbeddingService();

  late final ApiService _api;
  late final PerfilDbService _perfilDb;

  bool _isLoading = false;
  String _userId = '';

  // La cápsula que el sistema ESTÁ USANDO AHORA MISMO (detectada o la base)
  String _currentCapsuleId = 'general_coordinator';
  String _currentCapsuleName = 'Fénix';
  String _currentCapsuleEmoji = '🤖';
  Color _currentCapsuleColor = const Color(0xFF3B82F6);
  String _currentCapsuleSystemPrompt = '';

  // Catálogo espejo (mismas definiciones que capsules_screen)
  final List<_Capsule> _capsules = const [
    _Capsule(
      id: 'general_coordinator',
      name: 'Fénix Base',
      emoji: '🤖',
      accentColor: Color(0xFF3B82F6),
      systemPrompt: 'Eres Fénix, un asistente amigo personal muy servicial y natural. Actúas como coordinador general de capacidades. Tu tono es cálido, conciso y profesional.',
      allowedSkills: ['agenda_crear', 'notificacion_enviar'],
    ),
    _Capsule(
      id: 'fitness_expert',
      name: 'Coach Carlos',
      emoji: '🏋️‍♂️',
      accentColor: Color(0xFFF97316),
      systemPrompt: 'Actúa como un coach de fitness y experto en ciencias del deporte de élite. Sé riguroso, técnico y motivador.',
      allowedSkills: ['agenda_crear', 'notificacion_enviar'],
    ),
    _Capsule(
      id: 'nutricion_expert',
      name: 'Dra. Sofía',
      emoji: '🥑',
      accentColor: Color(0xFF10B981),
      systemPrompt: 'Actúa como una doctora experta en nutrición cetogénica, fisiología metabólica y optimización lipídica.',
      allowedSkills: ['notificacion_enviar'],
    ),
    _Capsule(
      id: 'zen_mentor',
      name: 'Mentor Aurelio',
      emoji: '🧘',
      accentColor: Color(0xFFA8A29E),
      systemPrompt: 'Actúa como un mentor zen y filósofo estoico. Tu comunicación es pausada, profunda y evocadora.',
      allowedSkills: ['agenda_crear'],
    ),
    _Capsule(
      id: 'elderly_care',
      name: 'Cuidador Mateo',
      emoji: '🧓',
      accentColor: Color(0xFF14B8A6),
      systemPrompt: 'Actúa como un cuidador empático y paciente, especializado en personas mayores.',
      allowedSkills: ['notificacion_enviar', 'agenda_crear'],
    ),
    _Capsule(
      id: 'biohacking_expert',
      name: 'Dr. Lex',
      emoji: '🧬',
      accentColor: Color(0xFF06B6D4),
      systemPrompt: 'Actúa como un científico vanguardista en biohacking y extensión radical de la vida.',
      allowedSkills: ['agenda_crear', 'notificacion_enviar'],
    ),
    _Capsule(
      id: 'pro_work_assistant',
      name: 'Ejecutiva Elena',
      emoji: '💼',
      accentColor: Color(0xFF6366F1),
      systemPrompt: 'Actúa como una asistente ejecutiva de alto nivel, experta en metodologías como Pomodoro, Time-boxing y GTD.',
      allowedSkills: ['agenda_crear', 'notificacion_enviar', 'web_search'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
    _perfilDb = PerfilDbService();
    await _memoryService.init_memory();
    await _emotionDetector.init();
    await _embeddingService.init_model();

    // Cargar identidad
    _userId = await _storage.read(key: 'user_id') ?? 'anon';

    // Por defecto, mostrar Fénix Base hasta el primer mensaje
    final base = _capsules.firstWhere((c) => c.id == 'general_coordinator');
    _setCurrentCapsule(base);

    setState(() {});
  }

  void _setCurrentCapsule(_Capsule c) {
    _currentCapsuleId = c.id;
    _currentCapsuleName = c.name;
    _currentCapsuleEmoji = c.emoji;
    _currentCapsuleColor = c.accentColor;
    _currentCapsuleSystemPrompt = c.systemPrompt;
  }

  /// Resolver cápsula objetivo: la detectada dinámicamente si está activa,
  /// si no, fallback a la base (Fénix Base como orquestador).
  Future<_Capsule> _resolveCapsule(String text) async {
    final detectedId = CapsuleDetector.detectar_capsula(text);

    // Cargar las activas
    final activeStr = await _storage.read(key: 'active_capsule_ids') ?? 'general_coordinator';
    final activeIds = activeStr.split(',').toSet();

    if (activeIds.contains(detectedId)) {
      return _capsules.firstWhere(
        (c) => c.id == detectedId,
        orElse: () => _capsules.firstWhere((c) => c.id == 'general_coordinator'),
      );
    }
    // Si la detectada NO está activa, el orquestador (Fénix Base) responde
    return _capsules.firstWhere((c) => c.id == 'general_coordinator');
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      // 1. Resolver cápsula objetivo (DETECCIÓN DINÁMICA)
      final targetCapsule = await _resolveCapsule(text);
      final capsuleChanged = targetCapsule.id != _currentCapsuleId;

      // 2. Detectar emoción
      final emocion = await _emotionDetector.detectar_emocion(text);

      // 3. Cargar identidad EAV completa
      final identidad = await _perfilDb.obtenerEavComoMap() ?? {};
      final perfilStr = identidad.entries.map((e) => '${e.key}=${e.value}').join('\n');

      // 4. Búsqueda RAG local
      String ragText = 'Sin coincidencias en Nano-Obsidian local.';
      try {
        final queryVec = await _embeddingService.generar_vector(text);
        final topK = await _embeddingService.buscar_top_k(queryVec, k: 3);
        if (topK.isNotEmpty) {
          ragText = topK.map((r) => '[${r['chapter']}] sim=${(r['similarity'] as double).toStringAsFixed(2)}').join('\n');
        }
      } catch (_) {}

      // 5. Historial reciente (FIFO 8)
      _memoryService.agregar_mensaje_inmediato('user', text);
      final historial = _memoryService.obtener_memoria_inmediata();

      // 6. Cambiar cápsula visual si cambió (HUD dinámico)
      if (capsuleChanged) {
        setState(() => _setCurrentCapsule(targetCapsule));
      }

      // 7. Armar payload (contrato exacto del backend)
      final payload = PayloadRequest(
        userId: _userId,
        mensajeActual: text,
        perfilIdentidad: perfilStr,
        contextoRagHibrido: {
          'historial_usuario': '',
          'conocimiento_experto': ragText,
        },
        capsulaActiva: {
          'id': targetCapsule.id,
          'system_prompt': targetCapsule.systemPrompt,
          'allowed_skills': targetCapsule.allowedSkills,
        },
        activeSkills: targetCapsule.allowedSkills,
        historialReciente: historial,
      );

      // 8. POST /api/v1/chat + long-polling
      final response = await _api.enviar_mensaje_con_polling(payload);

      // 9. Procesar respuesta
      final assistantText = response['assistant_response'] ?? '(sin respuesta)';
      final perfilUpdate = (response['perfil_update'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final executedSkills = (response['executed_skills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final inferencedBy = response['inferenced_by'] ?? 'qwen2.5';

      // 10. Memoria inmediata
      _memoryService.agregar_mensaje_inmediato('assistant', assistantText);

      // 11. Persistir mutaciones EAV
      for (final upd in perfilUpdate) {
        await _perfilDb.upsertEav(
          upd['categoria']?.toString() ?? 'general',
          upd['clave']?.toString() ?? '',
          upd['valor']?.toString() ?? '',
        );
      }

      // 12. Mostrar mensaje en chat con indicador de cápsula
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: assistantText,
          capsuleId: targetCapsule.id,
          capsuleName: targetCapsule.name,
          capsuleEmoji: targetCapsule.emoji,
          inferencedBy: inferencedBy,
        ));
        if (executedSkills.isNotEmpty) {
          final skillsInfo = executedSkills.map((s) => '⚡ ${s['skill_name']}').join(' • ');
          _messages.add(_ChatMessage(role: 'system', content: 'Skills ejecutadas: $skillsInfo'));
        }
        if (perfilUpdate.isNotEmpty) {
          final updates = perfilUpdate.map((u) => '🧠 ${u['categoria']}.${u['clave']}=${u['valor']}').join('\n');
          _messages.add(_ChatMessage(role: 'system', content: 'Identidad EAV mutada:\n$updates'));
        }
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'system',
          content: '❌ Error de transmisión: $e\n\nVerifica que la URL $apiBaseUrl esté accesible.',
        ));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get apiBaseUrl => AppConfig.apiBaseUrl;

  String _buildThinkingText() =>
      '$_currentCapsuleEmoji $_currentCapsuleName está pensando...';

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        centerTitle: true,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(_currentCapsuleId),
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _currentCapsuleColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_currentCapsuleEmoji, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Text(
                _currentCapsuleName,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white54, size: 20),
            tooltip: 'Gestionar cápsulas',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/capsules');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de orquestador si la cápsula actual NO es la base
          if (_currentCapsuleId != 'general_coordinator')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFF3B82F6), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '🤖 Fénix Base orquestó → $_currentCapsuleEmoji $_currentCapsuleName',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4C8CFA)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _buildThinkingText(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Fénix Base activo',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Las cápsulas se activan solas según el tema.\nHabla con naturalidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID: ${_userId.substring(0, _userId.length > 8 ? 8 : _userId.length)}...',
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.role == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      );
    }
    final isUser = msg.role == 'user';
    final capColor = msg.capsuleEmoji != null && !isUser
        ? _capsules.firstWhere(
            (c) => c.id == msg.capsuleId,
            orElse: () => _capsules.first,
          ).accentColor
        : const Color(0xFF4C8CFA);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: capColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(msg.capsuleEmoji ?? '🤖', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4C8CFA) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: isUser ? null : const Radius.circular(4),
                  topRight: isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && msg.capsuleName != null) ...[
                    Text(
                      '${msg.capsuleEmoji} ${msg.capsuleName}',
                      style: TextStyle(color: capColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    msg.content,
                    style: TextStyle(color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(color: Color(0xFF0D0D12)),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Habla con Fénix...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _currentCapsuleColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final String? capsuleId;
  final String? capsuleName;
  final String? capsuleEmoji;
  final String? inferencedBy;

  _ChatMessage({
    required this.role,
    required this.content,
    this.capsuleId,
    this.capsuleName,
    this.capsuleEmoji,
    this.inferencedBy,
  });
}

class _Capsule {
  final String id;
  final String name;
  final String emoji;
  final Color accentColor;
  final String systemPrompt;
  final List<String> allowedSkills;

  const _Capsule({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accentColor,
    required this.systemPrompt,
    required this.allowedSkills,
  });
}