import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmployeeOnboardingService {
  static final String _scriptUrl =
      dotenv.env['EMPLOYEES_SCRIPT_URL'] ?? '';

  /// -------------------- GET ALL EMPLOYEES --------------------
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final uri = Uri.parse('$_scriptUrl?action=list');
    final res = await http.get(uri);
    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load employees');
    }

    return List<Map<String, dynamic>>.from(body['data']);
  }

  /// -------------------- GET EMPLOYEE BY ID --------------------
  static Future<Map<String, dynamic>> getEmployeeById(String employeeId) async {
    final uri = Uri.parse('$_scriptUrl?action=getById&id=$employeeId');
    final res = await http.get(uri);
    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Employee not found');
    }

    return Map<String, dynamic>.from(body['data']);
  }

  /// -------------------- UPSERT EMPLOYEE --------------------
  /// If employeeId is null/empty → ADD
  /// If employeeId exists → UPDATE
  static Future<void> upsertEmployee({
    String? employeeId,
    required String fullName,
    required String email,
    required String department,
    required String position,
    required String setup, // PENDING | DONE | OFFICE
  }) async {
    final res = await http.post(
      Uri.parse(_scriptUrl),
      body: {
        'action': employeeId == null || employeeId.isEmpty ? 'add' : 'update',
        'employeeId': employeeId ?? '',
        'fullName': fullName,
        'email': email,
        'department': department,
        'position': position,
        'setup': setup,
      },
    );

    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Save failed');
    }
  }

  /// -------------------- SOFT DELETE --------------------
  static Future<void> setInactive(String employeeId) async {
    final res = await http.post(
      Uri.parse(_scriptUrl),
      body: {
        'action': 'delete',
        'employeeId': employeeId,
      },
    );

    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Delete failed');
    }
  }

  /// -------------------- IMPORT FROM OLD EMPLOYEES --------------------
  static Future<void> importFromOldEmployees() async {
    final res = await http.post(
      Uri.parse(_scriptUrl),
      body: {
        'action': 'import',
      },
    );

    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Import failed');
    }
  }
}
