class Shift {
  final String email;
  final String baseShift;
  final String cycleStart;
  final String cycleEnd;
  final ShiftSchedule schedule;

  Shift({
    required this.email,
    required this.baseShift,
    required this.cycleStart,
    required this.cycleEnd,
    required this.schedule,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      email: json['email'] ?? '',
      baseShift: json['baseShift'] ?? '',
      cycleStart: json['cycleStart'] ?? '',
      cycleEnd: json['cycleEnd'] ?? '',
      schedule: ShiftSchedule.fromJson(json['schedule'] ?? {}),
    );
  }
}

class ShiftSchedule {
  String defaultShift;
  Map<String, dynamic> overridesDates;
  List<ShiftRange> overridesRanges;

  ShiftSchedule({
    required this.defaultShift,
    required this.overridesDates,
    required this.overridesRanges,
  });

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      defaultShift: json['default'] ?? '',
      overridesDates: Map<String, dynamic>.from(json['overrides']?['dates'] ?? {}),
      overridesRanges: (json['overrides']?['ranges'] as List<dynamic>? ?? [])
          .map((e) => ShiftRange.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'default': defaultShift,
        'overrides': {
          'dates': overridesDates,
          'ranges': overridesRanges.map((e) => e.toJson()).toList(),
        },
      };
}

class ShiftRange {
  final String from;
  final String to;
  final String shift;
  final String reason;

  ShiftRange({
    required this.from,
    required this.to,
    required this.shift,
    required this.reason,
  });

  factory ShiftRange.fromJson(Map<String, dynamic> json) {
    return ShiftRange(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      shift: json['shift'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'shift': shift,
        'reason': reason,
      };
}
