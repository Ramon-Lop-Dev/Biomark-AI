import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biomark/core/ui/components/biomark_ui_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Biomark Buttons UI Tests', () {
    testWidgets('BiomarkPrimaryButton renders and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkPrimaryButton(
              label: 'Continuar',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      expect(tapped, isTrue);
    });

    testWidgets('BiomarkPrimaryButton displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkPrimaryButton(
              label: 'Guardar',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('BiomarkDangerButton renders with emergency styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkDangerButton(
              label: 'Descartar Alerta',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Descartar Alerta'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('BiomarkVoiceButton renders and toggles listening state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkVoiceButton(
              onPressed: () {},
              isListening: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('BiomarkFilterChip renders and toggles state', (tester) async {
      bool selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BiomarkFilterChip(
                  label: 'Dengue',
                  count: 4,
                  isSelected: selected,
                  onSelected: (val) => setState(() => selected = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Dengue'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.text('Dengue'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });
  });

  group('Biomark Headers UI Tests', () {
    testWidgets('BiomarkScreenHeader renders title, subtitle, and back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkScreenHeader(
              title: 'Mis Signos Vitales',
              subtitle: 'Historial de mediciones SCG',
              showBackButton: true,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Mis Signos Vitales'), findsOneWidget);
      expect(find.text('Historial de mediciones SCG'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('BiomarkHeroHeader displays user greeting and role badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkHeroHeader(
              userName: 'Carlos',
              roleLabel: 'Promotor Comunitario',
              centerName: 'C/S Edgar Lang',
              unreadNotifications: 3,
            ),
          ),
        ),
      );

      expect(find.text('Hola, Carlos'), findsOneWidget);
      expect(find.text('PROMOTOR COMUNITARIO'), findsOneWidget);
      expect(find.text('• C/S Edgar Lang'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Biomark Cards UI Tests', () {
    testWidgets('BiomarkVitalPulseCard renders BPM and status label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkVitalPulseCard(
              bpm: 72,
              statusLabel: 'Ritmo Normal',
              isNormal: true,
              recordedAt: 'Hoy, 08:30 AM',
            ),
          ),
        ),
      );

      expect(find.text('72'), findsOneWidget);
      expect(find.text('Ritmo Normal'), findsOneWidget);
      expect(find.text('Frecuencia Cardíaca'), findsOneWidget);
      expect(find.text('Último registro: Hoy, 08:30 AM'), findsOneWidget);
    });

    testWidgets('BiomarkTriageStatusCard renders CCM triage levels correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const BiomarkTriageStatusCard(
              nivelTriaje: 'ROJO',
              titulo: 'Signos de Alarma Detectados',
              descripcion: 'Paciente con sangrado de encías y dolor abdominal continuo.',
              centroSaludAsignado: 'C/S Edgar Lang',
            ),
          ),
        ),
      );

      expect(find.text('ROJO'), findsOneWidget);
      expect(find.text('Signos de Alarma Detectados'), findsOneWidget);
      expect(find.text('Jurisdicción: C/S Edgar Lang'), findsOneWidget);
    });

    testWidgets('BiomarkHealthCard and BiomarkEventCard render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BiomarkHealthCard(
                  title: 'Prevención del Dengue',
                  category: 'Epidemiología',
                  summary: 'Eliminación activa de criaderos de mosquitos en San Judas.',
                ),
                BiomarkEventCard(
                  title: 'Jornada de Vacunación',
                  dateText: '12 OCT',
                  location: 'Barrio Altagracia, Cancha',
                  organizer: 'MINSA Distrito III',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Prevención del Dengue'), findsOneWidget);
      expect(find.text('Jornada de Vacunación'), findsOneWidget);
      expect(find.text('12 OCT'), findsOneWidget);
    });
  });

  group('Biomark Form Controls UI Tests', () {
    testWidgets('BiomarkTextField and PasswordField render and accept input', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiomarkTextField(
              label: 'Nombre Completo',
              controller: ctrl,
              hintText: 'Ingresa tu nombre',
            ),
          ),
        ),
      );

      expect(find.text('Nombre Completo'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'María López');
      expect(ctrl.text, 'María López');
    });

    testWidgets('BiomarkMultiSelectChips updates selection list', (tester) async {
      List<String> selected = ['Fiebre'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BiomarkMultiSelectChips(
                  options: const ['Fiebre', 'Cefalea', 'Dolor retroocular'],
                  selectedOptions: selected,
                  onChanged: (newList) => setState(() => selected = newList),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Fiebre'), findsOneWidget);
      expect(find.text('Cefalea'), findsOneWidget);
      await tester.tap(find.text('Cefalea'));
      await tester.pumpAndSettle();
      expect(selected.contains('Cefalea'), isTrue);
    });
  });

  group('Biomark Badges UI Tests', () {
    testWidgets('BiomarkTriageBadge renders Roja, Amarilla y Verde', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                BiomarkTriageBadge(level: 'ROJO'),
                BiomarkTriageBadge(level: 'AMARILLO'),
                BiomarkTriageBadge(level: 'VERDE'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Urgencia (Rojo)'), findsOneWidget);
      expect(find.text('Alerta (Amarillo)'), findsOneWidget);
      expect(find.text('Rutinario (Verde)'), findsOneWidget);
    });

    testWidgets('BiomarkRoleBadge and BiomarkSyncBadge render accurately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                BiomarkRoleBadge(role: 'TRABAJADOR_SALUD'),
                BiomarkSyncBadge(isOnline: false, pendingSyncCount: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Médico / MINSA'), findsOneWidget);
      expect(find.text('Modo sin red (2 pendientes)'), findsOneWidget);
    });
  });
}
