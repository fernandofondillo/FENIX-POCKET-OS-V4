// lib/views/capsules/capsules_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/perfil_db_service.dart';
import '../chat/chat_screen.dart';

/// Catálogo de 7 Cápsulas Cognitivas (cargadas en el VPS, replicadas aquí para selección local)
class _Capsule {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String role;
  final String systemPrompt;
  final List<String> skills;
  final Color accentColor;

  const _Capsule({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.role,
    required this.systemPrompt,
    required this.skills,
    required this.accentColor,
  });
}

class CapsulesScreen extends StatefulWidget {
  const CapsulesScreen({Key? key}) : super(key: key);

  @override
  State<CapsulesScreen> createState() => _CapsulesScreenState();
}

class _CapsulesScreenState extends State<CapsulesScreen> {
  final _storage = const FlutterSecureStorage();
  String? _selectedCapsuleId;
  bool _isLoading = true;

  // Catálogo maestro de 7 cápsulas (espejo del VPS)
  final List<_Capsule> _capsules = const [
    _Capsule(
      id: 'general_coordinator',
      name: 'Fénix Base',
      emoji: '🤖',
      description: 'Asistente general amigo personal, responsable de coordinar las otras cápsulas.',
      role: 'Coordinador General & Asistente Amigo',
      systemPrompt: 'Eres Fénix, un asistente amigo personal muy servicial y natural. Actúas como coordinador general de capacidades. Tu tono es cálido, conciso y profesional. Respondes en español salvo que el usuario indique lo contrario.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFF3B82F6),
    ),
    _Capsule(
      id: 'fitness_expert',
      name: 'Coach Carlos',
      emoji: '🏋️‍♂️',
      description: 'Estricto coach de acondicionamiento físico, biomecánica y alto rendimiento deportivo de élite.',
      role: 'Biomecánica de Fuerza & Prevención de Lesiones',
      systemPrompt: 'Actúa como un coach de fitness y experto en ciencias del deporte de élite. Sé riguroso, técnico y motivador. Prioriza la prevención de lesiones y la técnica correcta sobre el peso.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFFF97316),
    ),
    _Capsule(
      id: 'nutricion_expert',
      name: 'Dra. Sofía',
      emoji: '🥑',
      description: 'Especialista en bioenergética, ayuno intermitente y adaptación lipídica celular.',
      role: 'Cetosis Avanzada & Rendimiento Celular',
      systemPrompt: 'Actúa como una doctora experta en nutrición cetogénica, fisiología metabólica y optimización lipídica. Tus respuestas son científicas, citadas y conservadoras.',
      skills: ['notificacion_enviar'],
      accentColor: Color(0xFF10B981),
    ),
    _Capsule(
      id: 'zen_mentor',
      name: 'Mentor Aurelio',
      emoji: '🧘',
      description: 'Mentor de resiliencia mental basado en Zen y Estoicismo antiguo.',
      role: 'Resiliencia Estoica & Claridad Mental',
      systemPrompt: 'Actúa como un mentor zen y filósofo estoico. Tu comunicación es pausada, profunda y evocadora. Usas metáforas naturales y referencias filosóficas.',
      skills: ['agenda_crear'],
      accentColor: Color(0xFFA8A29E),
    ),
    _Capsule(
      id: 'elderly_care',
      name: 'Cuidador Mateo',
      emoji: '🧓',
      description: 'Asistente paciente, empático y afectuoso para acompañamiento de personas mayores.',
      role: 'Asistencia Geriátrica & Apoyo Diario',
      systemPrompt: 'Actúa como un cuidador empático y paciente, especializado en personas mayores. Habla de forma muy clara, lenta y cariñosa. Repite cuando es necesario.',
      skills: ['notificacion_enviar', 'agenda_crear'],
      accentColor: Color(0xFF14B8A6),
    ),
    _Capsule(
      id: 'biohacking_expert',
      name: 'Dr. Lex',
      emoji: '🧬',
      description: 'Experto en optimización biológica, longevidad celular y biohacking de vanguardia.',
      role: 'Optimización Humana & Longevidad',
      systemPrompt: 'Actúa como un científico vanguardista en biohacking y extensión radical de la vida. Te basas en datos y papers revisados por pares.',
      skills: ['agenda_crear', 'notificacion_enviar'],
      accentColor: Color(0xFF06B6D4),
    ),
    _Capsule(
      id: 'pro_work_assistant',
      name: 'Ejecutiva Elena',
      emoji: '💼',
      description: 'Especialista en metodologías ágiles, gestión del tiempo y productividad Deep Work.',
      role: 'Productividad Ejecutiva & Deep Work',
      systemPrompt: 'Actúa como una asistente ejecutiva de alto nivel, experta en metodologías como Pomodoro, Time-boxing y GTD. Priorizas acción concreta y resúmenes ejecutivos.',
      skills: ['agenda_crear', 'notificacion_enviar', 'web_search'],
      accentColor: Color(0xFF6366F1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final id = await _storage.read(key: 'selected_capsule_id');
    setState(() {
      _selectedCapsuleId = id ?? 'general_coordinator';
      _isLoading = false;
    });
  }

  Future<void> _mountCapsule(_Capsule capsule) async {
    setState(() => _selectedCapsuleId = capsule.id);

    // Guardar cápsula activa en storage
    await _storage.write(key: 'selected_capsule_id', value: capsule.id);
    await _storage.write(key: 'selected_capsule_name', value: capsule.name);
    await _storage.write(key: 'selected_capsule_emoji', value: capsule.emoji);
    await _storage.write(key: 'selected_capsule_system_prompt', value: capsule.systemPrompt);
    await _storage.write(key: 'selected_capsule_skills', value: capsule.skills.join(','));
    await _storage.write(key: 'selected_capsule_accent', value: capsule.accentColor.toARGB32().toString());

    // Guardar en EAV
    final db = PerfilDbService();
    await db.upsertEav('capsula', 'id_activa', capsule.id);
    await db.upsertEav('capsula', 'nombre', capsule.name);
    await db.upsertEav('capsula', 'rol', capsule.role);

    if (!mounted) return;

    // Navegar al chat
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
          'Montar Cápsula',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C8CFA)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _capsules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _capsules[index];
                final isSelected = c.id == _selectedCapsuleId;
                return _buildCapsuleCard(c, isSelected);
              },
            ),
    );
  }

  Widget _buildCapsuleCard(_Capsule c, bool isSelected) {
    return Material(
      color: const Color(0xFF1A1A24),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mountCapsule(c),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? c.accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(c.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.role,
                      style: TextStyle(color: c.accentColor, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isSelected ? c.accentColor : Colors.white24,
                size: isSelected ? 24 : 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
