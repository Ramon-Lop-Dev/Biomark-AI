# Biomark AI — Cliente Móvil y Web (Flutter)

Aplicación multiplataforma (Android, iOS y Web) desarrollada con **Flutter 3.24+** y **Material Design 3**. Proporciona herramientas de salud preventiva, estimación de frecuencia cardíaca por sensores ópticos y mecánicos, pautas sanitarias basadas en normativas del MINSA, asistente de salud multimodal y gestión comunitaria.

---

## 1. Arquitectura del Proyecto (Feature-First)

La aplicación implementa una arquitectura orientada a características (**Feature-First**) desacoplada en tres capas principales por cada dominio: **Domain** (entidades y reglas), **Data** (repositorios, servicios y clientes HTTP/locales) y **Presentation** (pantallas, widgets y controladores de estado).

```text
lib/
├── core/                         # Utilidades y servicios transversales
│   ├── auth/                     # Gestión de sesión, tokens JWT y autenticación
│   ├── config/                   # Configuración de URLs de API y entornos
│   ├── design/                   # Controlador de temas (AppThemeController) y paleta corporativa
│   ├── notifications/            # Integración con Firebase Cloud Messaging (FCM)
│   └── profile/                  # Servicios transversales de perfil de usuario
│
├── features/                     # Módulos funcionales desacoplados
│   ├── vitals/                   # Medición y análisis de signos vitales
│   │   ├── domain/               # Modelos de pulso y mediciones (VitalMeasurement)
│   │   ├── data/                 # Almacenamiento local (VitalsStorage)
│   │   └── presentation/         # Procesador DSP (PpgProcessor, ScgProcessor) y pantallas
│   │
│   ├── home/                     # Pantalla de inicio y centro de mando
│   │   ├── domain/               # Entidad de recomendaciones (HealthRecommendation)
│   │   ├── data/                 # Motor de priorización contextual (RecommendationsService)
│   │   └── presentation/         # HomeScreen, carrusel de pautas y métricas comunitarias
│   │
│   ├── community/                # Gestión de salud comunitaria y pautas sanitarias
│   │   ├── recommendations_management_screen.dart # Formulario de publicación con RBAC
│   │   └── presentation/         # Listado epidemiológico y eventos de salud
│   │
│   ├── chat/                     # Asistente virtual de salud multimodal
│   │   ├── domain/               # Modelos de mensajes y estados de conversación
│   │   ├── data/                 # Clientes para chat, análisis visual y notas de voz
│   │   └── presentation/         # ChatScreen con reproductor de audio integrado
│   │
│   ├── progress/                 # Seguimiento de evolución clínica del paciente
│   │   ├── domain/               # Estados de evolución (MEJORO, IGUAL, EMPEORO, NO_SEGURO)
│   │   ├── data/                 # Cliente de persistencia y sincronización
│   │   └── presentation/         # Gráficas de evolución y correlación con pulso
│   │
│   ├── clinical/                 # Encuesta clínica inicial y antecedentes
│   │   ├── data/                 # Servicio de sincronización de antecedentes
│   │   └── presentation/         # Cuestionario clínico de factores de riesgo
│   │
│   ├── profile/                  # Administración del perfil y configuración
│   │   └── presentation/         # Edición de perfil, avatar, apariencia y baja de cuenta
│   │
│   ├── gis/                      # Mapeo georreferenciado de unidades de salud MINSA
│   └── reminders/                # Programación de medicamentos y citas médicas
│
├── app_shell.dart                # Estructura principal de navegación inferior accesible
├── biomark_brand.dart            # Paleta de colores, tipografías y temas (Claro, Oscuro, Alto Contraste)
└── main.dart                     # Inicialización de servicios y punto de arranque
```

---

## 2. Módulos y Capacidades Principales

### Medición de Signos Vitales (PPG y SCG)
* **Fotopletismografía óptica (PPG):**
  * Estimación de frecuencia cardíaca (BPM) a través de la cámara trasera y el flash.
  * Procesamiento digital de señales (DSP): validación de contacto en lecho capilar, eliminación de deriva continua (DC-tracking) y filtro paso-bajo para supresión de ruido.
  * Detección de sístoles con ventana refractaria fisiológica (40 a 180 BPM).
  * Clasificación clínica de resultados: Ritmo normal (60-100 BPM), Bradicardia (<60 BPM) y Taquicardia (>100 BPM).
* **Sismocardiografía mecánica (SCG):**
  * Detección de micromovimientos cardíacos en reposo utilizando el acelerómetro y giroscopio.
  * Filtro de rechazo para movimientos bruscos del usuario (motion artifacts).

### Recomendaciones de Salud MINSA y Priorización Inteligente
* **Estandarización visual y médica:** Las pautas incorporan colores e iconos normativos oficiales asignados a cada categoría sanitaria (Dengue, Golpe de Calor, Cardiovascular, Adherencia a Medicamentos, Diabetes y Salud Respiratoria).
* **Motor de cálculo de relevancia:** Ordena automáticamente las tarjetas en tiempo real combinando:
  1. Alertas sanitarias activas en el municipio del usuario (+10 pts).
  2. Padecimientos crónicos declarados en la encuesta clínica (+8 pts).
  3. Alteraciones en la última medición de pulso registrada (+7 pts).
  4. Indicación de tratamientos farmacológicos vigentes (+5 pts).
* **Gestión autorizada por roles (RBAC):** Interfaz para promotores y personal médico que permite publicar nuevas recomendaciones verificadas, validando el respaldo de normativas técnicas del MINSA.

### Accesibilidad Universal (WCAG 2.1 Nivel AA)
* **Tema de Alto Contraste:** Modo opcional con contraste superior a 7:1 en fondos, bordes y textos para usuarios con déficit visual.
* **Compatibilidad con lectores de pantalla:** Inclusión de etiquetas semánticas (`Semantics`) en botones, controles y tarjetas para TalkBack (Android) y VoiceOver (iOS), manteniendo total invisibilidad para usuarios estándar.
* **Sugerencia de modo por voz:** Notificación amigable en la pantalla de inicio para personas con baja alfabetización, con opción de cierre permanente (`[X]`) e interruptor en las preferencias de apariencia.
* **Ergonomía de pulsación:** Elementos interactivos con dimensiones mínimas de 48x48 dp para prevenir pulsaciones erróneas.
* **Resiliencia sin conexión:** Almacenamiento local mediante `SharedPreferences` para acceder a las pautas y datos vitales en puestos rurales sin cobertura de datos.

### Adaptabilidad Responsive (Móvil y Web)
* La interfaz se ajusta dinámicamente a pantallas de dispositivos móviles, tabletas y navegadores de escritorio.
* Se utilizan límites de ancho de lectura optimizados, evitando estiramientos visuales en pantallas panorámicas.

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

* **Cámara (`CAMERA`):** Requerida para la captura óptica del pulso capilar y registro de imágenes dermatológicas/orofaríngeas.
* **Linterna (`FLASHLIGHT`):** Necesaria para iluminar el dedo durante la medición PPG.
* **Micrófono (`RECORD_AUDIO`):** Empleado para enviar consultas de voz al asistente clínico.
* **Ubicación (`ACCESS_FINE_LOCATION`):** Utilizada únicamente con consentimiento del usuario para ordenar por proximidad los centros de salud del MINSA.
