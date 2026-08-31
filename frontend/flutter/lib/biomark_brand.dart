// Define la paleta corporativa y el tema Material 3 compartido por la app.
import 'package:flutter/material.dart';

class BiomarkColors {
  static const green = Color(0xFF46AB39);
  static const blue = Color(0xFF3260A9);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

final ThemeData biomarkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: BiomarkColors.white,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: BiomarkColors.blue,
    onPrimary: BiomarkColors.white,
    secondary: BiomarkColors.green,
    onSecondary: BiomarkColors.white,
    error: BiomarkColors.black,
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
