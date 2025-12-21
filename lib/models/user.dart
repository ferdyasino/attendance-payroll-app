class User {
  final String fullName;
  final String email;
  final String role;
  final bool firstLogin;
  final String passwordHash;
  final DateTime? lastLogin;
  final String status;

  User({
    required this.fullName,
    required this.email,
    required this.role,
    this.firstLogin = false,
    this.passwordHash = '',
    this.status = '',
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // firstLogin conversion
    bool firstLoginVal = false;
    final firstLoginRaw = json['first_login'];
    if (firstLoginRaw is bool) firstLoginVal = firstLoginRaw;
    else if (firstLoginRaw is String && firstLoginRaw.toLowerCase() == 'true') firstLoginVal = true;

    // lastLogin conversion
    DateTime? lastLoginVal;
    if (json['last_login'] != null && json['last_login'].toString().isNotEmpty) {
      lastLoginVal = DateTime.tryParse(json['last_login'].toString());
    }


    return User(
      fullName: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      status: json['status'] ?? '',
      firstLogin: firstLoginVal,
      passwordHash: json['password_hash'] ?? '',
      lastLogin: lastLoginVal,
    );
  }

  Map<String, String> toJsonForUpdate() {
    return {
      'fullname': fullName,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  Map<String, String> toJsonForAdd() {
    return {
      'fullname': fullName,
      'email': email,
      'role': role,
      'status': status,
      'action': 'add',
    };
  }
}
