# Biomark AI — Cliente Móvil y Web (Flutter)

Aplicación multiplataforma (Android, iOS y Web) desarrollada con **Flutter 3.24+** y **Material Design 3**. Proporciona herramientas de salud preventiva, estimación biomecánica de signos vitales mediante Sismocardiografía (SCG), pautas sanitarias basadas en normativas del MINSA, asistente de salud multimodal con motor offline autónomo y gestión comunitaria.

---

## 1. Arquitectura del Proyecto (Feature-First)

La aplicación implementa una arquitectura orientada a características (**Feature-First**) desacoplada en tres capas principales por cada dominio: **Domain** (entidades y reglas), **Data** (repositorios, servicios y clientes HTTP/locales) y **Presentation** (pantallas, widgets y controladores de estado).

```text
lib/
├── core/                         # Utilidades y servicios transversales
│   ├── auth/                     # Gestión de sesión, tokens JWT y autenticación
│   ├── config/                   # Configuración de URLs de API y entornos
│   ├── design/                   # BiomarkGlassSurface, temas claro/oscuro y alto contraste
│   ├── notifications/            # Integración con Firebase Cloud Messaging (FCM)
│   └── profile/                  # Servicios transversales de perfil de usuario
│
├── features/                     # Módulos funcionales desacoplados
│   ├── vitals/                   # Medición y análisis de signos vitales por SCG
│   │   ├── domain/               # Modelos de pulso y mediciones (VitalMeasurement)
│   │   ├── data/                 # Almacenamiento local (VitalsStorage)
│   │   └── presentation/         # Procesador biomecánico (ScgProcessor) y pantalla (ScgScreen)
│   │
│   ├── home/                     # Pantalla de inicio y centro de mando
│   │   ├── domain/               # Entidad de recomendaciones (HealthRecommendation)
│   │   ├── data/                 # Motor de priorización contextual (RecommendationsService)
│   │   └── presentation/         # HomeScreen con Glassmorphism y tarjetas interactivas
│   │
│   ├── community/                # Gestión de salud comunitaria y pautas sanitarias
│   │   ├── recommendations_management_screen.dart # Formulario de publicación con RBAC
│   │   └── presentation/         # Listado epidemiológico y eventos de salud
│   │
│   ├── chat/                     # Asistente virtual de salud multimodal
│   │   ├── domain/               # Modelos de mensajes y estados de conversación
│   │   ├── data/                 # MinsaOfflineKnowledge, OfflineChatEngine y clientes API
│   │   └── presentation/         # ChatScreen con seguimiento de síntomas (_FollowUpActionCard)
│   │
│   ├── progress/                 # Seguimiento de evolución clínica del paciente
│   │   ├── domain/               # Estados de evolución (MEJORO, IGUAL, EMPEORO, NO_SEGURO)
│   │   ├── data/                 # Cliente de persistencia y sincronización
│   │   └── presentation/         # Gráficas de evolución, metas e hitos de recuperación
│   │
│   ├── clinical/                 # Encuesta clínica inicial y antecedentes
│   │   ├── data/                 # Servicio de sincronización de antecedentes
│   │   └── presentation/         # Cuestionario clínico de factores de riesgo
│   │
│   ├── profile/                  # Administración del perfil y configuración
│   │   └── presentation/         # Edición de perfil, avatar, apariencia y baja de cuenta
│   │
│   ├── gis/                      # Mapeo georreferenciado con GPS de alta precisión y filtros
│   └── reminders/                # Programación de medicamentos y citas médicas
│
├── app_shell.dart                # Estructura principal de navegación inferior accesible
├── biomark_brand.dart            # Paleta de colores, tipografías y temas (Claro, Oscuro, Alto Contraste)
└── main.dart                     # Inicialización de servicios y punto de arranque
```

---

## 2. Módulos y Capacidades Principales

### Medición de Signos Vitales por Sismocardiografía (SCG)
* **Sismocardiografía Mecánica (SCG):**
  * Estimación de la frecuencia cardíaca (BPM) a partir de los micromovimientos transmitidos al esternón por la actividad cardíaca, empleando el acelerómetro y giroscopio del smartphone (`sensors_plus`).
  * Procesamiento digital de señales (DSP): filtrado pasabanda digital de 10 a 30 Hz para capturar los ruidos valvulares aórtico y mitral, minimizando componentes de respiración y movimiento.
  * Detección de picos sistólicos con umbral dinámico adaptativo y ventana refractaria mínima (250 ms) para evitar falsos positivos.
  * Compatibilidad con posturas clínicas: acostado boca arriba (supina) y sentado con compensación del vector gravitatorio.
  * Estimación de la calidad de señal (0% a 100%) y descarte automático ante perturbaciones corporales.
  * Clasificación clínica inmediata del ritmo cardíaco: Normal (60-100 BPM), Bradicardia (<60 BPM) o Taquicardia (>100 BPM).
  *(Nota: Se consolidó la sismocardiografía como método biométrico exclusivo, retirando la fotopletismografía óptica por cámara/flash).*

### Recomendaciones de Salud MINSA y Priorización Inteligente
* **Estandarización visual y médica:** Las pautas incorporan colores e iconos normativos oficiales asignados a cada categoría sanitaria (Dengue, Golpe de Calor, Cardiovascular, Adherencia a Medicamentos, Diabetes y Salud Respiratoria).
* **Motor de cálculo de relevancia:** Ordena automáticamente las tarjetas en tiempo real combinando:
  1. Alertas sanitarias activas en el municipio del usuario (+10 pts).
  2. Padecimientos crónicos declarados en la encuesta clínica (+8 pts).
  3. Alteraciones en la última medición de pulso registrada (+7 pts).
  4. Indicación de tratamientos farmacológicos vigentes (+5 pts).
* **Gestión autorizada por roles (RBAC):** Interfaz para promotores y personal médico que permite publicar nuevas recomendaciones verificadas, validando el respaldo de normativas técnicas del MINSA.

### Asistente Clínico Multimodal con Motor Offline Autónomo
* **Motor Clínico Offline (`OfflineChatEngine` y `MinsaOfflineKnowledge`):**
  * Base de conocimiento oficial en memoria del MINSA (Dengue 004/073, Diarrea 153, Neumonía/IRA 028, Diabetes/Hipertensión 078, Esquema PAI y Alerta Térmica >30°C).
  * Evaluador determinista de banderas rojas críticas (`CRITICAL`) y scoring semántico de síntomas.
  * Funciona de manera transparente cuando el dispositivo se queda sin conexión, sin mostrar errores de red.
* **Seguimiento Proactivo de Evolución de Síntomas:**
  * Tarjeta interactiva `_FollowUpActionCard` en el chat cuando el paciente describe mejoría o empeoramiento.
  * Opciones rápidas de un solo toque: *Mejoré*, *Sigo igual*, *Empeoré*, *No seguro* con guardado directo en el historial.

### Accesibilidad Universal y Glassmorphism (WCAG 2.1 AAA)
* **Diseño Glassmorphism Adaptativo (`BiomarkGlassSurface`):** Desenfoque gaussiano translúcido de fondo con bordes sutiles de 1.0 px, adaptados a modo claro y oscuro.
* **Tema de Alto Contraste:** Modo conmutado a superficies 100% opacas con bordes nítidos de 2.0 px y contraste superior a 7:1 en fondos y textos para usuarios con déficit visual (cumplimiento WCAG AAA).
* **Compatibilidad con lectores de pantalla:** Inclusión de etiquetas semánticas (`Semantics`) en botones, controles y tarjetas para TalkBack (Android) y VoiceOver (iOS).
* **Sugerencia de modo por voz:** Notificación amigable en la pantalla de inicio para personas con baja alfabetización, con opción de cierre permanente (`[X]`) e interruptor en las preferencias de apariencia.
* **Ergonomía de pulsación:** Elementos interactivos con dimensiones mínimas de 48x48 dp para prevenir pulsaciones erróneas.
* **Auditoría Antisolapamiento:** Widgets construidos con `LayoutBuilder` y restricciones flexibles para evitar desbordamientos `RenderFlex` en cualquier resolución de pantalla.

### Mapa GIS de Alta Precisión
* **Localización de Alta Exactitud:** Configuración `LocationAccuracy.high` para cálculo exacto de distancia geodésica.
* **Filtros por Nivel de Atención:** Chips rápidos de selección (*Todos*, *Hospitales*, *Centros de Salud*, *Puestos Médicos*).

---

## 3. Instrucciones de Ejecución

### Requisitos
* Flutter SDK versión 3.24 o superior.
* Navegador Google Chrome (para pruebas web) o dispositivo móvil con depuración USB activada.

### Variables de Compilación
La aplicación recibe la URL del servidor backend mediante `--dart-define`:

```bash
# Instalación de dependencias
flutter pub get

# Ejecución en navegador Web
flutter run -d chrome --dart-define=BIOMARK_API_URL=http://localhost:3000

# Ejecución en dispositivo móvil Android
flutter run -d <ID_DISPOSITIVO> --dart-define=BIOMARK_API_URL=https://tu-servidor-api.org
```

---

## 4. Pruebas y Control de Calidad

Ejecución de la suite de pruebas unitarias y de integración de widgets:

```bash
# Pruebas automatizadas de dominio, servicios y lógica matemática
flutter test

# Análisis estático de código y directrices de estilo
flutter analyze
```

---

## 5. Permisos Requeridos del Dispositivo

* **Sensores de Movimiento:** Utiliza el acelerómetro y giroscopio estándar del dispositivo para la sismocardiografía torácica (SCG).
* **Cámara (`CAMERA`):** Requerida exclusivamente para la captura voluntaria de imágenes de piel o faringe en el módulo de teleorientación visual.
* **Micrófono (`RECORD_AUDIO`):** Empleado para enviar consultas de voz al asistente clínico.
* **Ubicación (`ACCESS_FINE_LOCATION`):** Utilizada con consentimiento para ordenar por proximidad los centros de salud del MINSA y orientar hacia la unidad más cercana.
