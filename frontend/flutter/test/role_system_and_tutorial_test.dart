import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/features/community/data/invitations_api.dart';
import 'package:flutter_biomark/features/community/presentation/role_tutorial_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PromoterItem Domain Tests', () {
    test('Parsea correctamente centroSaludNombre y estadoCuenta desde JSON', () {
      final json = {
        'id': 'user-123',
        'correo': 'brigadista@minsa.gob.ni',
        'estado_cuenta': 'ACTIVO',
        'fecha_creacion': '2026-09-20T10:00:00Z',
        'perfiles': {
          'nombre_completo': 'Juan Pérez',
          'telefono': '+505 8888 1234',
        },
        'centros_salud': {
          'nombre': 'Centro de Salud Sócrates Flores',
        },
      };

      final item = PromoterItem.fromJson(json);

      expect(item.id, 'user-123');
      expect(item.email, 'brigadista@minsa.gob.ni');
      expect(item.fullName, 'Juan Pérez');
      expect(item.isActivo, true);
      expect(item.estadoCuenta, 'ACTIVO');
      expect(item.centroSaludNombre, 'Centro de Salud Sócrates Flores');
    });

    test('Maneja centros_salud nulo sin fallar', () {
      final json = {
        'id': 'user-456',
        'correo': 'promotor2@minsa.gob.ni',
        'estado_cuenta': 'SUSPENDIDO',
      };

      final item = PromoterItem.fromJson(json);

      expect(item.isActivo, false);
      expect(item.centroSaludNombre, isNull);
      expect(item.fullName, 'promotor2@minsa.gob.ni');
    });
  });

  group('RoleTutorialDialog Widget Tests', () {
    testWidgets('Renderiza tutorial para rol ADMIN con comandos SILAIS Managua', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleTutorialDialog(initialRole: 'ADMIN'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guía y Tutorial de la Aplicación'), findsOneWidget);
      expect(find.text('SILAIS MANAGUA · COMANDO'), findsOneWidget);
      expect(find.text('Centro de Mando Departamental'), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
    });

    testWidgets('Renderiza tutorial para rol PROMOTOR con vigilancia comunitaria', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleTutorialDialog(initialRole: 'PROMOTOR'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BRIGADISTA COMUNITARIO MINSA'), findsOneWidget);
      expect(find.text('Vigilancia en Terreno y Comunidad'), findsOneWidget);
    });

    testWidgets('Renderiza tutorial para rol TRABAJADOR_SALUD con triaje CCM', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleTutorialDialog(initialRole: 'TRABAJADOR_SALUD'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MINSA · ATENCIÓN CLÍNICA'), findsOneWidget);
      expect(find.text('Centro de Mando Local'), findsOneWidget);
    });

    testWidgets('Renderiza tutorial para rol USUARIO común con orientación y mapa', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleTutorialDialog(initialRole: 'USUARIO'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BIOMARK AI · CIUDADANO'), findsOneWidget);
      expect(find.text('Tu Copiloto de Salud Familiar'), findsOneWidget);
    });
  });
}
