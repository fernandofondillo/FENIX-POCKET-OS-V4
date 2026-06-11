# 🐦‍🔥 Fénix Pocket OS v4.1.0

> **El agente de inteligencia soberana en tu bolsillo.**
> La interfaz efímera entre tu psique digital y la soberana persistencia local.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![Tests](https://img.shields.io/badge/tests-100%25_green-success)](#)
[![License](https://img.shields.io/badge/license-MIT-blue)](#)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue?logo=apple)](#)
[![Android](https://img.shields.io/badge/Android-6.0%2B-green?logo=android)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?logo=flutter)](#)
[![VPS](https://img.shields.io/badge/VPS-A.G.O.S.-orange)](#)

---

## 📋 Tabla de Contenidos

1. [¿Qué es Fénix Pocket OS?](#-qué-es-fénix-pocket-os)
2. [Filosofía: Soberanía Total del Móvil](#-filosofía-soberanía-total-del-móvil)
3. [Arquitectura del Sistema](#-arquitectura-del-sistema)
4. [Las 7 Cápsulas Cognitivas](#-las-7-cápsulas-cognitivas)
5. [Memoria Jerárquica (3 Niveles)](#-memoria-jerárquica-3-niveles)
6. [Sistema de Skills Nativas](#-sistema-de-skills-nativas)
7. [Stack Técnico](#-stack-técnico)
8. [Estructura del Proyecto](#-estructura-del-proyecto)
9. [Instalación y Despliegue](#-instalación-y-despliegue)
10. [Backend VPS (A.G.O.S.)](#-backend-vps-agos)
11. [Flujo de un Mensaje (End-to-End)](#-flujo-de-un-mensaje-end-to-end)
12. [Contrato de la API](#-contrato-de-la-api)
13. [Seguridad y Cifrado](#-seguridad-y-cifrado)
14. [Testing y Verificación E2E](#-testing-y-verificación-e2e)
15. [Multi-Tenant y Privacidad](#-multi-tenant-y-privacidad)
16. [Roadmap](#-roadmap)
17. [Licencia](#-licencia)

---

## 🐦‍🔥 ¿Qué es Fénix Pocket OS?

**Fénix Pocket OS** es un sistema operativo personal de inteligencia artificial que se instala en tu móvil (Android o iOS) y convierte tu dispositivo en un **oráculo ciego**: sabe mucho de ti, pero solo tú tienes acceso a esa información.

A diferencia de los asistentes comerciales (Siri, Alexa, Google Assistant), Fénix:

- ❌ **NO** envía tus datos a la nube para entrenar modelos
- ❌ **NO** perfila tu comportamiento para venderte publicidad
- ❌ **NO** comparte nada con terceros
- ❌ **NO** requiere cuenta, email ni teléfono
- ✅ **TODO** (memorias, identidad, historial, cápsulas) vive cifrado en tu móvil
- ✅ **Solo** envía el mensaje actual a un LLM local (Qwen 7B en tu VPS) para generar respuesta
- ✅ **El VPS no recuerda nada** después de cada conversación (stateless)

### Casos de uso

- 🏋️ **Entrenamiento personalizado** (Coach Carlos — biomecánica)
- 🥑 **Nutrición cetogénica** (Dra. Sofía — bioenergética)
- 🧘 **Resiliencia mental** (Mentor Aurelio — estoicismo zen)
- 🧓 **Acompañamiento de personas mayores** (Cuidador Mateo)
- 🧬 **Biohacking y longevidad** (Dr. Lex)
- 💼 **Productividad ejecutiva** (Ejecutiva Elena)
- 🤖 **Coordinación general** (Fénix Base — orquestador)

---

## 🔐 Filosofía: Soberanía Total del Móvil

En la era masiva del almacenamiento en la nube y la monetización agresiva del comportamiento algorítmico individual, **Fénix Pocket OS** emerge como una declaración de **independencia táctica** y **soberanía local extrema**.

### La Promesa

> *Tu servidor no recuerda, no archiva y no analiza quién eres. Fénix es un oráculo ciego.*

**Lo que SÍ es soberano en el móvil del usuario** (nunca sale de tu dispositivo):

| Componente | Ubicación física | Cifrado |
|---|---|---|
| **Identidad del usuario** (UUID + perfil EAV) | SQLite local + Secure Storage | AES-256 |
| **Memoria inmediata** (últimos 8 mensajes) | RAM del proceso | — |
| **Memoria consolidada** (hechos, preferencias) | SQLite local | AES-256 |
| **Cápsulas activas** (qué especializadas tienes) | Secure Storage (Keychain/Keystore) | Hardware-backed |
| **Historial completo de chat** | SQLite local | AES-256 |
| **Emociones detectadas** | Memoria inmediata | — |
| **Vector RAG local** (embeddings de mensajes) | SQLite + archivos binarios | Plano local |
| **Configuración personal** (frecuencia, meta, salud) | SQLite | AES-256 |

**Lo ÚNICO que sale del móvil** (en cada mensaje):

1. El `mensaje_actual` (texto que escribiste)
2. `user_id` (UUID anónimo v4, NO PII)
3. `perfil_identidad` (formato texto denso, sin nombre real)
4. `contexto_rag_hibrido` (resumen textual, no datos crudos)
5. `historial_reciente` (últimos 8 mensajes, FIFO)

**Lo que ENTRA al móvil** (respuesta del VPS):

1. `assistant_response` (texto de la cápsula)
2. `perfil_update` (mutaciones EAV: "ahora sé que te gusta X")
3. `executed_skills` (skills que se ejecutaron)

**Después, el VPS OLVIDA TODO.** ❌ No persiste nada.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    MÓVIL DEL USUARIO                         │
│                  (SOBERANO, NO TOCABLE)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────┐             │
│  │  CAPA DE PRESENTACIÓN (Flutter UI)          │             │
│  │  • WelcomeScreen (onboarding 5 campos)      │             │
│  │  • CapsulesScreen (7 cápsulas + switches)   │             │
│  │  • ChatScreen (cápsula activa dinámica)     │             │
│  └────────────────────────────────────────────┘             │
│                          ▼                                   │
│  ┌────────────────────────────────────────────┐             │
│  │  CAPA DE LÓGICA (Servicios Flutter)         │             │
│  │  • ApiService → POST al VPS                 │             │
│  │  • CapsuleDetector → elige cápsula          │             │
│  │  • EmotionDetector → analiza sentimiento    │             │
│  │  • MemoryService → gestión memoria          │             │
│  │  • LocalEmbeddingService → RAG local        │             │
│  │  • PerfilDbService → SQLite EAV             │             │
│  │  • SecureStorageService → Keychain/Keystore │             │
│  │  • PushService → notificaciones locales     │             │
│  │  • SkillsService → ejecución skills         │             │
│  └────────────────────────────────────────────┘             │
│                          ▼                                   │
│  ┌────────────────────────────────────────────┐             │
│  │  CAPA DE DATOS LOCALES (SOBERANA)          │             │
│  │                                              │             │
│  │  📦 SQLite (4 bases de datos):              │             │
│  │    • perfil.db     → identidad EAV         │             │
│  │    • chat.db       → historial completo     │             │
│  │    • memoria.db    → hechos consolidados    │             │
│  │    • embedding.db  → vectores RAG           │             │
│  │                                              │             │
│  │  🔐 Secure Storage (Keychain/Keystore):     │             │
│  │    • user_id (UUID v4)                       │             │
│  │    • active_capsule_ids                      │             │
│  │    • encryption_key (AES-256)                │             │
│  │    • selected_capsule_*                      │             │
│  │                                              │             │
│  │  🔒 Todo cifrado AES-256 en reposo          │             │
│  │  🔒 Hardware-backed Keychain (iOS)          │             │
│  │  🔒 Android Keystore + EncryptedSharedPrefs │             │
│  └────────────────────────────────────────────┘             │
│                          │                                   │
│                          │ HTTPS (TLS 1.3)                   │
│                          │ Payload ~2 KB por mensaje         │
│                          ▼                                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                 VPS A.G.O.S. (STATELESS)                     │
│              (NO GUARDA NADA DEL USUARIO)                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────┐             │
│  │  FastAPI Event-Driven (:8000)               │             │
│  │  • POST /api/v1/chat                       │             │
│  │  • GET  /api/v1/task/{id} (long-polling)    │             │
│  │  • POST /api/v1/consolidate (nocturno)      │             │
│  │  • POST /api/v1/skills/execute             │             │
│  │  • GET  /api/v1/health                     │             │
│  └────────────────────────────────────────────┘             │
│                          ▼                                   │
│  ┌────────────────────────────────────────────┐             │
│  │  ORQUESTADOR (CapsuleDetector Python)       │             │
│  │  • Detecta cápsula objetivo                 │             │
│  │  • Enriquece con system_prompt              │             │
│  │  • Prepara contexto RAG híbrido             │             │
│  │  • Selecciona skills permitidas             │             │
│  └────────────────────────────────────────────┘             │
│                          ▼                                   │
│  ┌────────────────────────────────────────────┐             │
│  │  QWEN 2.5 7B Q4_K_M (llama-server :8090)   │             │
│  │  • Modelo cuantizado (4.36 GB en RAM)       │             │
│  │  • Stateless: cada request es independiente │             │
│  │  • NO aprende de tus datos                  │             │
│  │  • NO guarda conversaciones                  │             │
│  │  • temperature=0.3, top_p=0.9, max=300      │             │
│  └────────────────────────────────────────────┘             │
│                                                              │
│  ❌ NO base de datos de usuarios                              │
│  ❌ NO logs persistentes de conversaciones                    │
│  ❌ NO entrenamiento con datos de usuario                     │
│  ✅ Solo Redis (caché de tareas, TTL 5 min)                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧠 Las 7 Cápsulas Cognitivas

Fénix Pocket OS implementa un **sistema multi-agente** donde cada cápsula es un especialista con personalidad, conocimiento y skills propias. **Fénix Base** es el orquestador siempre activo; las demás se activan dinámicamente según el tema de la conversación.

| ID | Cápsula | Emoji | Rol | Se activa con | Skills |
|----|---------|-------|-----|---------------|--------|
| `general_coordinator` | **Fénix Base** | 🤖 | Coordinador general & orquestador | SIEMPRE activo | agenda, notif |
| `fitness_expert` | **Coach Carlos** | 🏋️‍♂️ | Biomecánica de fuerza | ejercicio, peso, dolor, postura | agenda, notif |
| `nutricion_expert` | **Dra. Sofía** | 🥑 | Cetosis & bioenergética | dieta, comida, ayuno, grasa | notif |
| `zen_mentor` | **Mentor Aurelio** | 🧘 | Estoicismo zen & resiliencia | ansiedad, estrés, reflexión, propósito | agenda |
| `elderly_care` | **Cuidador Mateo** | 🧓 | Asistencia geriátrica empática | pastillas, médico, familia, acompañamiento | notif, agenda |
| `biohacking_expert` | **Dr. Lex** | 🧬 | Biohacking & longevidad | sueño, suplementos, nootrópicos, glucosa | agenda, notif |
| `pro_work_assistant` | **Ejecutiva Elena** | 💼 | Productividad & Deep Work | tareas, agenda, email, reunión, foco | agenda, notif, web |

### Detección Dinámica

**El usuario NO necesita seleccionar cápsula manualmente.** El sistema detecta y cambia automáticamente:

1. Usuario escribe: *"me duele la espalda haciendo sentadillas"*
2. `CapsuleDetector.detectar_capsula()` → analiza keywords → `fitness_expert`
3. `ChatScreen` cambia el HUD: avatar del AppBar pasa de 🤖 a 🏋️
4. Banner aparece: *"🤖 Fénix Base orquestó → 🏋️ Coach Carlos"*
5. Qwen 7B genera respuesta con system_prompt de fitness
6. Si la cápsula objetivo está **desactivada** por el usuario, Fénix Base responde como fallback

---

## 💾 Memoria Jerárquica (3 Niveles)

Fénix implementa un sistema de memoria inspirado en cognición humana:

### Nivel 1: Memoria Inmediata (RAM)
- **Capacidad**: últimos 8 mensajes (FIFO)
- **Persistencia**: solo durante la sesión
- **Uso**: mantener contexto conversacional activo
- **Almacenamiento**: lista circular en `MemoryService`

### Nivel 2: Memoria Consolidada (SQLite)
- **Capacidad**: hechos consolidados por categoría (EAV)
- **Persistencia**: permanente, cifrada AES-256
- **Uso**: identidad del usuario (preferencias, salud, metas, restricciones)
- **Almacenamiento**: tabla `perfil` con esquema EAV (Entity-Attribute-Value)

### Nivel 3: Memoria Episódica (RAG Local)
- **Capacidad**: embeddings de conversaciones pasadas
- **Persistencia**: permanente, vectores en `embedding.db`
- **Uso**: búsqueda semántica de recuerdos relevantes
- **Algoritmo**: top-K cosine similarity con modelo local

### Flujo de Consolidación

```
Usuario escribe mensaje
    ↓
Memoria inmediata (Nivel 1) ← siempre presente
    ↓
Backend procesa → devuelve perfil_update
    ↓
Memoria consolidada (Nivel 2) ← persistida local
    ↓
[Noche] Consolidación batch → genera embeddings
    ↓
Memoria episódica (Nivel 3) ← RAG futuro
```

---

## ⚡ Sistema de Skills Nativas

Las **skills** son acciones que las cápsulas pueden ejecutar. Viven en el backend (VPS) y se invocan vía API:

| Skill ID | Descripción | Cápsulas que la usan |
|----------|-------------|----------------------|
| `agenda_crear` | Crear evento en calendario del usuario | Fénix Base, Coach Carlos, Mentor Aurelio, Dr. Lex, Ejecutiva Elena |
| `notificacion_enviar` | Enviar push notification local | Fénix Base, Coach Carlos, Dra. Sofía, Dr. Lex, Ejecutiva Elena |
| `web_search` | Búsqueda web (DuckDuckGo/Brave) | Ejecutiva Elena |
| `memoria_recordar` | Guardar hecho explícito en perfil EAV | Todas (orquestador) |
| `memoria_olvidar` | Eliminar hecho del perfil (GDPR-like) | Todas (orquestador) |

**Ejecución**:
1. Qwen genera respuesta con tag JSON: `{"skill": "agenda_crear", "params": {...}}`
2. Backend parsea y ejecuta la skill
3. Resultado se incluye en `executed_skills` de la respuesta
4. Móvil muestra notificación al usuario

---

## 🛠️ Stack Técnico

### Frontend (Móvil)
- **Flutter 3.44.1** (estable, soporte multiplataforma)
- **Dart 3.5.4** (null-safety, async/await, isolates)
- **Provider/Riverpod** (gestión de estado)
- **HTTP/Dio** (cliente REST)
- **sqflite** (SQLite local)
- **flutter_secure_storage** (Keychain/Keystore)
- **encrypt** (AES-256)
- **uuid** (UUID v4 anónimo)
- **logger** (logging estructurado)

### Backend (VPS)
- **Python 3.12** + **FastAPI** (event-driven, async)
- **llama-cpp-python** + **llama-server** (Qwen 7B inference)
- **Redis 7** (caché de tareas, TTL 5 min)
- **Pydantic v2** (validación de schemas)
- **uvicorn** (ASGI server)
- **ngrok** (túnel HTTPS público para dev)

### Modelo de Lenguaje
- **Qwen 2.5 7B Instruct** cuantizado **Q4_K_M** (4.36 GB RAM)
- **Parámetros de inference**: `temperature=0.3, top_p=0.9, max_tokens=300, parallel=1`
- **Compilado con**: llama.cpp (Metal GPU en Mac, CUDA en Linux, CPU fallback)

### DevOps
- **GitHub Actions** (CI/CD)
  - `build-android.yml` → compila APK con Flutter
  - `build-ios.yml` → compila IPA en Mac runner (Xcode 15.4, iOS SDK 17.5)
- **Android SDK 35** + **build-tools 35/34/33** + **NDK**
- **JDK 17** (compilación Gradle)
- **Java 21** (runtime, opcional)

---

## 📁 Estructura del Proyecto

```
fenix-pocket-os/
├── lib/                              # Código Flutter
│   ├── main.dart                     # Entry point + wire-up de servicios
│   ├── core/
│   │   └── app_config.dart          # URL base, feature flags
│   ├── models/
│   │   └── payload_request.dart     # Contrato snake_case del backend
│   ├── services/                     # Lógica de negocio
│   │   ├── api_service.dart         # Cliente REST + long-polling
│   │   ├── capsule_detector.dart    # Detección dinámica de cápsula
│   │   ├── emotion_detector.dart    # Análisis emocional local
│   │   ├── local_embedding_service.dart  # RAG local
│   │   ├── memory_service.dart      # Memoria inmediata + consolidada
│   │   ├── perfil_db_service.dart   # SQLite EAV
│   │   ├── push_service.dart        # Notificaciones locales
│   │   ├── secure_storage_service.dart  # Keychain/Keystore
│   │   └── skills_service.dart      # Ejecución de skills
│   └── views/                        # UI Flutter
│       ├── auth/
│       │   └── welcome_screen.dart  # Onboarding 5 campos
│       ├── capsules/
│       │   └── capsules_screen.dart # Catálogo + switches
│       └── chat/
│           └── chat_screen.dart     # Chat principal con cápsula activa
│
├── app/                              # Backend FastAPI
│   ├── main.py                       # Entry point
│   ├── api/
│   │   ├── chat_router.py           # POST /api/v1/chat
│   │   ├── task_router.py           # GET /api/v1/task/{id}
│   │   ├── consolidate_router.py    # POST /api/v1/consolidate
│   │   └── skills_router.py         # POST /api/v1/skills/execute
│   ├── services/
│   │   ├── inference_router.py      # Cliente llama-server
│   │   ├── capsule_detector.py      # Orquestador de cápsulas
│   │   ├── skill_catalogue.py       # Catálogo de 5 skills
│   │   └── memory_consolidator.py   # Consolidación batch
│   └── schemas/
│       └── chat_schema.py           # Pydantic v2
│
├── ios/                              # Proyecto iOS nativo
│   ├── Runner.xcodeproj/
│   ├── Runner/                       # AppDelegate, SceneDelegate
│   └── Info.plist
│
├── android/                          # Proyecto Android nativo
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   └── gradle/
│
├── test/                             # Tests Flutter
│   ├── widget_test.dart
│   └── services/
│
├── assets/                           # Recursos estáticos
│   ├── images/
│   └── data/
│
├── .github/workflows/
│   ├── build-android.yml
│   └── build-ios.yml
│
├── pubspec.yaml                      # Dependencias Dart
├── analysis_options.yaml             # Lints
└── README.md                         # Este archivo
```

---

## 🚀 Instalación y Despliegue

### Pre-requisitos
- Flutter SDK 3.44.1+
- Dart 3.5.4+
- Android SDK 35 (para Android)
- Xcode 15.4+ (para iOS, solo en macOS)
- JDK 17
- ngrok CLI (para exponer backend en dev)

### Compilar APK Android

```bash
# 1. Clonar
git clone https://github.com/fernandofondillo/FENIX-POCKET-OS-V4.git
cd FENIX-POCKET-OS-V4

# 2. Instalar dependencias
flutter pub get

# 3. Compilar APK release
export PATH="/opt/flutter/bin:$PATH"
export ANDROID_HOME=/opt/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk (~50 MB)
```

### Compilar IPA iOS

**Opción A: GitHub Actions (recomendado)**

1. Push a `main` → workflow `.github/workflows/build-ios.yml` se dispara manualmente
2. Descargar artifact `fenix-pocket-os-ios-unsigned` (válido 7 días)

**Opción B: Local (solo macOS)**

```bash
flutter build ios --release --no-codesign \
  --build-name=4.1.0 \
  --build-number=41

# Empaquetar como .ipa
mkdir -p Payload
cp -R build/ios/iphoneos/Runner.app Payload/
zip -r fenix-pocket-os-unsigned.ipa Payload

# Output: fenix-pocket-os-unsigned.ipa (~7 MB)
```

### Instalar en dispositivo

**Android**: copiar APK al móvil → habilitar "Orígenes desconocidos" → abrir APK

**iOS** (sin cuenta Developer):
1. Instalar **Sideloadly** desde https://sideloadly.io en tu Mac
2. Conectar iPhone por USB
3. Arrastrar el `.ipa` a Sideloadly
4. Introducir Apple ID personal
5. Generar **contraseña específica de app** en https://appleid.apple.com
6. Pulsar "Start" → esperar 30s
7. En iPhone: `Ajustes > General > VPN y gestión de dispositivos > Confiar`
8. Activar **Modo Desarrollador** en `Ajustes > Privacidad y seguridad`

---

## 🖥️ Backend VPS (A.G.O.S.)

**A.G.O.S.** = *Asynchronous Generative Orchestration System*

Es el cerebro stateless que ejecuta Qwen 7B y orquesta las cápsulas. **NO guarda nada del usuario**.

### Levantar el backend

```bash
# 1. Instalar dependencias Python
cd app/
pip install -r requirements.txt

# 2. Levantar Qwen 7B con llama-server
llama-server -m qwen2.5-7b-instruct-q4_k_m.gguf \
  --host 0.0.0.0 --port 8090 \
  -c 2048 -t 8

# 3. Levantar FastAPI
uvicorn main:app --host 0.0.0.0 --port 8000

# 4. Exponer con ngrok (dev)
ngrok http 8000
# Output: https://xxxx.ngrok-free.dev
```

### Health Check

```bash
curl https://your-ngrok-url.ngrok-free.dev/api/v1/health
```

Respuesta:
```json
{
  "status": "healthy",
  "capsules": 7,
  "skills": 5,
  "llama_cpp": "ok",
  "redis": "ok"
}
```

---

## 🔄 Flujo de un Mensaje (End-to-End)

**Ejemplo**: Usuario escribe *"me duele la espalda haciendo sentadillas"*

```
1. USUARIO (móvil) escribe mensaje
   ↓
2. MÓVIL procesa LOCALMENTE:
   - CapsuleDetector.detectar_capsula() → "fitness_expert" 🏋️
   - EmotionDetector.detectar_emocion() → "preocupado"
   - MemoryService.obtener_historial() → últimos 8 mensajes
   - LocalEmbeddingService.buscar_top_k() → 3 chunks similares
   - PerfilDbService.obtenerEav() → identidad textual densa
   ↓
3. MÓVIL envía al VPS (HTTPS, ~2 KB):
   {
     "user_id": "a3f8b2c1-9d4e-4a2b-bf3c-1234567890ab",
     "mensaje_actual": "me duele la espalda haciendo sentadillas",
     "perfil_identidad": "edad=35\nsexo=masculino\nfrecuencia=3/semana\nmeta=fuerza\nrestriccion=lumbar_previo",
     "contexto_rag_hibrido": {
       "historial_usuario": "...",
       "conocimiento_experto": "[biomecanica_squat] sim=0.87..."
     },
     "capsula_activa": {
       "id": "fitness_expert",
       "system_prompt": "Actúa como un coach de fitness...",
       "allowed_skills": ["agenda_crear", "notificacion_enviar"]
     },
     "active_skills": ["agenda_crear", "notificacion_enviar"],
     "historial_reciente": ["msg1", "msg2", ...]
   }
   ↓
4. VPS (Qwen 7B) procesa:
   - Recibe el contexto
   - Genera respuesta con system_prompt de fitness
   - Calcula mutaciones EAV (ej: "restriccion = dolor_lumbar_activo")
   ↓
5. VPS responde al MÓVIL (~1 KB):
   {
     "assistant_response": "El dolor lumbar en sentadillas suele indicar...",
     "perfil_update": [
       {"categoria": "salud", "clave": "dolor_activo", "valor": "lumbar"},
       {"categoria": "entrenamiento", "clave": "biomecanica_issue", "valor": "valgo_rodilla"}
     ],
     "executed_skills": [],
     "inferenced_by": "qwen2.5"
   }
   ↓
6. VPS OLVIDA TODO. ❌ No guarda nada.
   ↓
7. MÓVIL persiste LOCALMENTE:
   - Guarda mensaje en chat.db
   - Aplica mutaciones EAV en perfil.db
   - Actualiza memoria inmediata
   - Genera embedding para RAG futuro
   ↓
8. MÓVIL muestra respuesta al usuario con avatar de Coach Carlos 🏋️
```

**Total de datos que cruzan la frontera del móvil**: ~2 KB
**Total de datos que quedan en el VPS después**: 0 bytes

---

## 📡 Contrato de la API

### POST /api/v1/chat

**Request** (snake_case estricto):

```json
{
  "user_id": "string (UUID v4)",
  "mensaje_actual": "string (texto del usuario)",
  "perfil_identidad": "string (perfil textual denso, NO objeto)",
  "contexto_rag_hibrido": {
    "historial_usuario": "string",
    "conocimiento_experto": "string"
  },
  "capsula_activa": {
    "id": "string (fitness_expert, zen_mentor, ...)",
    "system_prompt": "string",
    "allowed_skills": ["string"]
  },
  "active_skills": ["string"],
  "historial_reciente": ["string"]
}
```

**Response 200 OK**:

```json
{
  "task_id": "string (UUID)",
  "status": "completed",
  "assistant_response": "string",
  "perfil_update": [
    {
      "categoria": "string",
      "clave": "string",
      "valor": "string"
    }
  ],
  "executed_skills": [
    {
      "skill_name": "string",
      "params": {},
      "result": {}
    }
  ],
  "inferenced_by": "qwen2.5"
}
```

### GET /api/v1/task/{task_id}

**Long-polling** (800ms / max 30s) para respuestas asíncronas.

### POST /api/v1/consolidate

Consolidación batch nocturna de memorias.

### POST /api/v1/skills/execute

Ejecutar skill manualmente (testing/admin).

### GET /api/v1/health

```json
{
  "status": "healthy",
  "capsules": 7,
  "skills": 5,
  "llama_cpp": "ok",
  "redis": "ok"
}
```

---

## 🔒 Seguridad y Cifrado

### En Reposo (datos en móvil)

| Plataforma | Mecanismo | Detalle |
|---|---|---|
| **iOS** | Keychain (hardware-backed) | Cifrado AES con clave derivada del Secure Enclave |
| **Android** | EncryptedSharedPreferences + Keystore | AES-256 GCM con clave en Android Keystore |
| **SQLite** | Cifrado a nivel de aplicación | AES-256 CBC con clave del Keychain/Keystore |

### En Tránsito (red)

- **TLS 1.3** (HTTPS obligatorio)
- **ngrok** con TLS termination (dev)
- **Certificados válidos** (Let's Encrypt en producción)

### En el VPS

- **Sin PII** (Personal Identifiable Information)
- **UUID v4 anónimo** como única identificación
- **Stateless**: cada request es independiente
- **Redis con TTL 5 min** (caché de inference, expira automáticamente)
- **Sin logs persistentes** de conversaciones

---

## 🧪 Testing y Verificación E2E

### Test E2E (verificado en VPS)

```python
import urllib.request, json

url = 'https://your-ngrok-url.ngrok-free.dev/api/v1/chat'
payload = {
  "user_id": "test-uuid-a3f8b2c1",
  "mensaje_actual": "me duele la espalda haciendo sentadillas",
  "perfil_identidad": "edad=35\nmeta=fuerza",
  "contexto_rag_hibrido": {"historial_usuario": "", "conocimiento_experto": ""},
  "capsula_activa": {
    "id": "fitness_expert",
    "system_prompt": "Actúa como coach de fitness",
    "allowed_skills": ["agenda_crear"]
  },
  "active_skills": ["agenda_crear"],
  "historial_reciente": []
}

req = urllib.request.Request(url, data=json.dumps(payload).encode(),
  headers={'Content-Type': 'application/json'})
resp = json.loads(urllib.request.urlopen(req).read())
print(resp['assistant_response'])
```

**Output verificado** (latencia 42.3s primera vez, 8-12s después):
> *"El dolor lumbar durante sentadillas es una señal común de..."
> ... [respuesta técnica de ~280 palabras sobre biomecánica]*

### Flutter Tests

```bash
flutter test
# Output: All tests passed!
```

---

## 👥 Multi-Tenant y Privacidad

### Aislamiento por UUID

- Cada usuario genera su `user_id` localmente al onboarding
- **NO hay registro**, **NO hay login**, **NO hay verificación**
- El VPS solo ve el UUID, no sabe nombre/email/teléfono
- Diferentes usuarios en el mismo VPS están completamente aislados

### Sin PII (Personal Identifiable Information)

**Lo que NO se pide nunca**:
- ❌ Nombre real
- ❌ Email
- ❌ Teléfono
- ❌ Dirección
- ❌ Fecha de nacimiento exacta (solo rango etario en EAV)

**Lo que se pide en onboarding** (5 campos):
- ID local (UUID auto-generado)
- Frecuencia de entrenamiento
- Meta de salud
- Restricción biomecánica (opcional)

### GDPR-like: Derecho al Olvido

- **Borrar cuenta**: desinstalar la app → todos los datos locales se eliminan
- **Olvidar hecho específico**: usar skill `memoria_olvidar` o pedir a Fénix
- **VPS no retiene nada**: no hay nada que borrar en el servidor

---

## 🗺️ Roadmap

### ✅ v4.1.0 (Actual)
- 7 cápsulas cognitivas con detección dinámica
- 5 skills nativas
- Onboarding 5 campos
- Chat con cápsula activa + HUD dinámico
- APK Android 49 MB + IPA iOS 6.9 MB
- Backend A.G.O.S. con Qwen 7B
- Multi-tenant stateless
- Cifrado AES-256 en reposo

### 🚧 v4.2.0 (Próximo)
- Skills de calendario real (Google Calendar, Apple Calendar)
- Push notifications con FCM/APNs
- Exportar/importar perfil cifrado (migración de dispositivo)
- Modo offline con respuestas encoladas
- Telemetría anónima opcional (opt-in)

### 🔮 v5.0 (Futuro)
- Fine-tuning de Qwen con datos del usuario (local, on-device)
- Voice input/output (Whisper local + TTS)
- Multi-modal (visión con LLaVA local)
- Sincronización E2E entre dispositivos del mismo usuario
- Marketplace de cápsulas de terceros (verificadas)

---

## 📄 Licencia

MIT License

Copyright (c) 2026 Fernando Rueda (QUYRIUX)

Se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia de este software y de los archivos de documentación asociados (el "Software"), a utilizar el Software sin restricción, incluyendo sin limitación los derechos de uso, copia, modificación, fusión, publicación, distribución, sublicencia y/o venta de copias del Software, y a permitir a las personas a las que se les proporcione el Software a hacer lo mismo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en todas las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA...

---

## 🤝 Contribuciones

Este es un proyecto personal de Fernando Rueda. Para sugerencias o reportar issues:
- **GitHub**: https://github.com/fernandofondillo/FENIX-POCKET-OS-V4/issues
- **Telegram**: @fernando_fundillo

---

## 🙏 Agradecimientos

- **Qwen Team** (Alibaba) por el modelo base open-source
- **llama.cpp** por el inference engine
- **Flutter** por el framework multiplataforma
- **FastAPI** por el backend asíncrono
- **ngrok** por el túnel HTTPS en desarrollo

---

<div align="center">

**🐦‍🔥 Fénix Pocket OS — Tu soberano digital.**

*Hecho con 🔥 en España, para el mundo.*

</div>
