// models/employee.dart
class AttendanceRecord {
  final String date;
  final String day;
  final String? shift;
  final String? inTime;
  final String? outTime;
  final String? breakIn;
  final String? breakOut;
  final String? preShiftOT;
  final String? postShiftOT;
  final String? approvedBy;
  final dynamic totalOT;

  AttendanceRecord({
    required this.date,
    required this.day,
    this.shift,
    this.inTime,
    this.outTime,
    this.breakIn,
    this.breakOut,
    this.preShiftOT,
    this.postShiftOT,
    this.approvedBy,
    this.totalOT,
  });
}

class Employee {
  final String department;
  final String position;
  final String setup;
  final String fullName;
  final List<AttendanceRecord> records;

  Employee({
    required this.department,
    required this.position,
    required this.setup,
    required this.fullName,
    required this.records,
  });
}