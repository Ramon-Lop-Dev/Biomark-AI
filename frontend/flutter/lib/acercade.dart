// Pantalla "Acerca de Biomark AI"
//
// Requiere el paquete url_launcher (pubspec.yaml):
//   url_launcher: ^6.3.0
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'biomark_brand.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  // TODO: si tienes flutter_package_info o similar, reemplaza esto con
  // la versión real del build en vez de un valor fijo.
  static const String _version = '1.0.0';
  static const String _sitioWeb = 'https://biomark-landing-p.vercel.app';

  Future<void> _abrirSitioWeb(BuildContext context) async {
    final uri = Uri.parse(_sitioWeb);
    final abierto =
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el enlace')),
      );
    }
  }

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
          'Acerca de Biomark AI',
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BiomarkColors.blue.withValues(alpha: .12),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/Icono.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'BIOMARK AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tema.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versión $_version',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: tema.colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            const SizedBox(height: 24),
            _buildTarjeta(
              tema: tema,
              child: Text(
                'BIOMARK AI es tu asistente de salud: te ayuda a resolver '
                'dudas sobre medicamentos de uso común, organiza tus '
                'antecedentes médicos y los de tu familia, y te acompaña '
                'con recordatorios para que no se te pase nada importante. '
                'La visita a tu médico sigue siendo lo más importante — '
                'nosotros solo te ayudamos a llegar más informado.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: tema.colorScheme.onSurface.withValues(alpha: .85),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _buildSeccionTitulo(tema, 'Qué puedes hacer con Biomark AI'),
            const SizedBox(height: 10),
            _buildTarjeta(
              tema: tema,
              child: Column(
                children: [
                  _buildCaracteristica(
                    tema: tema,
                    icono: Icons.forum_rounded,
                    texto: 'Conversar con la IA sobre tu salud y medicamentos',
                  ),
                  Divider(
                    height: 22,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildCaracteristica(
                    tema: tema,
                    icono: Icons.folder_shared_outlined,
                    texto: 'Guardar tus antecedentes médicos organizados',
                  ),
                  Divider(
                    height: 22,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildCaracteristica(
                    tema: tema,
                    icono: Icons.notifications_active_outlined,
                    texto: 'Recibir recordatorios de medicamentos y citas',
                  ),
                  Divider(
                    height: 22,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildCaracteristica(
                    tema: tema,
                    icono: Icons.map_outlined,
                    texto: 'Ubicar centros y jornadas de salud cercanos',
                  ),
                  Divider(
                    height: 22,
                    color: tema.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  _buildCaracteristica(
                    tema: tema,
                    icono: Icons.lock_outline_rounded,
                    texto: 'Mantener tus datos cifrados y privados',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirSitioWeb(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Visitar nuestro sitio web'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BiomarkColors.blue,
                  side: const BorderSide(color: BiomarkColors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '© 2026 Biomark AI. Todos los derechos reservados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: tema.colorScheme.onSurface.withValues(alpha: .4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaracteristica({
    required ThemeData tema,
    required IconData icono,
    required String texto,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BiomarkColors.green.withValues(alpha: .12),
          ),
          child: Icon(icono, size: 15, color: BiomarkColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tema.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionTitulo(ThemeData tema, String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: tema.colorScheme.onSurface.withValues(alpha: .6),
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
