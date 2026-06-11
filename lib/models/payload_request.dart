// lib/models/payload_request.dart
/// Modelo del payload snake_case EXACTO que espera el VPS A.G.O.S.
/// Coincide 1:1 con `app/schemas/chat_schema.py` en backend.
class PayloadRequest {
  final String userId;
  final String mensajeActual;
  final String perfilIdentidad;        // STRING plano: "clave1=valor1\nclave2=valor2"
  final Map<String, String> contextoRagHibrido;  // {historial_usuario, conocimiento_experto}
  final Map<String, dynamic> capsulaActiva;     // {id, system_prompt, allowed_skills}
  final List<String> activeSkills;
  final List<Map<String, String>> historialReciente;

  PayloadRequest({
    required this.userId,
    required this.mensajeActual,
    required this.perfilIdentidad,
    required this.contextoRagHibrido,
    required this.capsulaActiva,
    required this.activeSkills,
    required this.historialReciente,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'mensaje_actual': mensajeActual,
        'perfil_identidad': perfilIdentidad,
        'contexto_rag_hibrido': contextoRagHibrido,
        'capsula_activa': capsulaActiva,
        'active_skills': activeSkills,
        'historial_reciente': historialReciente,
      };
}
