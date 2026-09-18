import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_biomark/core/design/app_themecontroller.dart';
class AparienciaScreen extends StatefulWidget {
  const AparienciaScreen({super.key});

  @override
  State<AparienciaScreen> createState() => _AparienciaScreenState();
}

class _AparienciaScreenState extends State<AparienciaScreen> {
  bool _mostrarBannerVoz = true;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _mostrarBannerVoz = prefs.getBool('mostrar_banner_asistente_voz') ?? true;
      });
    }
  }

  Future<void> _toggleBannerVoz(bool valor) async {
    setState(() => _mostrarBannerVoz = valor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mostrar_banner_asistente_voz', valor);
  }

  void _seleccionar(ModoApariencia modo) {
    AppThemeController.instance.cambiarModo(modo);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final actual = AppThemeController.instance.modoActual;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Apariencia',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Elige cómo se ve la app',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: tema.cardColor,
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
                    children: List.generate(ModoApariencia.values.length, (i) {
                      final modo = ModoApariencia.values[i];
                      final esUltimo = i == ModoApariencia.values.length - 1;
                      final seleccionado = modo == actual;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _seleccionar(modo),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tema.colorScheme.primary.withValues(alpha: .12),
                                    ),
                                    child: Icon(
                                      modo.icono,
                                      size: 17,
                                      color: tema.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      modo.etiqueta,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
                                        color: seleccionado
                                            ? tema.colorScheme.primary
                                            : tema.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (seleccionado)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: tema.colorScheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!esUltimo)
                            Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: tema.colorScheme.onSurface.withValues(alpha: .08),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Accesibilidad e Inclusión',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tema.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: tema.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    secondary: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tema.colorScheme.primary.withValues(alpha: .12),
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 18,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                    title: const Text(
                      'Sugerencia de Modo por Voz en Inicio',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Muestra una tarjeta accesible en la pantalla de inicio para personas con baja visión o que prefieren hablar.',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _mostrarBannerVoz,
                    onChanged: _toggleBannerVoz,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}