class AppUser {
  final String fullName;
  final String email;
  final String role;

  AppUser({
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
    );
  }
}
