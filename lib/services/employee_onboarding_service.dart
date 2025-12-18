// ==================== FILE: employee_onboarding_service.dart ====================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmployeeOnboardingService {
  static final String _scriptUrl = dotenv.env['EMPLOYEES_SCRIPT_URL'] ?? '';
  static final String _usersScriptUrl = dotenv.env['USERS_SCRIPT_URL'] ?? '';

  /// -------------------- STATUS NORMALIZATION --------------------
  static String normalizeStatus(String? status) {
    if (status == null) return 'Active';
    final s = status.trim().toLowerCase();
    return (s == 'inactive') ? 'Inactive' : 'Active';
  }

  /// -------------------- GET ALL EMPLOYEES --------------------
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final res = await http.get(Uri.parse('$_scriptUrl?action=list'));
      if (res.statusCode != 200) throw Exception('Failed to load employees');

      final body = jsonDecode(res.body);
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to load employees');
      }

      return List<Map<String, dynamic>>.from(body['data']);
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  /// -------------------- GET EMPLOYEE BY EMAIL --------------------
  static Future<Map<String, dynamic>?> getEmployeeByEmail(String email) async {
    final employees = await getAllEmployees();
    try {
      return employees.firstWhere(
        (e) => (e['email']?.toString().toLowerCase() ?? '') == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// -------------------- ADD / UPDATE EMPLOYEE --------------------
  static Future<bool> upsertEmployee({
    String? employeeId,
    required String fullName,
    required String email,
    required String department,
    required String position,
    required String setup,
    required String status,
  }) async {
    final normalizedStatus = normalizeStatus(status);
    final existing = await getEmployeeByEmail(email);
    final isUpdate = existing != null;

    try {
      // -------------------- Employee Sheet --------------------
      final res = await http.post(
        Uri.parse(_scriptUrl),
        body: {
          'action': isUpdate ? 'update' : 'add',
          'employeeId': isUpdate ? existing!['employee id'] : '',
          'fullName': fullName,
          'email': email,
          'department': department,
          'position': position,
          'setup': setup,
          'status': normalizedStatus,
        },
      );

      if (res.statusCode != 200 && res.statusCode != 302) return false;

      final body = jsonDecode(res.body);
      if (body['success'] != true) {
        print('Employee save warning: ${body['message']}');
      }

      // -------------------- Users Sheet --------------------
      final userRes = await http.post(
        Uri.parse(_usersScriptUrl),
        body: {
          'action': isUpdate ? 'update' : 'add',
          'fullName': fullName,
          'email': email,
          'role': 'USER',
          'status': normalizedStatus,
        },
      );

      if (userRes.statusCode != 200 && userRes.statusCode != 302) {
        print('Warning: Users sheet sync may have failed');
      } else {
        final userBody = jsonDecode(userRes.body);
        if (userBody['success'] != true) {
          print('Users sheet warning: ${userBody['message']}');
        }
      }

      return true;
    } catch (e) {
      print('Error adding/updating employee: $e');
      return false;
    }
  }

  /// -------------------- SOFT DELETE --------------------
  static Future<bool> setInactive(String email) async {
    final existing = await getEmployeeByEmail(email);
    if (existing == null) return false;

    final empId = existing['employee id'];
    try {
      // -------------------- Employee Sheet --------------------
      final res = await http.post(Uri.parse(_scriptUrl), body: {
        'action': 'delete',
        'employeeId': empId,
      });
      if (res.statusCode != 200 && res.statusCode != 302) return false;

      final body = jsonDecode(res.body);
      if (body['success'] != true) {
        print('Employee delete warning: ${body['message']}');
      }

      // -------------------- Users Sheet --------------------
      final userRes = await http.post(Uri.parse(_usersScriptUrl), body: {
        'action': 'update',
        'email': email,
        'status': 'Inactive',
      });

      if (userRes.statusCode != 200 && userRes.statusCode != 302) {
        print('Warning: Users sheet update may have failed');
      } else {
        final userBody = jsonDecode(userRes.body);
        if (userBody['success'] != true) {
          print('Users sheet warning: ${userBody['message']}');
        }
      }

      return true;
    } catch (e) {
      print('Error deactivating employee: $e');
      return false;
    }
  }
}
