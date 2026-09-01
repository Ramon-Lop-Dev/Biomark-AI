# Frontend Flutter

El frontend debe apuntar al dominio HTTPS del nginx, no a `localhost`, ngrok ni a los puertos internos Docker. Configura la URL por ambiente (desarrollo, staging, producción) y no incluyas claves service role.

Registra el token FCM en `POST /api/users/push-token` después de obtener consentimiento de notificaciones. Envía `session_id` UUID para conservar memoria de chat y solicita ubicación solo con consentimiento explícito.

Prueba en dispositivo real contra el VPS: login, chat, voz, mapa inteligente, navegación, vacunas, recordatorios y recepción de push.

## Chat conectado

El chat Flutter llama únicamente al backend público (`POST /api/chat`). El backend valida el JWT y comunica internamente con `ai-service`; nunca configures `AI_SERVICE_INTERNAL_KEY` en Flutter.

Ejecuta la app con la URL HTTPS del backend y el access token obtenido en `POST /api/auth/login`:

```bash
cd frontend/flutter
flutter run -d RMX3741 \
	--dart-define=BIOMARK_API_URL=https://api.tu-dominio.ni \
	--dart-define=BIOMARK_ACCESS_TOKEN=TU_ACCESS_TOKEN
```

En un teléfono físico no uses `localhost`: debe ser el dominio HTTPS publicado por nginx. La primera respuesta crea `session_id`; las siguientes solicitudes de la misma pantalla lo reutilizan para conservar el contexto.

## Arquitectura Flutter

El frontend se organiza por features y responsabilidades:

```text
lib/
├── core/
│   └── design/                 # Material 3 y superficies claymorphism
├── features/
│   └── chat/
│       ├── data/               # Cliente HTTP y DTOs de respuesta
│       ├── domain/             # Entidades del negocio del chat
│       └── presentation/      # ChatScreen y widgets de interfaz
├── biomark_brand.dart          # Paleta y ThemeData corporativo
└── home_screen.dart            # Shell de navegación y composición
```

Cada nueva capacidad debe seguir el mismo límite: `data` para APIs, `domain` para clases y reglas de negocio, `presentation` para widgets/pantallas y `core` solo para componentes compartidos. Las pantallas deben usar Material 3 y `BiomarkClaySurface` para superficies con claymorphism; los colores deben salir de `BiomarkColors` o del `ColorScheme`.

El chat modular se encuentra en `features/chat/presentation/chat_screen.dart` y se comunica con `features/chat/data/chat_api.dart`. No llames al `ai-service` desde Flutter.
