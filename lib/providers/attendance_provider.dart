import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<Attendance> _attendanceList = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  // Getters
  List<Attendance> get attendanceList => _attendanceList;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;

  bool get isClockedIn => _todayAttendance?.timeIn != null && _todayAttendance?.timeOut == null;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Set attendance list
  void _setAttendanceList(List<Attendance> list) {
    _attendanceList = list;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Set today's attendance
  void _setTodayAttendance(Attendance? attendance) {
    _todayAttendance = attendance;
    notifyListeners();
  }

  // Set summary
  void _setSummary(Map<String, dynamic> summary) {
    _summary = summary;
    notifyListeners();
  }

  // Time In
  Future<bool> timeIn() async {
    try {
      _setLoading(true);
      clearError();

      final attendance = await AttendanceService.timeIn();
      _setTodayAttendance(attendance);
      
      // Refresh attendance list
      await fetchUserAttendance();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Time Out
  Future<bool> timeOut() async {
    try {
      _setLoading(true);
      clearError();

      final attendance = await AttendanceService.timeOut();
      _setTodayAttendance(attendance);
      
      // Refresh attendance list
      await fetchUserAttendance();
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Get today's attendance
  Future<void> fetchTodayAttendance() async {
    try {
      _setLoading(true);
      final attendance = await AttendanceService.getTodayAttendance();
      _setTodayAttendance(attendance);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Get user attendance records
  Future<void> fetchUserAttendance({
    String? userId,
    String? month,
    String? year,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // If userId is not provided, we'll need to get it from auth provider
      // For now, we'll use the current user's ID
      final List<Attendance> attendances;

      if (userId != null) {
        attendances = await AttendanceService.getUserAttendance(
          userId,
          month: month,
          year: year,
        );
      } else {
        // Try to get today's attendance as fallback
        final today = await AttendanceService.getTodayAttendance();
        if (today != null) {
          attendances = await AttendanceService.getUserAttendance(
            today.userId.toString(),
            month: month,
            year: year,
          );
        } else {
          _setError('User ID is required');
          _setLoading(false);
          return;
        }
      }

      _setAttendanceList(attendances);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Get attendance summary
  Future<void> fetchAttendanceSummary({
    required String userId,
    String? month,
    String? year,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final summary = await AttendanceService.getAttendanceSummary(
        userId,
        month: month,
        year: year,
      );

      _setSummary(summary);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Get all attendance (Admin/Superadmin only)
  Future<void> fetchAllAttendance({
    String? startDate,
    String? endDate,
    String? status,
    String? userId,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final attendances = await AttendanceService.getAllAttendance(
        startDate: startDate,
        endDate: endDate,
        status: status,
        userId: userId,
      );

      _setAttendanceList(attendances);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Refresh attendance data
  Future<void> refresh() async {
    await fetchTodayAttendance();
    if (_todayAttendance != null) {
      await fetchUserAttendance(userId: _todayAttendance!.userId.toString());
    }
  }
}
