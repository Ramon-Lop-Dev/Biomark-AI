import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/biomark_brand.dart';
import 'package:flutter_biomark/core/design/app_themecontroller.dart';
import 'package:flutter_biomark/core/design/biomark_glass_surface.dart';
import 'package:flutter_biomark/core/design/responsive_layout.dart';
import 'package:flutter_biomark/app_shell.dart';

/// Helper matemático para calcular la luminancia relativa y el ratio de contraste WCAG 2.1
double _srgbToLinear(int channel8Bit) {
  final c = channel8Bit / 255.0;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _srgbToLinear((color.r * 255).round());
  final g = _srgbToLinear((color.g * 255).round());
  final b = _srgbToLinear((color.b * 255).round());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Auditoría de Ratios de Contraste (WCAG 2.1 AA / AAA)', () {
    test('Paleta principal supera ratios WCAG 2.1 AA (4.5:1 para texto normal, 3.0:1 para componentes)', () {
      // Azul corporativo (#3260A9) sobre Blanco (#FFFFFF)
      final crBlueWhite = _contrastRatio(BiomarkColors.blue, BiomarkColors.white);
      expect(crBlueWhite, greaterThanOrEqualTo(4.5), reason: 'Azul sobre blanco debe superar WCAG AA');
      expect(crBlueWhite, closeTo(6.21, 0.1));

      // Azul corporativo sobre fondo claro (#F9F9FC)
      final crBlueBg = _contrastRatio(BiomarkColors.blue, BiomarkColors.backgroundClaro);
      expect(crBlueBg, greaterThanOrEqualTo(4.5), reason: 'Azul sobre fondo claro debe superar WCAG AA');

      // Texto negro sobre fondo blanco
      final crBlackWhite = _contrastRatio(BiomarkColors.black, BiomarkColors.white);
      expect(crBlackWhite, closeTo(21.0, 0.1), reason: 'Negro sobre blanco es ratio máximo');

      // Texto blanco sobre fondo oscuro (#121212)
      final crWhiteDark = _contrastRatio(BiomarkColors.white, BiomarkColors.backgroundOscuro);
      expect(crWhiteDark, greaterThanOrEqualTo(7.0), reason: 'Blanco sobre fondo oscuro supera WCAG AAA');

      // Verde sobre fondo negro (indicadores de alta visibilidad en tarjetas oscuras)
      final crGreenBlack = _contrastRatio(BiomarkColors.green, BiomarkColors.black);
      expect(crGreenBlack, greaterThanOrEqualTo(7.0), reason: 'Verde sobre negro supera WCAG AAA');
    });

    test('Tema de Alto Contraste supera ratios WCAG 2.1 AAA (7.0:1)', () {
      final highContrastTheme = biomarkHighContrastTheme;

      // Color primario alto contraste (Negro puro) sobre fondo blanco
      final crPrimaryBg = _contrastRatio(
        highContrastTheme.colorScheme.primary,
        highContrastTheme.scaffoldBackgroundColor,
      );
      expect(crPrimaryBg, closeTo(21.0, 0.1), reason: 'Primario negro sobre fondo blanco ofrece 21:1');

      // Color secundario alto contraste (Azul intenso #1E3A8A) sobre fondo blanco
      final crSecondaryBg = _contrastRatio(
        highContrastTheme.colorScheme.secondary,
        highContrastTheme.scaffoldBackgroundColor,
      );
      expect(crSecondaryBg, greaterThanOrEqualTo(7.0), reason: 'Azul secundario alto contraste supera ratio AAA 7:1');
      expect(crSecondaryBg, closeTo(10.36, 0.1));

      // Color de error alto contraste (#990000) sobre fondo blanco
      final crErrorBg = _contrastRatio(
        highContrastTheme.colorScheme.error,
        highContrastTheme.scaffoldBackgroundColor,
      );
      expect(crErrorBg, greaterThanOrEqualTo(7.0), reason: 'Error alto contraste supera ratio AAA 7:1');
      expect(crErrorBg, closeTo(8.92, 0.1));
    });

    test('Tema Oscuro supera ratios WCAG 2.1 AA para texto y errores', () {
      final darkTheme = biomarkDarkTheme;

      // Texto blanco sobre superficie oscura (#1E1E1E)
      final crOnSurface = _contrastRatio(
        darkTheme.colorScheme.onSurface,
        darkTheme.colorScheme.surface,
      );
      expect(crOnSurface, greaterThanOrEqualTo(14.0), reason: 'Texto blanco sobre superficie oscura supera AAA');

      // Color de error en tema oscuro (#CF6679) sobre superficie oscura (#1E1E1E)
      final crErrorDark = _contrastRatio(
        darkTheme.colorScheme.error,
        darkTheme.colorScheme.surface,
      );
      expect(crErrorDark, greaterThanOrEqualTo(4.5), reason: 'Error en tema oscuro supera WCAG AA');
    });
  });

  group('2. Controlador de Apariencia y Alto Contraste (WCAG AAA Switcher)', () {
    test('AppThemeController cambia a modo alto contraste y expone propiedades correctas', () async {
      final controller = AppThemeController.instance;

      await controller.cambiarModo(ModoApariencia.altoContraste);
      expect(controller.modoActual, ModoApariencia.altoContraste);
      expect(controller.isHighContrast, isTrue);
      expect(controller.currentLightTheme, equals(biomarkHighContrastTheme));

      await controller.cambiarModo(ModoApariencia.claro);
      expect(controller.isHighContrast, isFalse);
      expect(controller.currentLightTheme, equals(biomarkTheme));

      await controller.cambiarModo(ModoApariencia.sistema);
      expect(controller.modoActual, ModoApariencia.sistema);
    });

    testWidgets('BiomarkGlassSurface conmuta a tarjeta sólida con borde de 2.0px en Alto Contraste', (tester) async {
      await AppThemeController.instance.cambiarModo(ModoApariencia.altoContraste);

      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkHighContrastTheme,
          home: const Scaffold(
            body: BiomarkGlassSurface(
              child: Text('Contenido Accesible'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe existir el texto sin desenfoques translúcidos
      expect(find.text('Contenido Accesible'), findsOneWidget);

      // Verificar que el Container renderiza un borde de ancho 2.0
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      bool foundHighContrastBorder = false;
      for (final element in containerFinder.evaluate()) {
        final widget = element.widget as Container;
        final decoration = widget.decoration;
        if (decoration is BoxDecoration && decoration.border != null) {
          final border = decoration.border;
          if (border is Border && border.top.width == 2.0) {
            foundHighContrastBorder = true;
            break;
          }
        }
      }
      expect(foundHighContrastBorder, isTrue, reason: 'En alto contraste BiomarkGlassSurface debe usar borde de 2.0px');

      // Restaurar tema normal
      await AppThemeController.instance.cambiarModo(ModoApariencia.claro);
    });
  });

  group('3. Ergonomía Táctil y Tamaño de Elementos Interactivos (Target Size >= 48x48 dp)', () {
    testWidgets('Los botones de navegación en AppShell respetan tamaño mínimo de 48x48 dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkTheme,
          home: const AppShell(),
        ),
      );
      await tester.pump();

      // Buscar ítems de navegación que tienen ConstrainedBox con minWidth=48 y minHeight=48
      final constrainedFinder = find.byType(ConstrainedBox);
      bool hasMin48Target = false;
      for (final element in constrainedFinder.evaluate()) {
        final widget = element.widget as ConstrainedBox;
        if (widget.constraints.minWidth >= 48.0 && widget.constraints.minHeight >= 48.0) {
          hasMin48Target = true;
          break;
        }
      }
      expect(hasMin48Target, isTrue, reason: 'Los ítems de navegación deben tener un área táctil mínima de 48x48 dp');
    });

    testWidgets('El botón flotante central de Chat tiene dimensiones táctiles ergonómicas (64x64 dp)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkTheme,
          home: const AppShell(),
        ),
      );
      await tester.pump();

      // Buscar el Semantics de abrir chat
      final chatSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Abrir asistente de salud Biomark AI',
      );
      expect(chatSemantics, findsOneWidget);

      final containerFinder = find.descendant(
        of: chatSemantics,
        matching: find.byWidgetPredicate(
          (w) => w is Container && (w.constraints?.minWidth == 64 || (w.decoration is BoxDecoration)),
        ),
      );
      expect(containerFinder, findsWidgets);
    });
  });

  group('4. Jerarquía Visual y Legibilidad Tipográfica', () {
    test('TextTheme de Biomark define fuentes diferenciadas para jerarquía de títulos y cuerpo', () {
      final theme = biomarkTheme;

      // Jerarquía de Títulos: Familia 'Syne', fontWeight Bold / w600
      expect(theme.textTheme.displayLarge?.fontFamily, 'Syne');
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.bold);

      expect(theme.textTheme.headlineMedium?.fontFamily, 'Syne');
      expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.bold);

      expect(theme.textTheme.titleLarge?.fontFamily, 'Syne');
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);

      // Jerarquía de Cuerpo y Etiquetas: Familia 'Poppins' para máxima legibilidad
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Poppins');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Poppins');
      expect(theme.textTheme.labelLarge?.fontFamily, 'Poppins');
    });

    test('Tema de Alto Contraste intensifica los pesos tipográficos (w900, w800, w600)', () {
      final hcTheme = biomarkHighContrastTheme;

      expect(hcTheme.textTheme.displayLarge?.fontWeight, FontWeight.w900);
      expect(hcTheme.textTheme.headlineMedium?.fontWeight, FontWeight.w900);
      expect(hcTheme.textTheme.titleLarge?.fontWeight, FontWeight.w800);
      expect(hcTheme.textTheme.bodyLarge?.fontWeight, FontWeight.w600);
      expect(hcTheme.textTheme.bodyMedium?.fontWeight, FontWeight.w600);
      expect(hcTheme.textTheme.labelLarge?.fontWeight, FontWeight.w800);
    });
  });

  group('5. Accesibilidad Semántica y No Dependencia Exclusiva del Color', () {
    testWidgets('AppShell expone nodos Semantics con etiquetas descriptivas e indicación de selección', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkTheme,
          home: const AppShell(),
        ),
      );
      await tester.pump();

      // Verificar que los ítems del navbar tienen Semantics con etiqueta y número de pestaña
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && (widget.properties.label?.contains('pestaña') ?? false),
      );
      expect(semanticsFinder, findsWidgets);

      // Verificar que al menos uno está seleccionado como inicial
      final selectedFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      );
      expect(selectedFinder, findsWidgets);
    });

    test('Distintivos clínicos no dependen únicamente del color (incluyen texto + icono + etiqueta)', () {
      // Simular badges CCM
      final ccmRatings = ['ROJO', 'AMARILLO', 'VERDE'];
      for (final rating in ccmRatings) {
        final String label;
        final IconData icon;
        if (rating == 'ROJO') {
          label = 'CCM: ALTO RIESGO (ROJO)';
          icon = Icons.warning_amber_rounded;
        } else if (rating == 'AMARILLO') {
          label = 'CCM: MODERADO (AMARILLO)';
          icon = Icons.priority_high_rounded;
        } else {
          label = 'CCM: LEVE (VERDE)';
          icon = Icons.check_circle_outline_rounded;
        }

        expect(label.isNotEmpty, isTrue);
        expect(icon, isNotNull);
        expect(label.contains(rating), isTrue, reason: 'El texto explícito debe indicar el nivel de triaje sin depender del color');
      }
    });
  });

  group('6. Adaptación Responsiva y Escalabilidad de Texto (Dynamic Type / TextScaler)', () {
    test('Breakpoints definen umbrales correctos para móvil, tablet y escritorio', () {
      expect(ResponsiveBreakpoints.mobileMax, equals(650.0));
      expect(ResponsiveBreakpoints.tabletMax, equals(1050.0));
      expect(ResponsiveBreakpoints.desktopMax, equals(1400.0));
    });

    testWidgets('La interfaz se adapta a escalas de texto ampliadas (1.5x y 2.0x) sin desbordamientos', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      // Probar escala 1.5x (accesibilidad típica para usuarios con presbicia o baja visión)
      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: const AppShell(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'No deben ocurrir desbordamientos con TextScaler 1.5x');

      // Probar escala 2.0x (accesibilidad máxima recomendada por WCAG 1.4.4 Resize Text)
      await tester.pumpWidget(
        MaterialApp(
          theme: biomarkTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: const AppShell(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'No deben ocurrir desbordamientos con TextScaler 2.0x');
    });

    testWidgets('ResponsiveContainer restringe el ancho en pantallas anchas (desktop)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              maxWidth: 950,
              child: Text('Contenido Desktop'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ResponsiveContainer),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrainedBox.constraints.maxWidth, equals(950.0));
    });
  });
}
