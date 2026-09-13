import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_biomark/features/reminders/data/reminders_service.dart';

void main() {
  test('formatea una hora UTC en la zona local del dispositivo', () {
    final local = DateTime.parse('2026-09-13T07:00:00.000Z').toLocal();
    final expected =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    expect(RemindersService.formatHour('2026-09-13T07:00:00.000Z'), expected);
  });
}
