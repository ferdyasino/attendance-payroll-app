import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmployeeOnboardingService {
  static final String _scriptUrl = dotenv.env['EMPLOYEES_SCRIPT_URL'] ?? '';
  static final String _usersScriptUrl = dotenv.env['USERS_SCRIPT_URL'] ?? '';
  static final String _oldAttendanceUrl = dotenv.env['ATTENDANCE_SHEET_URL'] ?? '';

  static String normalizeStatus(String? status) {
    if (status == null) return 'Active';
    final s = status.trim().toLowerCase();
    return (s == 'inactive') ? 'Inactive' : 'Active';
  }

  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final res = await http.get(Uri.parse('$_scriptUrl?action=list'));
      if (res.statusCode != 200) throw Exception('Failed to load employees');

      final body = jsonDecode(res.body);
      if (body['success'] != true) throw Exception(body['message'] ?? 'Failed to load employees');

      return List<Map<String, dynamic>>.from(body['data']);
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

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

  static Future<bool> upsertEmployee({
    String? employeeId,
    required String fullName,
    required String email,
    required String department,
    required String position,
    required String setup,
    String? status,
  }) async {
    final normalizedStatus = normalizeStatus(status);
    final isUpdate = employeeId != null && employeeId.isNotEmpty;

    try {
      final res = await http.post(
        Uri.parse(_scriptUrl),
        body: {
          'action': isUpdate ? 'update' : 'add',
          'employeeId': employeeId ?? '',
          'fullName': fullName,
          'email': email,
          'department': department,
          'position': position,
          'setup': setup,
          'status': normalizedStatus,
        },
      );

      if (res.statusCode != 200 && res.statusCode != 302) return false;

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
      }

      return true;
    } catch (e) {
      print('Error adding/updating employee: $e');
      return false;
    }
  }

  static Future<bool> setInactive(String employeeId) async {
    if (employeeId.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse(_scriptUrl),
        body: {'action': 'delete', 'employeeId': employeeId},
      );

      return res.statusCode == 200 || res.statusCode == 302;
    } catch (e) {
      print('Error deactivating employee: $e');
      return false;
    }
  }

  /// FINAL: Matches GoogleSheetService parsing exactly
  static Future<List<Map<String, dynamic>>> fetchEmployeesFromOldAttendance() async {
    if (_oldAttendanceUrl.isEmpty) {
      print('Attendance sheet URL is empty');
      return [];
    }

    try {
      final res = await http.get(Uri.parse(_oldAttendanceUrl));
      if (res.statusCode != 200) {
        print('HTTP Error fetching attendance sheet: ${res.statusCode}');
        return [];
      }

      String jsonText = res.body.trim();

      // Robust stripping – handles all known Google formats
      if (jsonText.startsWith('/*O_o*/')) {
        jsonText = jsonText.substring(jsonText.indexOf('{'));
        jsonText = jsonText.substring(0, jsonText.lastIndexOf(')'));
      } else if (jsonText.startsWith('google.visualization.Query.setResponse')) {
        jsonText = jsonText.substring(jsonText.indexOf('(') + 1, jsonText.lastIndexOf(')'));
      } else if (jsonText.contains('google.visualization.Query.setResponse')) {
        final match = RegExp(r'google\.visualization\.Query\.setResponse\((.*)\);?', dotAll: true)
            .firstMatch(jsonText);
        if (match != null) jsonText = match.group(1)!;
      }

      final Map<String, dynamic> data = jsonDecode(jsonText);
      final List<dynamic> rows = data['table']['rows'];

      dynamic get(int r, int c) {
        final cell = rows[r]['c']?[c];
        return cell != null ? (cell['f'] ?? cell['v']) : null;
      }

      final Set<String> seenNames = {};
      final List<Map<String, dynamic>> employees = [];
      String currentDept = "Unknown Department";

      for (int r = 0; r < rows.length; r++) {
        final colA = get(r, 0);
        final nameCell = get(r, 3);

        // Department header
        if (colA is String && colA.toString().trim().isNotEmpty && (nameCell == null || nameCell.toString().trim().isEmpty)) {
          currentDept = colA.toString().trim();
          continue;
        }

        if (nameCell == null) continue;

        final String fullName = nameCell.toString().trim();
        if (fullName.isEmpty || seenNames.contains(fullName)) continue;

        seenNames.add(fullName);

        final String posSetupRaw = (get(r, 2)?.toString() ?? "").trim();
        String setup = "OFFICE";
        final upper = posSetupRaw.toUpperCase();
        if (upper.contains("WFH")) setup = "WFH";
        else if (upper.contains("HYBRID")) setup = "HYBRID";
        else if (upper.contains("FLEX")) setup = "WFH";

        final position = posSetupRaw
            .replaceAll(RegExp(r'\s*(WFH|HYBRID|FLEXI?)\s*', caseSensitive: false), '')
            .trim();

        final baseEmail = fullName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z ]'), '')
            .trim()
            .split(RegExp(r'\s+'))
            .join('.');

        final email = '$baseEmail@oldsheet.local';

        employees.add({
          'fullName': fullName,
          'department': currentDept,
          'setup': setup,
          'position': position,
          'email': email,
          'status': 'Active',
        });
      }

      employees.sort((a, b) => a['fullName'].compareTo(b['fullName']));

      print('IMPORT SUCCESS: ${employees.length} employees loaded from attendance sheet');
      return employees;
    } catch (e, stack) {
      print('IMPORT ERROR: $e');
      print(stack);
      return [];
    }
  }
}