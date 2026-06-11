// lib/core/app_config.dart
/// Configuración central de URLs de Fénix Pocket OS V4
class AppConfig {
  /// URL del backend FastAPI (VPS A.G.O.S.) expuesto vía ngrok
  /// Esta URL se mantiene activa mientras el VPS reporte túnel ngrok abierto.
  /// En producción real con dominio propio, cambiar a HTTPS.
  static const String apiBaseUrl = 'https://roguish-degradedly-anjelica.ngrok-free.dev';

  /// Versión del contrato de payload
  static const String apiVersion = 'v1';

  /// Identificador único de plataforma
  static const String platformId = 'fenix_pocket_os_v4';

  /// Modelo LLM que escucha el VPS
  static const String llmModel = 'Qwen2.5-7B-Instruct-Q4_K_M';

  /// Timeouts (en segundos)
  static const int chatTimeoutSeconds = 45;
  static const int pollingIntervalMs = 800;
  static const int skillsTimeoutSeconds = 30;

  /// Tamaños máximos de payload
  static const int maxHistoryMessages = 8;
  static const int maxRagContextChars = 400;
  static const int maxIdentityChars = 800;
}
