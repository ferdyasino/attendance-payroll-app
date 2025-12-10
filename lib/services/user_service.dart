// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class UserService {
  static String get usersSheetUrl => dotenv.env['USERS_SHEET_URL'] ?? '';
  static String get usersScriptUrl => dotenv.env['USERS_SCRIPT_URL'] ?? '';

  /// -------------------- Fetch all users from Google Sheet --------------------
  static Future<List<AppUser>> getUsers() async {
    final url = usersSheetUrl;
    if (url.isEmpty) {
      print("⚠️ USERS_SHEET_URL is not set in .env");
      return [];
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to load users (HTTP ${response.statusCode})");
      }

      // Remove Google Sheets JSON wrapper
      String jsonString = response.body;
      if (jsonString.startsWith('/*O_o*/')) {
        jsonString = jsonString.substring(jsonString.indexOf('{'));
        jsonString = jsonString.substring(0, jsonString.lastIndexOf(')'));
      } else if (jsonString.startsWith('google.visualization.Query.setResponse')) {
        jsonString = jsonString.substring(jsonString.indexOf('(') + 1, jsonString.lastIndexOf(')'));
      }

      final jsonData = jsonDecode(jsonString);
      final rows = jsonData["table"]["rows"] as List<dynamic>? ?? [];

      return rows.map((row) {
        final cells = row["c"];
        if (cells == null || cells.length < 3) return null;

        return AppUser(
          fullName: cells[0]?["v"]?.toString().trim() ?? "",
          email: cells[1]?["v"]?.toString().trim() ?? "",
          role: cells[2]?["v"]?.toString().trim().toUpperCase() ?? "USER",
        );
      }).whereType<AppUser>().toList();
    } catch (e) {
      print("UserService getUsers error: $e");
      return [];
    }
  }

  /// -------------------- Fetch single user by email --------------------
  static Future<AppUser?> getUserByEmail(String email) async {
    final users = await getUsers();
    return users.firstWhereOrNull((u) => u.email.toLowerCase() == email.toLowerCase());
  }

  /// -------------------- Get only admins --------------------
  static Future<List<AppUser>> getAdmins() async {
    final users = await getUsers();
    return users.where((u) => u.role.toUpperCase() == "ADMIN").toList();
  }

  /// -------------------- Add a new user --------------------
  static Future<bool> addUser({
    required String fullName,
    required String email,
    String role = "USER",
    bool useJson = false,
  }) async {
    return _sendUserRequest(
      data: {"fullName": fullName, "email": email, "role": role},
      useJson: useJson,
    );
  }

  /// -------------------- Update existing user --------------------
  static Future<bool> updateUser({
    required String fullName,
    required String email,
    required String role,
    bool useJson = false,
  }) async {
    return _sendUserRequest(
      data: {"fullName": fullName, "email": email, "role": role},
      useJson: useJson,
      action: "update",
    );
  }

  /// -------------------- Delete user --------------------
  static Future<bool> deleteUser(String email, {bool useJson = false}) async {
    return _sendUserRequest(
      data: {"email": email},
      useJson: useJson,
      action: "delete",
    );
  }

  /// -------------------- Internal helper for POST requests --------------------
  static Future<bool> _sendUserRequest({
    required Map<String, dynamic> data,
    bool useJson = false,
    String action = "add",
  }) async {
    final scriptUrl = usersScriptUrl;
    if (scriptUrl.isEmpty) {
      print("⚠️ USERS_SCRIPT_URL is not set in .env");
      return false;
    }

    try {
      http.Response response;

      // Add action to the payload
      final payloadData = {...data, "action": action};

      if (useJson) {
        final payload = jsonEncode(payloadData);
        print("Sending JSON POST: $payload");

        response = await http.post(
          Uri.parse(scriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        );
      } else {
        final payload = payloadData.map((k, v) => MapEntry(k, v.toString()));
        print("Sending form-urlencoded POST: $payload");

        response = await http.post(
          Uri.parse(scriptUrl),
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: payload,
        );
      }

      print("HTTP Status: ${response.statusCode}");
      print("Response body: ${response.body}");

      // Treat 200 or 302 as success
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e, st) {
      print("❌ UserService exception: $e");
      print(st);
      return false;
    }
  }
}

/// -------------------- Extension to mimic firstWhereOrNull --------------------
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
