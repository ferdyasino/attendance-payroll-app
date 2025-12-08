class Attendance {
  final String id;
  final int userId;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final double totalHours;
  final int lateMinutes;
  final int overtimeMinutes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? user;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.totalHours,
    required this.lateMinutes,
    required this.overtimeMinutes,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? json['userId'] ?? 0,
      date: json['date'] ?? '',
      timeIn: json['timeIn'] ?? json['time_in'],
      timeOut: json['timeOut'] ?? json['time_out'],
      totalHours: (json['totalHours'] ?? json['total_hours'] ?? 0.0).toDouble(),
      lateMinutes: json['lateMinutes'] ?? json['late_minutes'] ?? 0,
      overtimeMinutes: json['overtimeMinutes'] ?? json['overtime_minutes'] ?? 0,
      status: json['status'] ?? 'absent',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'totalHours': totalHours,
      'lateMinutes': lateMinutes,
      'overtimeMinutes': overtimeMinutes,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user,
    };
  }

  String get userName => user?['name'] ?? 'Unknown User';
  String get userEmail => user?['email'] ?? '';

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLeave => status == 'leave';

  String get formattedTotalHours {
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).floor();
    return '${hours}h ${minutes}m';
  }
}
