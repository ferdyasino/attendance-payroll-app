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
