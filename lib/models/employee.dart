// models/employee.dart

class AttendanceRecord {
  final String date;        
  final String day;         
  final String? shift;      

  final String? inTime;
  final String? outTime;

  final String? totalOT;    

  const AttendanceRecord({
    required this.date,
    required this.day,
    this.shift,
    this.inTime,
    this.outTime,
    this.totalOT,
  });

  bool get isPresent => inTime != null || outTime != null;

  bool get isAbsent => inTime == null && outTime == null && shift != "NO SHIFT";

  double get totalOTInHours {
    if (totalOT == null || totalOT!.trim().isEmpty || totalOT == "0") return 0.0;
    final cleaned = totalOT!.trim();

    if (cleaned.contains(':')) {
      final parts = cleaned.split(':');
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return hours + (minutes / 60);
    }

    final minutes = int.tryParse(cleaned) ?? 0;
    return minutes / 60;
  }
}

class Employee {
  final String department;
  final String position;
  final String setup;
  final String fullName;
  final String email;
  final List<AttendanceRecord> records;

  const Employee({
    required this.department,
    required this.position,
    required this.setup,
    required this.fullName,
    required this.email,
    required this.records,
  });

  String get latestOTMinutes {
    if (records.isEmpty) return "0";
    final withOT = records.where((r) =>
        r.totalOT != null &&
        r.totalOT!.trim().isNotEmpty &&
        r.totalOT != "0");
    if (withOT.isEmpty) return "0";
    return withOT.first.totalOT!;
  }

  double get totalOTHours {
    return records.fold(0.0, (sum, r) => sum + r.totalOTInHours);
  }

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
}
