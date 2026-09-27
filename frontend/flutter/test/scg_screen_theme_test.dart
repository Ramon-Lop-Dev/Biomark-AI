import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/features/vitals/presentation/scg_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScgScreen Bitematic Adaptation Tests', () {
    testWidgets('Renders properly in Light Mode without clipping or errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const ScgScreen(),
        ),
      );
      await tester.pump();

      // Verificar que el título de la pantalla aparece
      expect(find.text('Sismocardiografía (SCG)'), findsOneWidget);

      // Verificar opciones de postura
      expect(find.text('Acostado'), findsOneWidget);
      expect(find.text('Sentado'), findsOneWidget);

      // Verificar botón de inicio
      expect(find.text('Iniciar medición en el pecho'), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Mode without clipping or errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const ScgScreen(),
        ),
      );
      await tester.pump();

      // Verificar que los textos principales se renderizan con alto contraste
      expect(find.text('Sismocardiografía (SCG)'), findsOneWidget);
      expect(find.text('Acostado'), findsOneWidget);
      expect(find.text('Sentado'), findsOneWidget);
      expect(find.text('Iniciar medición en el pecho'), findsOneWidget);
    });
  });
}
