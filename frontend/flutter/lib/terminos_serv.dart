// Pantalla "Términos de servicio" — Biomark AI
//
// Mismo patrón visual que politica_privacidad_screen.dart.
//
// TODO: reemplaza el texto de ejemplo con tus términos reales
// (revisados por alguien con criterio legal).
import 'package:flutter/material.dart';

class TerminosServicioScreen extends StatelessWidget {
  const TerminosServicioScreen({super.key});

  static const String _ultimaActualizacion = '5 de septiembre de 2026';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: tema.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: tema.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Términos de servicio',
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Última actualización: $_ultimaActualizacion',
              style: TextStyle(
                fontSize: 12,
                color: tema.colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 16),
            _buildTarjeta(
              tema: tema,
              child: Text(
                'Al usar Biomark AI aceptas estos términos. Léelos con '
                'atención, sobre todo la sección sobre el alcance de la '
                'IA como apoyo y no como reemplazo de atención médica '
                'profesional.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: tema.colorScheme.onSurface.withValues(alpha: .85),
                ),
              ),
            ),
            _buildSeccion(
              tema: tema,
              titulo: '1. Qué es Biomark AI',
              cuerpo:
                  'Biomark AI es un asistente de salud que ayuda a resolver '
                  'dudas sobre medicamentos de uso común, organizar '
                  'antecedentes médicos tuyos y de tu familia, identificar '
                  'medicamentos por foto o voz, ubicar centros y jornadas '
                  'de salud cercanos, y enviarte recordatorios. No '
                  'sustituye el diagnóstico ni el tratamiento de un '
                  'profesional de la salud: ante cualquier duda o '
                  'emergencia, consulta a tu médico o acude a un centro de '
                  'salud.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '2. Uso aceptable',
              cuerpo:
                  'Debes usar la app solo para fines personales y '
                  'legítimos. No puedes usarla para suplantar identidades, '
                  'compartir información médica de terceros sin su '
                  'consentimiento, subir contenido ilegal o dañino a través '
                  'de fotos, voz o texto, o intentar vulnerar la seguridad '
                  'del servicio.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '3. Cuentas de usuario y familiares',
              cuerpo:
                  'Eres responsable de mantener segura tu contraseña y de '
                  'toda actividad realizada desde tu cuenta. Si activas la '
                  'opción de compartir tu historial con familiares, eres '
                  'responsable de que esas personas tengan derecho a ver '
                  'esa información. Avísanos si sospechas un acceso no '
                  'autorizado.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '4. El rol de la inteligencia artificial',
              cuerpo:
                  'Las respuestas del asistente (por texto, voz o '
                  'identificación de imágenes) se generan automáticamente '
                  'y pueden contener errores o quedar desactualizadas. Es '
                  'información orientativa, no una consulta médica. '
                  'Biomark AI no se hace responsable de decisiones médicas '
                  'tomadas sin consultar a un profesional de la salud.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '5. Disponibilidad del servicio',
              cuerpo:
                  'Funciones como la búsqueda de centros de salud por '
                  'ubicación, el reconocimiento de voz o de imágenes '
                  'dependen de conexión a internet y de servicios de '
                  'terceros, por lo que pueden no estar disponibles en '
                  'todo momento o lugar.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '6. Cambios en el servicio',
              cuerpo:
                  'Podemos actualizar estos términos o modificar '
                  'funciones de la app. Te avisaremos de cambios '
                  'importantes dentro de la aplicación antes de que entren '
                  'en vigor.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '7. Cancelación',
              cuerpo:
                  'Puedes eliminar tu cuenta cuando quieras desde Ajustes > '
                  'Privacidad y datos médicos. Esto borra permanentemente '
                  'tu perfil, antecedentes e historial de conversaciones. '
                  'Nosotros también podemos suspender cuentas que '
                  'incumplan estos términos.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '8. Contacto',
              cuerpo:
                  'Para preguntas sobre estos términos, escríbenos a '
                  'soporte@biomark.ai.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion({
    required ThemeData tema,
    required String titulo,
    required String cuerpo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: tema.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildTarjeta(
            tema: tema,
            child: Text(
              cuerpo,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: tema.colorScheme.onSurface.withValues(alpha: .85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjeta({required ThemeData tema, required Widget child}) {
    final esOscuro = tema.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? .25 : .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}