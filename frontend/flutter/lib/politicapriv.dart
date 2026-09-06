// Pantalla "Política de privacidad" — Biomark AI
import 'package:flutter/material.dart';

class PoliticaPrivacidadScreen extends StatelessWidget {
  const PoliticaPrivacidadScreen({super.key});

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
          'Política de privacidad',
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
                'En Biomark AI nos tomamos en serio la privacidad de tu '
                'información médica. Este documento explica qué datos '
                'recopilamos, cómo los usamos y qué control tienes sobre '
                'ellos.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: tema.colorScheme.onSurface.withValues(alpha: .85),
                ),
              ),
            ),
            _buildSeccion(
              tema: tema,
              titulo: '1. Qué datos recopilamos',
              cuerpo:
                  'Recopilamos la información que nos das directamente al '
                  'usar Biomark AI:\n\n'
                  '• Datos de perfil y cuenta (nombre, correo, contraseña).\n'
                  '• Antecedentes médicos y encuestas de salud que tú '
                  'registras.\n'
                  '• Mensajes de texto y voz que envías al asistente de IA, '
                  'y fotos que subes para que la IA las identifique (por '
                  'ejemplo, una caja de medicamento).\n'
                  '• Ubicación aproximada, solo cuando la usas para buscar '
                  'centros o jornadas de salud cercanos.\n'
                  '• Datos técnicos básicos (modelo de dispositivo, versión '
                  'de la app) para mantener el servicio funcionando.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '2. Cómo usamos tus datos',
              cuerpo:
                  'Usamos tus datos para:\n\n'
                  '• Generar respuestas del asistente de IA personalizadas '
                  'a tu historial y encuestas de salud.\n'
                  '• Transcribir tu voz (ASR) y, si corresponde, leerte '
                  'respuestas en voz alta (TTS).\n'
                  '• Identificar medicamentos u otros elementos en fotos '
                  'que subes (reconocimiento de imágenes).\n'
                  '• Ubicar centros y jornadas de salud cercanos a ti cuando '
                  'activas la búsqueda por ubicación.\n'
                  '• Organizar tu historial médico. '
                  '• Enviarte recordatorios de medicamentos y citas.\n\n'
                  'No vendemos tus datos a terceros ni los usamos para '
                  'publicidad.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '3. Con quién compartimos información',
              cuerpo:
                  'Solo compartimos datos con proveedores que nos ayudan a '
                  'operar la app (por ejemplo, hosting, procesamiento de '
                  'IA o servicios de mapas para ubicar centros de salud), '
                  'bajo acuerdos de confidencialidad y únicamente en la '
                  'medida necesaria para prestar el servicio. '
                  'Esa información solo la ven '
                  'las personas que tú autorizas explícitamente dentro de '
                  'la app.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '4. Seguridad',
              cuerpo:
                  'Tus datos médicos, de voz e imágenes se almacenan '
                  'cifrados y el acceso está restringido a lo necesario '
                  'para operar el servicio. Puedes activar bloqueo '
                  'biométrico adicional desde Ajustes > Privacidad y datos '
                  'médicos para proteger el acceso desde tu dispositivo.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '5. Cuánto tiempo conservamos tus datos',
              cuerpo:
                  'Conservamos tu información mientras tu cuenta esté '
                  'activa. Si eliminas tu cuenta desde Ajustes > Privacidad '
                  'y datos médicos, borramos permanentemente tu perfil, '
                  'antecedentes médicos e historial de conversaciones, '
                  'salvo lo que estemos legalmente obligados a conservar '
                  'por un periodo adicional.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '6. Tus derechos',
              cuerpo:
                  'Tienes derecho a acceder, corregir o eliminar tus datos '
                  'personales y médicos. Desde Ajustes > Privacidad y datos '
                  '• Desactivar el uso de tus datos para personalizar la '
                  'IA.\n'
                  '• Eliminar tu cuenta y toda tu información de forma '
                  'permanente.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '7. Menores de edad',
              cuerpo:
                  'Biomark AI no está dirigida a niños que la usen por su '
                  'cuenta. Si registras antecedentes médicos de un hijo o '
                  'familiar menor de edad, lo haces como su tutor y bajo '
                  'tu responsabilidad.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '8. Cambios a esta política',
              cuerpo:
                  'Si actualizamos esta política de forma importante, te '
                  'avisaremos dentro de la app antes de que el cambio '
                  'entre en vigor.',
            ),
            _buildSeccion(
              tema: tema,
              titulo: '9. Contacto',
              cuerpo:
                  'Si tienes dudas sobre esta política o quieres ejercer '
                  'tus derechos sobre tus datos, escríbenos a '
                  'biomarkai2026@gmail.com',
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