import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DepartmentService {
  String get attendanceSheetUrl => dotenv.env['ATTENDANCE_SHEET_URL'] ?? '';
  String get departmentsScriptUrl => dotenv.env['DEPARTMENTS_SCRIPT_URL'] ?? '';

  /// Fetch old (read-only) departments
  Future<List<Map<String, dynamic>>> fetchOldDepartments() async {
    if (attendanceSheetUrl.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(attendanceSheetUrl));
      if (response.statusCode != 200) throw Exception('Failed to load sheet');

      String jsonText = response.body;
      if (jsonText.startsWith('/*O_o*/')) {
        jsonText = jsonText.substring(jsonText.indexOf('{'));
        jsonText = jsonText.substring(0, jsonText.lastIndexOf(')'));
      } else if (jsonText.startsWith('google.visualization.Query.setResponse')) {
        jsonText = jsonText.substring(jsonText.indexOf('(') + 1, jsonText.lastIndexOf(')'));
      }

      final Map<String, dynamic> data = jsonDecode(jsonText);
      final List<dynamic> rows = data['table']['rows'];

      List<Map<String, dynamic>> departments = [];
      for (var row in rows) {
        final colA = row['c']?[0]?['v']?.toString().trim() ?? '';
        final colD = row['c']?[3]?['v']?.toString().trim();

        if (colA.isNotEmpty && (colD == null || colD.isEmpty)) {
          final parts = colA.split('-');
          final deptName = parts[0].trim();
          final deptHead = parts.length > 1 ? parts[1].trim() : '';
          departments.add({
            'departmentName': deptName,
            'departmentHead': deptHead,
            'defaultSetup': 'OFFICE',
            'addedToNewTab': false,
            'isOldSheet': true,
          });
        }
      }
      return departments;
    } catch (e) {
      print("Error fetching old departments: $e");
      return [];
    }
  }

  /// Fetch new departments
  Future<List<Map<String, dynamic>>> fetchNewDepartments() async {
    if (departmentsScriptUrl.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(departmentsScriptUrl));
      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) {
        return {
          'departmentName': (e['department'] ?? '').toString(),
          'departmentHead': (e['head'] ?? '').toString(),
          'defaultSetup': (e['setupDefault'] ?? 'OFFICE').toString(),
          'addedToNewTab': true,
          'isOldSheet': false,
        };
      }).toList();
    } catch (e) {
      print("Error fetching new departments: $e");
      return [];
    }
  }

  /// Combine old and new departments with correct status
  Future<List<Map<String, dynamic>>> fetchDepartmentsWithStatus() async {
    final oldDeps = await fetchOldDepartments();
    final newDeps = await fetchNewDepartments();
    final newNames = newDeps.map((e) => e['departmentName']).toSet();

    // Mark old departments that are already added
    final oldUpdated = oldDeps.map((e) {
      if (newNames.contains(e['departmentName'])) {
        return {...e, 'addedToNewTab': true};
      }
      return e;
    }).toList();

    // Merge new departments and old ones not already in new
    final combined = [...newDeps];
    for (var oldDept in oldUpdated) {
      if (!newNames.contains(oldDept['departmentName'])) {
        combined.add(oldDept);
      }
    }

    return combined;
  }

  /// Add a department to Google Sheet
  Future<bool> addDepartment(Map<String, dynamic> dept) async {
    if (departmentsScriptUrl.isEmpty) return false;
    try {
      final response = await http.post(Uri.parse(departmentsScriptUrl), body: {
        'action': 'add',
        'departmentName': dept['departmentName'] ?? '',
        'departmentHead': dept['departmentHead'] ?? '',
        'setupDefault': dept['defaultSetup'] ?? 'OFFICE',
      });
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print("Error adding department: $e");
      return false;
    }
  }

  /// Update a department in Google Sheet
  Future<bool> updateDepartment(Map<String, dynamic> dept) async {
    if (departmentsScriptUrl.isEmpty) return false;
    try {
      final response = await http.post(Uri.parse(departmentsScriptUrl), body: {
        'action': 'update',
        'departmentName': dept['departmentName'] ?? '',
        'departmentHead': dept['departmentHead'] ?? '',
        'setupDefault': dept['defaultSetup'] ?? 'OFFICE',
      });
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print("Error updating department: $e");
      return false;
    }
  }

  /// Delete a department from Google Sheet
  Future<bool> deleteDepartment(Map<String, dynamic> dept) async {
    if (departmentsScriptUrl.isEmpty) return false;
    try {
      final response = await http.post(Uri.parse(departmentsScriptUrl), body: {
        'action': 'delete',
        'departmentName': dept['departmentName'] ?? '',
      });
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print("Error deleting department: $e");
      return false;
    }
  }
}
