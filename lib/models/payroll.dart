class Payroll {
  final int id;
  final int userId;
  final String month;
  final double baseSalary;
  final double overtimePay;
  final double deductions;
  final double totalPay;
  final DateTime payDate;
  final String? userName;
  final String? userEmail;

  Payroll({
    required this.id,
    required this.userId,
    required this.month,
    required this.baseSalary,
    required this.overtimePay,
    required this.deductions,
    required this.totalPay,
    required this.payDate,
    this.userName,
    this.userEmail,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'],
      userId: json['userId'],
      month: json['month'],
      baseSalary: json['baseSalary'].toDouble(),
      overtimePay: json['overtimePay'].toDouble(),
      deductions: json['deductions'].toDouble(),
      totalPay: json['totalPay'].toDouble(),
      payDate: DateTime.parse(json['payDate']),
      userName: json['User']?['name'],
      userEmail: json['User']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'baseSalary': baseSalary,
      'overtimePay': overtimePay,
      'deductions': deductions,
      'totalPay': totalPay,
      'payDate': payDate.toIso8601String(),
    };
  }
}