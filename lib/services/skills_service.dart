// lib/services/skills_service.dart
import 'package:dio/dio.dart';
import '../core/app_config.dart';

class SkillsService {
  late final Dio _dio;
  final String baseUrl;

  SkillsService({this.baseUrl = AppConfig.apiBaseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: AppConfig.skillsTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.skillsTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
  }

  /// Ejecuta una skill nativa en el VPS
  Future<Map<String, dynamic>> executeSkill({
    required String skillName,
    required Map<String, dynamic> args,
    required String userId,
  }) async {
    try {
      final resp = await _dio.post('/api/v1/skills/execute', data: {
        'user_id': userId,
        'skill_name': skillName,
        'args': args,
      });
      return Map<String, dynamic>.from(resp.data);
    } on DioException catch (e) {
      throw Exception('Skill $skillName falló: ${e.response?.data ?? e.message}');
    }
  }
}
