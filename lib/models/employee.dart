// models/employee.dart

class AttendanceRecord {
  final String date;        // e.g. "September 4"
  final String day;         // e.g. "Wednesday"
  final String? shift;      // e.g. "9PM-6AM", "8:30PM-5:30AM", or "NO SHIFT"

  // Real clock times in 12-hour format → "9:00 PM", "6:00 AM", or null if absent/leave
  final String? inTime;     // ← NOW SHOWS ACTUAL TIME (not "OFFICE-ONTIME")
  final String? outTime;    // ← NOW SHOWS ACTUAL TIME (not "OUT-ONTIME")

  // Optional: keep these if you ever want to show raw status again
  // final String? rawInStatus;
  // final String? rawOutStatus;

  final String? totalOT;    // e.g. "90", "1:30", "0", or null

  const AttendanceRecord({
    required this.date,
    required this.day,
    this.shift,
    this.inTime,
    this.outTime,
    this.totalOT,
  });

  // Helper: check if employee was present that day
  bool get isPresent => inTime != null || outTime != null;

  // Helper: check if absent/leave/no shift
  bool get isAbsent => inTime == null && outTime == null && shift != "NO SHIFT";

  // Optional: convert totalOT "90" → 1.5 hours (if needed later)
  double get totalOTInHours {
    if (totalOT == null || totalOT!.trim().isEmpty) return 0.0;
    final cleaned = totalOT!.trim();
    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return hours + (minutes / 60);
    }
    return double.tryParse(cleaned) ?? 0.0;
  }
}

class Employee {
  final String department;
  final String position;
  final String setup;
  final String fullName;
  final List<AttendanceRecord> records;

  const Employee({
    required this.department,
    required this.position,
    required this.setup,
    required this.fullName,
    required this.records,
  });

  // Helper: get latest OT across all records
  String get latestOT {
    if (records.isEmpty) return "0";
    final withOT = records.where((r) => r.totalOT != null && r.totalOT!.trim().isNotEmpty);
    if (withOT.isEmpty) return "0";
    return withOT.last.totalOT!;
  }

  // Helper: total OT this pay period (in hours as double)
  double get totalOTHours {
    return records.fold(0.0, (sum, r) => sum + r.totalOTInHours);
  }
}