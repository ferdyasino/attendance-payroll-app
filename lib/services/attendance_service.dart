import '../models/attendance.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AttendanceService {
  // Time In
  static Future<Attendance> timeIn() async {
    try {
      final response = await ApiService.post(
        Constants.timeInEndpoint,
        body: {},
      );

      if (response['success'] == true && response['data'] != null) {
        return Attendance.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Time-in failed');
      }
    } catch (e) {
      throw Exception('Time-in failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Time Out
  static Future<Attendance> timeOut() async {
    try {
      final response = await ApiService.post(
        Constants.timeOutEndpoint,
        body: {},
      );

      if (response['success'] == true && response['data'] != null) {
        return Attendance.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Time-out failed');
      }
    } catch (e) {
      throw Exception('Time-out failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Get today's attendance
  static Future<Attendance?> getTodayAttendance() async {
    try {
      final response = await ApiService.get(Constants.todayAttendanceEndpoint);

      if (response['success'] == true) {
        if (response['data'] != null) {
          return Attendance.fromJson(response['data']);
        }
        return null;
      } else {
        throw Exception(response['message'] ?? 'Failed to get today attendance');
      }
    } catch (e) {
      throw Exception('Failed to get today attendance: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Get user attendance records
  static Future<List<Attendance>> getUserAttendance(
    String userId, {
    String? month,
    String? year,
  }) async {
    try {
      String endpoint = '${Constants.userAttendanceEndpoint}/$userId';
      
      // Add query parameters if provided
      final queryParams = <String>[];
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(endpoint);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        return data.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get user attendance');
      }
    } catch (e) {
      throw Exception('Failed to get user attendance: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Get attendance summary for a user
  static Future<Map<String, dynamic>> getAttendanceSummary(
    String userId, {
    String? month,
    String? year,
  }) async {
    try {
      String endpoint = '${Constants.userAttendanceEndpoint}/$userId/summary';
      
      final queryParams = <String>[];
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(endpoint);

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to get attendance summary');
      }
    } catch (e) {
      throw Exception('Failed to get attendance summary: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Get all attendance records (Admin/Superadmin only)
  static Future<List<Attendance>> getAllAttendance({
    String? startDate,
    String? endDate,
    String? status,
    String? userId,
  }) async {
    try {
      String endpoint = '${Constants.attendanceBaseEndpoint}/all';
      
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');
      if (status != null) queryParams.add('status=$status');
      if (userId != null) queryParams.add('userId=$userId');
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(endpoint);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        return data.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get all attendance');
      }
    } catch (e) {
      throw Exception('Failed to get all attendance: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Legacy method for backward compatibility
  static Future<List<Attendance>> fetchAttendance() async {
    // Try to get all attendance (requires admin)
    try {
      return await getAllAttendance();
    } catch (e) {
      // If not admin, return empty list or handle differently
      return [];
    }
  }
}
