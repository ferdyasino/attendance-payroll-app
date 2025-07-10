import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';

class AttendanceService {
  static const String baseUrl = 'http://192.168.1.116:5000/api/attendances';

  static Future<List<Attendance>> fetchAttendance() async {
    final uri = Uri.parse(baseUrl);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        final message =
            json.decode(response.body)['message'] ?? 'Unknown error';
        throw Exception('❌ Attendance fetch failed: $message');
      }
      final data = json.decode(response.body) as List;
      return data.map((j) => Attendance.fromJson(j)).toList();
    } catch (e) {
      throw Exception(
          '❌ Attendance fetch failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Clock In
  static Future<String> clockIn(int employeeId) =>
      _postWithMessage('clock-in', employeeId);

  // Clock Out
  static Future<String> clockOut(int employeeId) =>
      _postWithMessage('clock-out', employeeId);

  // Breaks and Lunch
  static Future<String> break1In(int employeeId) =>
      _postWithMessage('break1-in', employeeId);

  static Future<String> break1Out(int employeeId) =>
      _postWithMessage('break1-out', employeeId);

  static Future<String> lunchIn(int employeeId) =>
      _postWithMessage('lunch-in', employeeId);

  static Future<String> lunchOut(int employeeId) =>
      _postWithMessage('lunch-out', employeeId);

  static Future<String> break2In(int employeeId) =>
      _postWithMessage('break2-in', employeeId);

  static Future<String> break2Out(int employeeId) =>
      _postWithMessage('break2-out', employeeId);

  static Future<String> break3In(int employeeId) =>
      _postWithMessage('break3-in', employeeId);

  static Future<String> break3Out(int employeeId) =>
      _postWithMessage('break3-out', employeeId);

  // Reusable helper for POST requests
  static Future<String> _postWithMessage(
      String endpoint, int employeeId) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      uri,
      body: jsonEncode({'employeeId': employeeId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      try {
        final message = jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception('❌ $endpoint failed: $message');
      } catch (_) {
        throw Exception('❌ $endpoint failed: ${response.body}');
      }
    }

    return jsonDecode(response.body)['message'] ?? '✅ $endpoint success!';
  }
}
