# Biomark AI — Frontend Móvil & Web (Flutter)

Aplicación móvil y web multiplataforma desarrollada en Flutter para la asistencia en salud preventiva, seguimiento de síntomas, fotopletismografía óptica (PPG) y salud comunitaria orientada a la población nicaragüense y normativas del MINSA.

---

## 1. Arquitectura del Proyecto (Feature-First)

El frontend está estructurado bajo una arquitectura orientada a características (**Feature-First**) y principios de **Clean Architecture**:

```text
lib/
├── core/                         # Capas transversales del sistema
│   ├── auth/                     # Sesión, JWT, helpers de Google Auth y listeners
│   ├── config/                   # Configuración de URLs de API y Firebase
│   ├── design/                   # Controladores de tema (claro/oscuro), paleta Clay
│   ├── notifications/            # Servicio de notificaciones push (FCM)
│   └── profile/                  # API de perfil de usuario
├── features/                     # Módulos funcionales desacoplados
│   ├── vitals/                   # Fotopletismografía (PPG) con cámara del teléfono
│   │   ├── domain/               # Modelos de signos vitales (VitalMeasurement)
│   │   ├── data/                 # Persistencia local (VitalsStorage SharedPreferences)
│   │   └── presentation/         # DSP en tiempo real (PpgProcessor) y pantalla (PpgScreen)
│   ├── home/                     # Pantalla de inicio modernizada
│   │   ├── domain/               # Modelos de recomendaciones (HealthRecommendation)
│   │   ├── data/                 # Motor de pautas MINSA (RecommendationsService)
│   │   └── presentation/         # HomeScreen con signos vitales, acciones rápidas y MINSA
│   ├── chat/                     # Asistente clínico multimodal
│   │   ├── domain/               # Modelos de mensajes y estados
│   │   ├── data/                 # Chat API, Vision API y Voice API
│   │   └── presentation/         # ChatScreen con reproductor de voz estilo WhatsApp
│   ├── progress/                 # Seguimiento de evolución clínica y metas
│   │   ├── domain/               # Estados MEJORO, IGUAL, EMPEORO, NO_SEGURO
│   │   ├── data/                 # ProgressApi y registro de auditoría
│   │   └── presentation/         # ProgressScreen integrado con pulso PPG
│   ├── clinical/                 # Encuesta clínica inicial e historial médico
│   │   ├── data/                 # SurveyService y sincronización
│   │   └── presentation/         # HealthSurveyScreen y AntecedentesScreen
│   ├── profile/                  # Gestión de perfil y configuración
│   │   └── presentation/         # ProfileScreen, EditarPerfil, Seguridad, etc.
│   ├── auth/                     # Registro, recuperación y pantalla de carga
│   │   └── presentation/         # RegisterScreen, ForgotPassword, LoadingScreen
│   ├── reminders/                # Recordatorios de medicamentos y vacunas
│   ├── gis/                      # Mapa inteligente de centros de salud y riesgo
│   └── community/                # Panel para promotores y eventos comunitarios
├── main.dart                     # Punto de entrada de la aplicación
└── biomark_brand.dart            # Paleta corporativa (BiomarkColors) y temas M3
```

---

## 2. Módulos Destacados

### 💓 Fotopletismografía Óptica (PPG - Pulso Cardíaco con Cámara)
- **Principio:** Detección de variaciones del volumen sanguíneo capilar mediante la cámara trasera y el flash LED del smartphone.
- **Procesamiento de señal (DSP):**
  - Validación de contacto dérmico (`avgRed > 95`) para ignorar luz ambiental.
  - Eliminación de componente continua (DC-tracking) y filtro paso-bajo IIR contra ruido de sensor.
  - Detección de sístoles con período refractario fisiológico (330 ms a 1500 ms = 40 a 180 BPM).
  - Mediana móvil para estabilidad en la lectura de BPM.
- **Experiencia de Usuario:**
  - Anillo con cuenta regresiva de 20 segundos.
  - Corazón con animación de latido sincronizado a las pulsaciones detectadas.
  - Gráfico de onda PPG estilo monitor hospitalario en tiempo real (`CustomPainter`).
  - Clasificación clínica: Ritmo normal (60-100 BPM), Bradicardia (<60 BPM) o Taquicardia (>100 BPM).
  - Persistencia automática e integración con la pantalla de **Mi Mejoría**.

### 📋 Pantalla de Inicio (HomeScreen)
- **Tarjeta de Signos Vitales (PPG):** Acceso directo y visualización de la última frecuencia cardíaca registrada.
- **Panel de Acciones Rápidas (Quick Actions Grid):** Acceso en 1 toque a *Consultar IA*, *Mi Mejoría*, *Medir Pulso* y *Centros MINSA*.
- **Módulo de Recomendaciones de Salud MINSA:** Tarjetas informativas adaptadas a la realidad nicaragüense:
  1. **Prevención de Dengue y Arbovirosis:** Normativa 004 del MINSA, eliminación de criaderos y signos de alarma.
  2. **Hidratación y Golpe de Calor:** Pautas de reposición hídrica en temperaturas superiores a 30°C (Pacífico y Centro).
  3. **Salud Cardiovascular y Pulso:** Rangos en reposo y factores que alteran el ritmo cardíaco.
  4. **Adherencia Farmacológica:** Importancia de no suspender dosis ni modificar prescripciones médicas.
- **Panorama Comunitario:** Resumen de casos validados por zona, señales y próximas jornadas de vacunación/fumigación.

### 🎙️ Chat Multimodal con Audio Estilo WhatsApp
- Mensajes de voz enviados con grabación de micrófono y procesados por Whisper ASR.
- Respuestas de voz sintetizadas con MMS TTS reproducibles con control de progreso, botón de reproducción/pausa y visualización en burbuja de audio.
- Integración del contexto clínico completo (encuesta de salud, enfermedades previas, medicamentos activos).

---

## 3. Pruebas y Verificación de Calidad

Para ejecutar la suite completa de pruebas unitarias:

```bash
flutter test
```

Verificación de sintaxis y buenas prácticas con el analizador de Dart:

```bash
flutter analyze
```

---

## 4. Permisos del Dispositivo

- **Android (`AndroidManifest.xml`):**
  - `CAMERA`: Para la medición PPG y captura de imágenes para análisis dermatológico/orofaríngeo.
  - `FLASHLIGHT`: Para iluminar el lecho capilar durante la medición PPG.
  - `RECORD_AUDIO`: Para consultas de voz con el asistente.
  - `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`: Para sugerir centros de salud cercanos.
- **iOS (`Info.plist`):**
  - `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`.
