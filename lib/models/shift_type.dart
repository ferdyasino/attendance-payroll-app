class ShiftType {
  final String shiftName;
  final String startTime;
  final String endTime;

  ShiftType({
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftType.fromJson(List<dynamic> json) {
    return ShiftType(
      shiftName: json[0]?.toString() ?? '',
      startTime: json[1]?.toString() ?? '',
      endTime: json[2]?.toString() ?? '',
    );
  }
}
