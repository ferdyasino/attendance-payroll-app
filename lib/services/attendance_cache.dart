import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceCache {
  static const _keyLastAction = "last_attendance_action";
  static const _keyLastTime = "last_attendance_time";

  // NEW: full logs list
  static const _keyLogs = "attendance_logs";

  // =========================
  // EXISTING: keep as-is
  // =========================
  static Future<void> saveLastLog({
    required String action,
    required String time,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyLastAction, action);
    await prefs.setString(_keyLastTime, time);
  }

  static Future<Map<String, String>?> getLastLog() async {
    final prefs = await SharedPreferences.getInstance();

    final action = prefs.getString(_keyLastAction);
    final time = prefs.getString(_keyLastTime);

    if (action == null || time == null) return null;

    return {
      "action": action,
      "time": time,
    };
  }

  // =========================
  // NEW: SAVE MULTIPLE LOGS
  // =========================
  static Future<void> saveLogs(List<Map<String, dynamic>> logs) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(logs);
    await prefs.setString(_keyLogs, encoded);
  }

  // =========================
  // NEW: GET ALL LOGS
  // =========================
  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_keyLogs);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);

    return List<Map<String, dynamic>>.from(decoded);
  }

  // =========================
  // NEW: ADD SINGLE LOG
  // =========================
  static Future<void> addLog({
    required String action,
    required String time,
  }) async {
    final logs = await getLogs();

    logs.insert(0, {
      "action": action,
      "time": time,
    });

    await saveLogs(logs);
  }

  // =========================
  // CLEAR ALL
  // =========================
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyLastAction);
    await prefs.remove(_keyLastTime);
    await prefs.remove(_keyLogs);
  }
}
