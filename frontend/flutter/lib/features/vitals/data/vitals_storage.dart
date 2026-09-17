import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/vital_measurement.dart';

class VitalsStorage {
  static const _keyLatest = 'biomark_latest_vital_measurement';
  static const _keyHistory = 'biomark_vitals_history';

  static Future<VitalMeasurement?> getLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLatest);
    if (raw == null) return null;
    try {
      return VitalMeasurement.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMeasurement(VitalMeasurement measurement) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(measurement.toJson());
    await prefs.setString(_keyLatest, jsonStr);

    final historyRaw = prefs.getStringList(_keyHistory) ?? [];
    historyRaw.insert(0, jsonStr);
    if (historyRaw.length > 20) {
      historyRaw.removeRange(20, historyRaw.length);
    }
    await prefs.setStringList(_keyHistory, historyRaw);
  }

  static Future<List<VitalMeasurement>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyHistory) ?? [];
    final list = <VitalMeasurement>[];
    for (final raw in rawList) {
      try {
        list.add(VitalMeasurement.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    return list;
  }
}
