import 'attendance_record.dart';

class Employee {
  final String department;
  final String position;
  final String setup;
  final String fullName;
  final String email;

  /// Attendance records (chronological or fetched order)
  final List<AttendanceRecord> records;

  /// Planned shifts (key = YYYY-MM-DD, value = shift code)
  final Map<String, String> plannedShifts;

  Employee({
    required this.department,
    required this.position,
    required this.setup,
    required this.fullName,
    required this.email,
    List<AttendanceRecord>? records,
    Map<String, String>? plannedShifts,
  })  : records = records ?? <AttendanceRecord>[],
        plannedShifts = plannedShifts ?? <String, String>{};

  // -------------------- OVERTIME HELPERS --------------------

  /// Latest non-zero OT value (string, raw)
  String get latestOTMinutes {
    if (records.isEmpty) return '0';

    for (final AttendanceRecord r in records.reversed) {
      final String? ot = r.totalOT;
      if (ot != null && ot.trim().isNotEmpty && ot.trim() != '0') {
        return ot.trim();
      }
    }
    return '0';
  }

  /// Total OT in hours (decimal)
  double get totalOTHours {
    return records.fold<double>(
      0.0,
      (double sum, AttendanceRecord r) => sum + r.totalOTInHours,
    );
  }

  /// Total OT in minutes (integer)
  int get totalOTMinutes {
    return records.fold<int>(0, (int sum, AttendanceRecord r) {
      final String? ot = r.totalOT;
      if (ot == null || ot.trim().isEmpty || ot.trim() == '0') {
        return sum;
      }

      final String cleaned = ot.trim();

      // Format: HH:MM
      if (cleaned.contains(':')) {
        final List<String> parts = cleaned.split(':');
        final int hours = int.tryParse(parts[0]) ?? 0;
        final int minutes =
            parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        return sum + (hours * 60) + minutes;
      }

      // Format: total minutes
      return sum + (int.tryParse(cleaned) ?? 0);
    });
  }

  // -------------------- SHIFT PLANNING --------------------

  /// Set shift for a future or current date only
  void setShiftForDay(String date, String shift) {
    final DateTime today =
        DateTime.now().toLocal().subtract(const Duration(
              hours: 24,
            ));

    final DateTime shiftDate = DateTime.parse(date);

    if (shiftDate.isBefore(today)) return;

    plannedShifts[date] = shift;
  }

  /// Get shift for a specific day
  String getShiftForDay(String date) {
    return plannedShifts[date] ?? '—';
  }

  // -------------------- FACTORY (OPTIONAL BUT RECOMMENDED) --------------------

  factory Employee.fromJson(
    Map<String, dynamic> json, {
    List<AttendanceRecord>? records,
    Map<String, String>? plannedShifts,
  }) {
    return Employee(
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      setup: json['setup'] ?? '',
      fullName: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      records: records,
      plannedShifts: plannedShifts,
    );
  }
}
