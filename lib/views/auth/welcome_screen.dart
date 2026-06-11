// lib/views/auth/welcome_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_config.dart';
import '../../services/memory_service.dart';
import '../../services/perfil_db_service.dart';
import '../capsules/capsules_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _profesionController = TextEditingController();
  final _frecuenciaController = TextEditingController();
  final _metaController = TextEditingController();
  final _restriccionController = TextEditingController();

  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  final _memoryService = MemoryService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeMemory();
  }

  Future<void> _initializeMemory() async {
    try {
      await _memoryService.init_memory();
    } catch (e) {
      debugPrint('Error inicializando memoria: $e');
    }
  }

  Future<void> _iniciarEcosistema() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Generar UUID anónimo (Multi-Usuario Zero-Knowledge)
      final userId = _uuid.v4();
      await _storage.write(key: 'user_id', value: userId);
      await _storage.write(key: 'platform_id', value: AppConfig.platformId);
      await _storage.write(key: 'onboarding_complete', value: 'true');

      // 2. Generar Master Key AES-256 (almacenada en Secure Enclave del SO)
      final rand = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => rand.nextInt(256));
      final masterKey = base64UrlEncode(keyBytes);
      await _storage.write(key: 'master_key_aes256', value: masterKey);

      // 3. Serializar Identidad EAV (5 campos del CEO)
      final db = PerfilDbService();
      await db.initDb();
      await db.upsertEav('identidad', 'nombre_usuario', _nombreController.text.trim());
      await db.upsertEav('identidad', 'profesion_activa', _profesionController.text.trim());
      await db.upsertEav('identidad', 'frecuencia_entrenamiento', _frecuenciaController.text.trim());
      await db.upsertEav('identidad', 'meta_salud', _metaController.text.trim());
      await db.upsertEav('identidad', 'restriccion_biomecanica', _restriccionController.text.trim());

      // 4. Parámetros Fundamentales Cero
      await db.upsertEav('sistema', 'config_inicial', 'Activa');
      await db.upsertEav('sistema', 'fecha_onboarding', DateTime.now().toIso8601String());
      await db.upsertEav('sistema', 'capsula_activa_id', 'general_coordinator');
      await db.upsertEav('sistema', 'llm_model', AppConfig.llmModel);

      if (!mounted) return;

      // 5. Navegar al Marketplace de Cápsulas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CapsulesScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en forja criptográfica: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_moon_outlined, size: 64, color: Color(0xFF4C8CFA)),
                  const SizedBox(height: 16),
                  const Text(
                    'Fénix Pocket OS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bóveda Cero-Conocimiento',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                  _buildField(_nombreController, 'ID / Denominación', 'ej. Fernando'),
                  const SizedBox(height: 14),
                  _buildField(_profesionController, 'Rol / Profesión / Rutina', 'ej. Investigador'),
                  const SizedBox(height: 14),
                  _buildField(_frecuenciaController, 'Frecuencia de Entrenamiento', 'ej. 4 veces/semana'),
                  const SizedBox(height: 14),
                  _buildField(_metaController, 'Meta Principal de Salud', 'ej. Reducir grasa, mejorar sueño'),
                  const SizedBox(height: 14),
                  _buildField(_restriccionController, 'Restricción Biomecánica / Dolencias', 'ej. Lesión lumbar (opcional)'),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C8CFA)))
                      : ElevatedButton(
                          onPressed: _iniciarEcosistema,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C8CFA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'ENGRAVE SYSTEM.IO',
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4C8CFA))),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          // Solo nombre y profesión son bloqueantes
          if (label.contains('ID') || label.contains('Rol')) {
            return 'Requisito bloqueante';
          }
        }
        return null;
      },
    );
  }
}
