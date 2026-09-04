// Pantalla de perfil de usuario — Biomark AI
import 'package:flutter/material.dart';

import 'biomark_brand.dart';
import 'main.dart'; // para poder cerrar sesión y volver a LoginScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Placeholder — luego se llenará con los datos reales del usuario
  // (mismo patrón que _nombreUsuario en home_screen.dart)
  static const String _nombreUsuario = 'Familia';
  static const String _correoUsuario = 'usuario@correo.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: BiomarkColors.black,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: BiomarkColors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildEncabezado(),
            const SizedBox(height: 24),
            _buildSeccion('Cuenta', [
              _ItemPerfil(
                icon: Icons.person_outline_rounded,
                label: 'Mis datos personales',
              ),
              _ItemPerfil(
                icon: Icons.family_restroom_rounded,
                label: 'Miembros de la familia',
              ),
              _ItemPerfil(
                icon: Icons.lock_outline_rounded,
                label: 'Seguridad y contraseña',
              ),
            ]),
            const SizedBox(height: 18),
            _buildSeccion('Preferencias', [
              _ItemPerfil(
                icon: Icons.notifications_none_rounded,
                label: 'Notificaciones',
              ),
              _ItemPerfil(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacidad y datos médicos',
              ),
              _ItemPerfil(icon: Icons.language_rounded, label: 'Idioma'),
            ]),
            const SizedBox(height: 18),
            _buildSeccion('Soporte', [
              _ItemPerfil(
                icon: Icons.help_outline_rounded,
                label: 'Centro de ayuda',
              ),
              _ItemPerfil(
                icon: Icons.info_outline_rounded,
                label: 'Acerca de Biomark AI',
              ),
            ]),
            const SizedBox(height: 28),
            _buildBotonCerrarSesion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            offset: Offset(-4, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BiomarkColors.blue.withValues(alpha: .12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: BiomarkColors.blue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  _nombreUsuario,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: BiomarkColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _correoUsuario,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7A7A85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A7A85)),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<_ItemPerfil> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A7A85),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final esUltimo = i == items.length - 1;
              return Column(
                children: [
                  _buildFila(items[i]),
                  if (!esUltimo)
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Color(0xFFEFEFF3),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFila(_ItemPerfil item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: BiomarkColors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: BiomarkColors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFBFBFC9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonCerrarSesion(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false, // limpia todo el stack de navegación
          );
        },
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 18,
        ),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ItemPerfil {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  _ItemPerfil({required this.icon, required this.label}) : onTap = null;
}
