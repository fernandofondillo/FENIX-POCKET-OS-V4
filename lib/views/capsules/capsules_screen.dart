// lib/views/capsules/capsules_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/perfil_db_service.dart';
import '../chat/chat_screen.dart';

/// Pantalla de ACTIVACIÓN/INVENTARIO de cápsulas.
/// El usuario SIEMPRE arranca con Fénix Base (general_coordinator) como
/// orquestador. Esta pantalla es para que el usuario vea y active las
/// cápsulas especializadas (fitness, nutrición, zen, etc.) que el
/// sistema usará DINÁMICAMENTE cuando detecte su tema.
///
/// El sistema detecta y cambia de cápsula automáticamente en cada mensaje.
/// El usuario no necesita seleccionar manualmente.
class CapsulesScreen extends StatefulWidget {
  const CapsulesScreen({Key? key}) : super(key: key);

  @override
  State<CapsulesScreen> createState() => _CapsulesScreenState();
}

class _CapsulesScreenState extends State<CapsulesScreen> {
  final _storage = const FlutterSecureStorage();
  Set<String> _activeCapsuleIds = {'general_coordinator'};
  bool _isLoading = true;

  // Catálogo maestro de 7 cápsulas
  final List<_Capsule> _capsules = const [
    _Capsule(
      id: 'general_coordinator',
      name: 'Fénix Base',
      emoji: '🤖',
      description: 'Coordinador general SIEMPRE activo. Orquesta las demás cápsulas.',
      role: 'Coordinador General & Orquestador',
      systemPrompt: 'Eres Fénix, un asistente amigo personal muy servicial y natural. Actúas como coordinador general de capacidades. Tu tono es cálido, conciso y profesional.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFF3B82F6),
      isBase: true,
    ),
    _Capsule(
      id: 'fitness_expert',
      name: 'Coach Carlos',
      emoji: '🏋️‍♂️',
      description: 'Biomecánica de fuerza y alto rendimiento. Se activa con: ejercicio, peso, dolor muscular, postura.',
      role: 'Biomecánica de Fuerza',
      systemPrompt: 'Actúa como un coach de fitness y experto en ciencias del deporte de élite. Sé riguroso, técnico y motivador.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFFF97316),
    ),
    _Capsule(
      id: 'nutricion_expert',
      name: 'Dra. Sofía',
      emoji: '🥑',
      description: 'Nutrición cetogénica y bioenergética. Se activa con: dieta, comida, ayuno, grasa, metabolismo.',
      role: 'Cetosis & Nutrición',
      systemPrompt: 'Actúa como una doctora experta en nutrición cetogénica, fisiología metabólica y optimización lipídica.',
      skills: ['notificacion_enviar'],
      accentColor: Color(0xFF10B981),
    ),
    _Capsule(
      id: 'zen_mentor',
      name: 'Mentor Aurelio',
      emoji: '🧘',
      description: 'Resiliencia mental y filosofía estoica. Se activa con: ansiedad, estrés, reflexión, propósito.',
      role: 'Filosofía Estoica',
      systemPrompt: 'Actúa como un mentor zen y filósofo estoico. Tu comunicación es pausada, profunda y evocadora.',
      skills: ['agenda_crear'],
      accentColor: Color(0xFFA8A29E),
    ),
    _Capsule(
      id: 'elderly_care',
      name: 'Cuidador Mateo',
      emoji: '🧓',
      description: 'Apoyo geriátrico empático. Se activa con: pastillas, médico, familia, acompañamiento.',
      role: 'Asistencia Geriátrica',
      systemPrompt: 'Actúa como un cuidador empático y paciente, especializado en personas mayores.',
      skills: ['notificacion_enviar', 'agenda_crear'],
      accentColor: Color(0xFF14B8A6),
    ),
    _Capsule(
      id: 'biohacking_expert',
      name: 'Dr. Lex',
      emoji: '🧬',
      description: 'Biohacking y longevidad celular. Se activa con: sueño, suplementos, nootrópicos, glucosa.',
      role: 'Optimización Biológica',
      systemPrompt: 'Actúa como un científico vanguardista en biohacking y extensión radical de la vida.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFF06B6D4),
    ),
    _Capsule(
      id: 'pro_work_assistant',
      name: 'Ejecutiva Elena',
      emoji: '💼',
      description: 'Productividad ejecutiva y Deep Work. Se activa con: tareas, agenda, email, reunión, foco.',
      role: 'Productividad & Deep Work',
      systemPrompt: 'Actúa como una asistente ejecutiva de alto nivel, experta en metodologías como Pomodoro, Time-boxing y GTD.',
      skills: ['agenda_crear', 'notificacion_enviar', 'web_search'],
      accentColor: Color(0xFF6366F1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final stored = await _storage.read(key: 'active_capsule_ids');
    if (stored != null && stored.isNotEmpty) {
      _activeCapsuleIds = stored.split(',').toSet();
    } else {
      // Por defecto, todas activadas
      _activeCapsuleIds = _capsules.map((c) => c.id).toSet();
      await _storage.write(
        key: 'active_capsule_ids',
        value: _activeCapsuleIds.join(','),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleCapsule(_Capsule capsule) async {
    if (capsule.isBase) return; // Fénix Base no se puede desactivar
    setState(() {
      if (_activeCapsuleIds.contains(capsule.id)) {
        _activeCapsuleIds.remove(capsule.id);
      } else {
        _activeCapsuleIds.add(capsule.id);
      }
    });
    await _storage.write(
      key: 'active_capsule_ids',
      value: _activeCapsuleIds.join(','),
    );

    // Persistir en EAV
    final db = PerfilDbService();
    await db.upsertEav('capsulas', 'activas_ids', _activeCapsuleIds.join(','));
  }

  Future<void> _enterChat() async {
    // Fénix Base SIEMPRE activo
    _activeCapsuleIds.add('general_coordinator');
    await _storage.write(
      key: 'active_capsule_ids',
      value: _activeCapsuleIds.join(','),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        title: const Text(
          'Cápsulas Activas',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C8CFA)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Fénix Base (🤖) orquesta y enruta. Activa las demás y se activarán solas según el tema.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _capsules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = _capsules[index];
                      final isActive = _activeCapsuleIds.contains(c.id);
                      return _buildCapsuleCard(c, isActive);
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enterChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C8CFA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'ENTRAR AL CHAT',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCapsuleCard(_Capsule c, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? c.accentColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentColor.withValues(alpha: isActive ? 0.2 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (c.isBase) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BASE',
                          style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (c.isBase)
            const Icon(Icons.lock, color: Colors.white24, size: 16)
          else
            Switch(
              value: isActive,
              onChanged: (_) => _toggleCapsule(c),
              activeThumbColor: c.accentColor,
            ),
        ],
      ),
    );
  }
}

class _Capsule {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String role;
  final String systemPrompt;
  final List<String> skills;
  final Color accentColor;
  final bool isBase;

  const _Capsule({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.role,
    required this.systemPrompt,
    required this.skills,
    required this.accentColor,
    this.isBase = false,
  });
}
