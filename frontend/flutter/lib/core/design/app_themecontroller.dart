// Controlador de apariencia (tema) — Biomark AI
//
// Singleton con ChangeNotifier: cuando el modo cambia, notifica a quien
// esté escuchando (normalmente el MaterialApp en main.dart, para que
// se reconstruya con el nuevo ThemeMode).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModoApariencia { claro, oscuro, sistema }

extension ModoAparienciaInfo on ModoApariencia {
  String get etiqueta {
    switch (this) {
      case ModoApariencia.claro:
        return 'Claro';
      case ModoApariencia.oscuro:
        return 'Oscuro';
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

  /// Llamar una vez al inicio (por ejemplo en main() antes de runApp)
  /// para cargar el modo guardado previamente.
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