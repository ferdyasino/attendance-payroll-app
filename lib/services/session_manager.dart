import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyEmail = "user_email";

  /// Save login session
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email.trim().toLowerCase());
  }

  /// Get saved session email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyEmail);
  }

  /// Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
  }
}
