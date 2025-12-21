// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';

class UserService {
  static String get usersSheetUrl => dotenv.env['USERS_SHEET_URL'] ?? '';
  static String get usersScriptUrl => dotenv.env['USERS_SCRIPT_URL'] ?? '';
  // -------------------- Fetch all users --------------------
  static Future<List<User>> getUsers() async {
    final url = usersSheetUrl;
    if (url.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      String jsonString = response.body;

      if (jsonString.startsWith('/*O_o*/')) {
        jsonString = jsonString.substring(jsonString.indexOf('{'));
        jsonString = jsonString.substring(0, jsonString.lastIndexOf(')'));
      } else if (jsonString.startsWith('google.visualization.Query.setResponse')) {
        jsonString =
            jsonString.substring(jsonString.indexOf('(') + 1, jsonString.lastIndexOf(')'));
      }

      final jsonData = jsonDecode(jsonString);
      final rows = jsonData['table']['rows'] as List<dynamic>? ?? [];

      return rows.map((row) {
        final c = row['c'];
        if (c == null || c.length < 3) return null;

        return User(
          fullName: c[0]?['v']?.toString() ?? '',
          email: c[1]?['v']?.toString() ?? '',
          role: c[2]?['v']?.toString().toUpperCase() ?? 'USER',
          status: c[5]?['v']?.toString() ?? '',
        );
      }).whereType<User>().toList();
    } catch (_) {
      return [];
    }
  }

  // -------------------- Get user by email --------------------
  static Future<User?> getUserByEmail(String email) async {
    final users = await getUsers();
    final target = email.trim().toLowerCase();
    return users.firstWhereOrNull((u) => u.email.toLowerCase() == target);
  }

  // -------------------- Add user --------------------
  static Future<bool> addUser({
    required String fullName,
    required String email,
    String role = 'USER',
  }) {
    return _send(
      action: 'add',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': role.trim().toUpperCase(),
      },
    );
  }

  // -------------------- Update user --------------------
  static Future<bool> updateUser({
    required String fullName,
    required String email,
    required String role,
    required String status,
  }) {
    return _send(
      action: 'update',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': role.trim().toUpperCase(),
        'status': status.trim(),
      },
    );
  }

  // -------------------- Delete user --------------------
  static Future<bool> deleteUser(String email) {
    return _send(
      action: 'update',
      data: {
        'email': email.trim().toLowerCase(),
        'status': 'INACTIVE',
      },
    );
  }

  // -------------------- POST helper --------------------
  static Future<bool> _send({
    required String action,
    required Map<String, String> data,
  }) async {
    final url = usersScriptUrl;
    if (url.isEmpty) return false;

    try {
      final payload = {
        ...data,
        'action': action,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 302) {
        return false;
      }

      try {
        final decoded = jsonDecode(response.body);
        return decoded is Map && decoded['success'] == true;
      } catch (_) {
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}

// -------------------- Helper --------------------
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
