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
import '../../services/skills_service.dart';

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
  late final SkillsService _skills;
  late final PerfilDbService _perfilDb;

  bool _isLoading = false;
  String _userId = '';
  String _capsuleName = 'Fénix';
  String _capsuleEmoji = '🤖';
  Color _capsuleColor = const Color(0xFF4C8CFA);
  String _capsuleSystemPrompt = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _api = ApiService(baseUrl: AppConfig.apiBaseUrl);
    _skills = SkillsService(baseUrl: AppConfig.apiBaseUrl);
    _perfilDb = PerfilDbService();

    await _memoryService.init_memory();
    await _emotionDetector.init();
    await _embeddingService.init_model();

    // Cargar identidad
    _userId = await _storage.read(key: 'user_id') ?? 'anon';
    _capsuleName = await _storage.read(key: 'selected_capsule_name') ?? 'Fénix';
    _capsuleEmoji = await _storage.read(key: 'selected_capsule_emoji') ?? '🤖';
    _capsuleSystemPrompt = await _storage.read(key: 'selected_capsule_system_prompt') ??
        'Eres Fénix, un asistente amigo personal servicial.';

    final accentStr = await _storage.read(key: 'selected_capsule_accent');
    if (accentStr != null) {
      final accentInt = int.tryParse(accentStr);
      if (accentInt != null) {
        _capsuleColor = Color(accentInt);
      }
    }

    setState(() {});
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
      // 1. Detectar cápsula dinámica (re-evalúa por si el usuario cambió de tema)
      final detectedCapsuleId = CapsuleDetector.detectar_capsula(text);

      // 2. Detectar emoción
      final emocion = await _emotionDetector.detectar_emocion(text);

      // 3. Cargar identidad EAV
      final identidad = await _perfilDb.obtenerEavComoMap() ?? {};
      final perfilStr = identidad.entries.map((e) => '${e.key}=${e.value}').join('\n');

      // 4. Búsqueda RAG local (top 3 chunks relevantes)
      List<String> ragResults = [];
      try {
        final queryVec = await _embeddingService.generar_vector(text);
        final topK = await _embeddingService.buscar_top_k(queryVec, k: 3);
        ragResults = topK.map((r) => '[${r['chapter']}] sim=${(r['similarity'] as double).toStringAsFixed(2)}').toList();
      } catch (e) {
        // Si falla el RAG, continuar sin él
      }

      // 5. Historial reciente (FIFO 8)
      _memoryService.agregar_mensaje_inmediato('user', text);
      final historial = _memoryService.obtener_memoria_inmediata();

      // 6. Armar payload snake_case (contrato exacto del backend)
      final payload = PayloadRequest(
        userId: _userId,
        mensajeActual: text,
        perfilIdentidad: perfilStr,  // STRING plano, no dict
        contextoRagHibrido: {
          'historial_usuario': '',  // Vacío por ahora (RAG lo gestiona RAG)
          'conocimiento_experto': ragResults.isEmpty
              ? 'Sin coincidencias en Nano-Obsidian local.'
              : ragResults.join('\n'),
        },
        capsulaActiva: {
          'id': detectedCapsuleId,
          'system_prompt': _capsuleSystemPrompt,
          'allowed_skills': const ['agenda_crear', 'notificacion_enviar', 'web_search', 'memoria_recordar', 'memoria_olvidar'],
        },
        activeSkills: const ['agenda_crear', 'notificacion_enviar'],
        historialReciente: historial,
      );

      // 7. POST /api/v1/chat + long-polling
      final response = await _api.enviar_mensaje_con_polling(payload);

      // 8. Procesar respuesta
      final assistantText = response['assistant_response'] ?? '(sin respuesta)';
      final perfilUpdate = (response['perfil_update'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final executedSkills = (response['executed_skills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final inferencedBy = response['inferenced_by'] ?? 'desconocido';

      // 9. Actualizar memoria inmediata
      _memoryService.agregar_mensaje_inmediato('assistant', assistantText);

      // 10. Persistir mutaciones EAV en SQLite local (Nivel 2)
      for (final upd in perfilUpdate) {
        await _perfilDb.upsertEav(
          upd['categoria']?.toString() ?? 'general',
          upd['clave']?.toString() ?? '',
          upd['valor']?.toString() ?? '',
        );
      }

      // 11. Mostrar mensaje en chat
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: assistantText,
          capsuleId: detectedCapsuleId,
          inferencedBy: inferencedBy,
        ));
        if (executedSkills.isNotEmpty) {
          final skillsInfo = executedSkills.map((s) => '⚡ ${s['skill_name']}').join(' • ');
          _messages.add(_ChatMessage(
            role: 'system',
            content: 'Skills ejecutadas: $skillsInfo',
          ));
        }
        if (perfilUpdate.isNotEmpty) {
          final updates = perfilUpdate.map((u) => '🧠 ${u['categoria']}.${u['clave']}=${u['valor']}').join('\n');
          _messages.add(_ChatMessage(
            role: 'system',
            content: 'Identidad EAV mutada:\n$updates',
          ));
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

  // Exponer apiBaseUrl al closure de error
  String get apiBaseUrl => AppConfig.apiBaseUrl;

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_capsuleEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              _capsuleName,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white54, size: 20),
            tooltip: 'Cambiar cápsula',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/capsules');
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4C8CFA))),
                  SizedBox(width: 12),
                  Text('Fénix está pensando...', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
            Text(_capsuleEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '$_capsuleName activo',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu bóveda Zero-Knowledge está sellada.\nHabla conmigo cuando quieras.',
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
                'ID: ${_userId.substring(0, 8)}...',
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
                color: _capsuleColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_capsuleEmoji, style: const TextStyle(fontSize: 16)),
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
                  Text(
                    msg.content,
                    style: TextStyle(color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                  ),
                  if (!isUser && msg.capsuleId != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '🧠 ${msg.capsuleId} • ${msg.inferencedBy ?? ""}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontFamily: 'monospace'),
                    ),
                  ],
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
                    hintText: 'Habla con $_capsuleName...',
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
                color: _capsuleColor,
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
  final String? inferencedBy;

  _ChatMessage({
    required this.role,
    required this.content,
    this.capsuleId,
    this.inferencedBy,
  });
}
