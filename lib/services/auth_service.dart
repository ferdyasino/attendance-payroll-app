
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static final String _scriptUrl = dotenv.env['USERS_SCRIPT_URL'] ?? "";

  /// -------------------- FETCH ALL USERS --------------------
  static Future<List<User>> fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse(_scriptUrl));
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        return decoded.map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// -------------------- CHECK EMAIL --------------------
  static Future<User?> checkEmail(String email) async {
    final users = await fetchAllUsers();
    try {
      return users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// -------------------- PASSWORD HASH --------------------
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password.trim() + salt.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// -------------------- LOGIN --------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final user = await checkEmail(email);
    if (user == null) return {'success': false, 'message': 'Email not found'};

    final hash = hashPassword(password, email);

    if (user.passwordHash.isEmpty) return {'success': false, 'message': 'Password not set'};
    if (user.passwordHash.trim() != hash) return {'success': false, 'message': 'Invalid password'};

    await saveLoginInfo(user.email, user.role);
    return {'success': true, 'user': user};
  }

  /// -------------------- SETUP PASSWORD --------------------
  static Future<Map<String, dynamic>> setupPassword({
    required String email,
    required String password,
  }) async {
    return _postAction('setuppassword', {'email': email, 'password': password});
  }

  /// -------------------- SAVE LOGIN INFO LOCALLY --------------------
  static Future<void> saveLoginInfo(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_role', role);
  }

  /// -------------------- LOGOUT --------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }

  /// -------------------- INTERNAL POST HANDLER --------------------
  static Future<Map<String, dynamic>> _postAction(String action, Map<String, String> data) async {
    try {
      final payload = {'action': action, ...data};
      final response = await http.post(Uri.parse(_scriptUrl), body: payload);

      if (response.statusCode == 200) return _parseResponse(response.body);

      // Handle redirect (302)
      if (response.statusCode == 302) {
        final getUrl = Uri.parse(
          '${_scriptUrl}?${payload.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}',
        );
        final getResponse = await http.get(getUrl);
        return _parseResponse(getResponse.body);
      }

      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  /// -------------------- RESPONSE PARSER --------------------
  static Map<String, dynamic> _parseResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) return {'success': true, 'data': decoded};
      return decoded as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Invalid JSON response'};
    }
  }
}