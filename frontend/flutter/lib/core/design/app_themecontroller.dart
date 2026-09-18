// Controlador de apariencia y accesibilidad — Biomark AI
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_biomark/biomark_brand.dart';

enum ModoApariencia { claro, oscuro, altoContraste, sistema }

extension ModoAparienciaInfo on ModoApariencia {
  String get etiqueta {
    switch (this) {
      case ModoApariencia.claro:
        return 'Claro';
      case ModoApariencia.oscuro:
        return 'Oscuro';
      case ModoApariencia.altoContraste:
        return 'Alto contraste (Accesibilidad WCAG)';
      case ModoApariencia.sistema:
        return 'Como mi dispositivo';
    }
  }

  IconData get icono {
    switch (this) {
      case ModoApariencia.claro:
        return Icons.wb_sunny_rounded;
      case ModoApariencia.oscuro:
        return Icons.dark_mode_rounded;
      case ModoApariencia.altoContraste:
        return Icons.contrast_rounded;
      case ModoApariencia.sistema:
        return Icons.smartphone_rounded;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ModoApariencia.claro:
        return ThemeMode.light;
      case ModoApariencia.oscuro:
        return ThemeMode.dark;
      case ModoApariencia.altoContraste:
        return ThemeMode.light;
      case ModoApariencia.sistema:
        return ThemeMode.system;
    }
  }
}

class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const _clavePreferencia = 'modo_apariencia';

  ModoApariencia _modoActual = ModoApariencia.sistema;
  ModoApariencia get modoActual => _modoActual;
  ThemeMode get themeMode => _modoActual.themeMode;

  ThemeData get currentLightTheme {
    if (_modoActual == ModoApariencia.altoContraste) {
      return biomarkHighContrastTheme;
    }
    return biomarkTheme;
  }

  bool get isHighContrast => _modoActual == ModoApariencia.altoContraste;

  Future<void> cargarGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clavePreferencia);
    if (guardado != null) {
      _modoActual = ModoApariencia.values.firstWhere(
        (m) => m.name == guardado,
        orElse: () => ModoApariencia.sistema,
      );
      notifyListeners();
    }
  }

  Future<void> cambiarModo(ModoApariencia nuevo) async {
    if (nuevo == _modoActual) return;
    _modoActual = nuevo;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePreferencia, nuevo.name);
  }
}
