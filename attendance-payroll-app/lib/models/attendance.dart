class Attendance {
  final int id;
  final int employeeId;
  final String date;
  final String timeIn;
  final String timeOut;
  final String status;
  final int lateMinutes;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.timeIn,
    required this.timeOut,
    required this.status,
    required this.lateMinutes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      employeeId: json['employeeId'],
      date: json['date'],
      timeIn: json['timeIn'],
      timeOut: json['timeOut'],
      status: json['status'],
      lateMinutes: json['lateMinutes'],
    );
  }
}
