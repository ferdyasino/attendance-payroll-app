import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  static const String _endpoint = '/attendances';

  static Future<List<Attendance>> fetchAttendance() async {
    try {
      final response = await ApiService.get(_endpoint);
      final data = response['data'] as List;
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
      String action, int employeeId) async {
    try {
      final response = await ApiService.post(
        '$_endpoint/$action',
        body: {'employeeId': employeeId},
      );
      return response['message'] ?? '✅ $action success!';
    } catch (e) {
      throw Exception('❌ $action failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
