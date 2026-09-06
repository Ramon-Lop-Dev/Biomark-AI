// Define la paleta corporativa y los temas Material 3 (claro y oscuro)
// compartidos por la app.
import 'package:flutter/material.dart';

class BiomarkColors {
  // Colores de marca — se mantienen iguales en claro y oscuro.
  static const green = Color(0xFF46AB39);
  static const blue = Color(0xFF3260A9);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // Fondos usados directamente en varias pantallas (Scaffold
  // backgroundColor: const Color(0xFFF9F9FC)). Se dejan aquí también
  // como constantes con nombre para poder ir reemplazando esos valores
  // sueltos poco a poco por BiomarkColors.backgroundClaro /
  // BiomarkColors.backgroundOscuro sin tener que adivinar el hex cada vez.
  static const backgroundClaro = Color(0xFFF9F9FC);
  static const backgroundOscuro = Color(0xFF121212);
  static const superficieOscura = Color(0xFF1E1E1E);
}

final ThemeData biomarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: BiomarkColors.backgroundClaro,
  cardColor: BiomarkColors.white,
  dividerColor: const Color(0xFFEFEFF3),
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: BiomarkColors.blue,
    onPrimary: BiomarkColors.white,
    secondary: BiomarkColors.green,
    onSecondary: BiomarkColors.white,
    error: Color(0xFFB3261E),
    onError: BiomarkColors.white,
    surface: BiomarkColors.white,
    onSurface: BiomarkColors.black,
  ),
  fontFamily: 'Poppins',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.bold,
      color: BiomarkColors.black,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.bold,
      color: BiomarkColors.black,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.w600,
      color: BiomarkColors.black,
    ),
    bodyLarge: TextStyle(fontFamily: 'Poppins', color: BiomarkColors.black),
    bodyMedium: TextStyle(fontFamily: 'Poppins', color: BiomarkColors.black),
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      color: BiomarkColors.black,
    ),
  ),
);

/// Tema oscuro — misma estructura que [biomarkTheme] pero con superficies
/// oscuras y texto claro. Los colores de marca (verde/azul) se mantienen
/// para que la app siga siendo reconocible en modo oscuro.
final ThemeData biomarkDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: BiomarkColors.backgroundOscuro,
  cardColor: BiomarkColors.superficieOscura,
  dividerColor: const Color(0xFF2E2E33),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: BiomarkColors.blue,
    onPrimary: BiomarkColors.white,
    secondary: BiomarkColors.green,
    onSecondary: BiomarkColors.white,
    error: Color(0xFFCF6679),
    onError: BiomarkColors.black,
    surface: BiomarkColors.superficieOscura,
    onSurface: BiomarkColors.white,
  ),
  fontFamily: 'Poppins',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.bold,
      color: BiomarkColors.white,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.bold,
      color: BiomarkColors.white,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Syne',
      fontWeight: FontWeight.w600,
      color: BiomarkColors.white,
    ),
    bodyLarge: TextStyle(fontFamily: 'Poppins', color: BiomarkColors.white),
    bodyMedium: TextStyle(fontFamily: 'Poppins', color: BiomarkColors.white),
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      color: BiomarkColors.white,
    ),
  ),
);