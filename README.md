# Biomark AI

Plataforma integral de salud preventiva, comunitaria y telemedicina diseñada para la población nicaragüense, alineada con los protocolos y normativas técnicas del Ministerio de Salud (MINSA).

Biomark AI combina una aplicación cliente multiplataforma (móvil y web) desarrollada en **Flutter**, una pasarela de servicios (API Gateway) en **Node.js y Express**, un microservicio especializado de inteligencia artificial clínica en **Python y FastAPI**, persistencia segura con **Supabase** (PostgreSQL, autenticación y almacenamiento) y automatizaciones de salud pública mediante **n8n**.

---

## 1. Arquitectura del Sistema

La arquitectura está concebida de forma distribuida para optimizar el consumo de recursos, garantizar alta disponibilidad y proteger los datos clínicos:

```mermaid
flowchart TD
  subgraph Clientes ["Clientes Multiplataforma"]
    F["Flutter (Android, iOS y Web)"]
    Sensors["Sensores del Dispositivo (Cámara, Flash, Acelerómetro)"]
  end

  subgraph ServidorVPS ["Servidor VPS (Contabo)"]
    Nginx["Proxy Inverso Nginx (SSL / HTTPS)"]
    Backend["API Gateway Node.js :3000"]
    N8N["Motor de Automatización n8n :5678"]
  end

  subgraph InferenciaIA ["Servicio GPU Cloud (RunPod)"]
    FastAPI["AI Service FastAPI :8000"]
    Models["LLM Clínico, Whisper ASR y MMS-TTS"]
  end

  subgraph ServiciosCloud ["Servicios en la Nube"]
    DB[("Supabase DB / Auth / Storage")]
    FCM["Firebase Cloud Messaging (FCM)"]
  end

  F -->|HTTPS| Nginx
  Sensors -.->|Procesamiento DSP Local| F
  Nginx -->|Proxy Interno| Backend
  Backend -->|Consultas Seguras con RLS| DB
  Backend -->|X-Internal-Key| FastAPI
  FastAPI --> Models
  Backend -->|Eventos y Webhooks| N8N
  N8N -->|Notificaciones Push| FCM
  FCM -->|Alertas Sanitarias| F
```

---

## 2. Funcionalidades Principales

### Medición de Signos Vitales en el Dispositivo
* **Fotopletismografía óptica (PPG):** Estimación de la frecuencia cardíaca (BPM) en 20 segundos mediante la cámara y el flash LED del teléfono. Incorpora procesamiento digital de señales (DSP) en tiempo real con eliminación de derivas, control de contacto dérmico y clasificación clínica (ritmo normal, bradicardia o taquicardia).
* **Sismocardiografía (SCG):** Registro de micromovimientos torácicos derivados de la actividad mecánica cardíaca empleando el acelerómetro y giroscopio del móvil, con detección automática de perturbaciones de movimiento.

### Pautas de Salud MINSA y Priorización Inteligente
* **Catálogo normativo oficial:** Tarjetas informativas de prevención respaldadas por normativas del MINSA de Nicaragua:
  * Prevención y signos de alarma de dengue y arbovirosis (Normativa 004 del MINSA).
  * Hidratación y protección ante olas de calor extremo (temperaturas superiores a 30 °C).
  * Cuidado y monitoreo de la salud cardiovascular.
  * Cumplimiento y adherencia al tratamiento farmacológico prescrito.
  * Manejo preventivo de diabetes y metabolismo (Normativa 078 del MINSA).
  * Protocolo de salud respiratoria e infecciones estacionales (Normativa 028 del MINSA).
* **Motor de priorización contextual:** El sistema clasifica y ordena las recomendaciones automáticamente según:
  1. Alertas epidemiológicas activas en el municipio del usuario.
  2. Enfermedades crónicas declaradas en la encuesta clínica de salud.
  3. Signos vitales alterados registrados en mediciones recientes de pulso.
  4. Presencia de tratamientos farmacológicos continuos.
* **Gestión por roles (RBAC):** Promotores de salud y personal sanitario autorizado (`PROMOTOR`, `TRABAJADOR_SALUD`, `ADMIN`) disponen de un módulo de gestión para publicar y validar nuevas pautas sanitarias de acuerdo a los estándares oficiales.

### Asistente Clínico Multimodal y Seguro
* **Interacción integral:** Consultas mediante texto, mensajes de voz grabados y fotografías para orientación visual en piel o faringe.
* **Seguridad clínica estricta:** La inteligencia artificial está programada para **no prescribir medicamentos** ni emitir diagnósticos definitivos. Ofrece orientación preventiva, detección de señales de alerta y canalización oportuna a centros de salud.
* **Lenguaje accesible y sin tecnicismos:** Respuestas adaptadas para su comprensión inmediata por familias y comunidades rurales, evitando jerga médica compleja.

### Accesibilidad Universal (Estándares WCAG 2.1 AA)
* **Diseño opcional y no intrusivo:** No afecta la experiencia limpia del usuario general.
* **Tema de alto contraste:** Modo opcional con relación de contraste superior a 7:1 para personas con baja agudeza visual.
* **Compatibilidad con lectores de pantalla:** Integración completa de etiquetas de accesibilidad (`Semantics`) para TalkBack en Android y VoiceOver en iOS.
* **Sugerencia de modo por voz:** Tarjeta de acceso rápido por voz en la pantalla principal con opción de descarte inmediato y control en los ajustes del perfil.
* **Ergonomía táctil:** Áreas de interacción táctil con dimensiones mínimas de 48x48 dp para facilitar la pulsación.
* **Modo sin conexión (Offline-first):** Respaldo en caché local de recomendaciones y datos de consulta para áreas con conectividad inestable.

### Panorama Comunitario y Geolocalización Sanitaria
* Mapeo georreferenciado de centros de salud, puestos médicos y hospitales del MINSA.
* Visualización de jornadas de vacunación, abatización y fumigación en el sector.
* Registro del historial y evolución de síntomas (*Mejoró*, *Igual*, *Empeoró*).

### Gestión de Cuenta y Privacidad
* Autenticación segura mediante correo electrónico o inicio de sesión con Google.
* Gestión de perfil de usuario y avatar alojado en Supabase Storage.
* Encuesta clínica inicial de antecedentes personales y factores de riesgo.
* Eliminación definitiva y segura de cuenta con baja de datos en cascada mediante procedimientos almacenados.

---

## 3. Estructura del Repositorio

```text
Biomark-AI/
├── ai-service/              # Motor de inferencia en Python (FastAPI, PyTorch, Whisper, TTS)
├── backend/                 # API Gateway y servidor de lógica de negocio en Node.js y Express
├── database/                # Migraciones SQL, esquemas, funciones RPC y semillas para Supabase
├── deploy/                  # Plantillas de variables de entorno y configuraciones de despliegue
├── docs/                    # Especificaciones técnicas, contratos OpenAPI y guías operativas
├── frontend/flutter/        # Aplicación cliente multiplataforma (móvil y web) en Flutter
├── nginx/                   # Configuración del proxy inverso con soporte SSL y límites de tráfico
├── n8n/                     # Flujos de automatización para recordatorios y notificaciones push
├── docker-compose.yml       # Orquestación de servicios para entorno de desarrollo local
└── docker-compose.contabo.yml # Orquestación optimizada para servidor en producción (VPS Contabo)
```

---

## 4. Guía de Puesta en Marcha

### Requisitos Previos
* **Docker y Docker Compose** instalados en el entorno de ejecución.
* **Flutter SDK 3.24+** para compilar la aplicación cliente.
* **Node.js 20+** y **Python 3.10+** (para desarrollo local sin contenedores).
* Cuenta y proyecto configurado en **Supabase**.

### Configuración de Variables de Entorno
Copia los archivos de ejemplo en la carpeta `deploy/` y completa los valores correspondientes:

```bash
cp deploy/.env.example deploy/.env
cp deploy/backend.env.example deploy/backend.env
cp deploy/ai-service.env.example deploy/ai-service.env
```

### Ejecución en Entorno Local con Docker
Para iniciar todos los servicios auxiliares (backend, proxy y automatizaciones):

```bash
docker compose --env-file deploy/.env up -d --build
```

### Ejecución de la Aplicación Flutter
Para ejecutar la aplicación en un emulador, dispositivo físico o navegador web:

```bash
cd frontend/flutter
flutter pub get

# Ejecución en modo depuración (móvil o web)
flutter run -d chrome --dart-define=BIOMARK_API_URL=http://localhost:3000
```

---

## 5. Verificación y Pruebas del Sistema

El proyecto cuenta con suites de pruebas automatizadas en cada uno de sus niveles:

* **Pruebas del cliente Flutter:**
  ```bash
  cd frontend/flutter
  flutter test
  flutter analyze
  ```

* **Pruebas del backend (Node.js):**
  ```bash
  cd backend
  npm test
  ```

* **Pruebas del servicio de IA (Python):**
  ```bash
  cd ai-service
  TESTING=1 python3 -m unittest discover -s . -p "test_*.py"
  ```

---

## 6. Licencia y Cumplimiento Sanitario

Este proyecto ha sido desarrollado como una herramienta tecnológica de apoyo preventivo y educación comunitaria. No sustituye la consulta médica presencial ni los criterios clínicos emitidos por profesionales de la salud colegiados.
