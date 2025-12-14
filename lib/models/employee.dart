import 'attendance_record.dart';

class Employee {
  final String department;
  final String position;
  final String setup;
  final String fullName;
  final String email;
  final List<AttendanceRecord> records;

  /// Bi-monthly planned shifts (key = date "YYYY-MM-DD")
  final Map<String, String> plannedShifts;

  Employee({
    required this.department,
    required this.position,
    required this.setup,
    required this.fullName,
    required this.email,
    required this.records,
    Map<String, String>? plannedShifts,
  }) : plannedShifts = plannedShifts ?? {};

  /// Latest OT string from records
  String get latestOTMinutes {
    if (records.isEmpty) return "0";
    final withOT = records.where((r) =>
        r.totalOT != null &&
        r.totalOT!.trim().isNotEmpty &&
        r.totalOT != "0");
    if (withOT.isEmpty) return "0";
    return withOT.first.totalOT!;
  }

  /// Total OT in hours
  double get totalOTHours {
    return records.fold(0.0, (sum, r) => sum + r.totalOTInHours);
  }

  /// Total OT in minutes
  int get totalOTMinutes {
    return records.fold(0, (sum, r) {
      if (r.totalOT == null || r.totalOT!.trim().isEmpty) return sum;
      final cleaned = r.totalOT!.trim();

      if (cleaned.contains(':')) {
        final parts = cleaned.split(':');
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        return sum + (hours * 60) + minutes;
      }

      return sum + (int.tryParse(cleaned) ?? 0);
    });
  }

  /// Set shift only for selected day (does not modify past)
  void setShiftForDay(String date, String shift) {
    final today = DateTime.now();
    final shiftDate = DateTime.parse(date);
    if (shiftDate.isBefore(today)) return;
    plannedShifts[date] = shift;
  }

  /// Get shift for a specific day
  String getShiftForDay(String date) {
    return plannedShifts[date] ?? "—";
  }
}
