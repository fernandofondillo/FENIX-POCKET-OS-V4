// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../models/payload_request.dart';
import '../core/app_config.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();

  ApiService({this.baseUrl = AppConfig.apiBaseUrl});

  /// Envía el payload al VPS y hace long-polling hasta recibir respuesta
  Future<Map<String, dynamic>> enviar_mensaje_con_polling(PayloadRequest payload) async {
    final url = Uri.parse('$baseUrl/api/v1/chat');
    final body = jsonEncode(payload.toJson());

    // 1. POST inicial → 202 + task_id
    final postResp = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: body,
    ).timeout(Duration(seconds: AppConfig.chatTimeoutSeconds));

    if (postResp.statusCode != 202) {
      throw Exception('POST falló con ${postResp.statusCode}: ${postResp.body}');
    }

    final taskData = jsonDecode(postResp.body) as Map<String, dynamic>;
    final taskId = taskData['task_id'] as String;
    print('📤 Task encolado: $taskId');

    // 2. Long-polling en /api/v1/task/{id}
    final pollUrl = Uri.parse('$baseUrl/api/v1/task/$taskId');
    final maxAttempts = (AppConfig.chatTimeoutSeconds * 1000) ~/ AppConfig.pollingIntervalMs;
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(Duration(milliseconds: AppConfig.pollingIntervalMs));
      attempts++;

      try {
        final pollResp = await _client.get(
          pollUrl,
          headers: {'ngrok-skip-browser-warning': 'true'},
        ).timeout(const Duration(seconds: 5));

        if (pollResp.statusCode == 200) {
          final data = jsonDecode(pollResp.body) as Map<String, dynamic>;
          print('✅ Task completada en $attempts intentos');
          return data;
        } else if (pollResp.statusCode == 202) {
          // Aún procesando
          continue;
        } else {
          throw Exception('Long-poll falló con ${pollResp.statusCode}: ${pollResp.body}');
        }
      } on TimeoutException {
        continue; // reintentar
      } catch (e) {
        if (attempts >= maxAttempts) rethrow;
      }
    }

    throw Exception('Timeout: VPS no respondió en ${AppConfig.chatTimeoutSeconds}s');
  }

  /// Health check
  Future<bool> health() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/health');
      final resp = await _client.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
