import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/employee.dart';

class EmployeeService {
  String get employeeApiUrl => dotenv.env['EMPLOYEES_SCRIPT_URL'] ?? '';

  /// Fetch all employees from the Apps Script API
  Future<List<Employee>> fetchEmployees() async {
    final url = employeeApiUrl;
    if (url.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load employees');
      }

      final List<dynamic> list = jsonDecode(response.body);

      // Convert JSON → Employee model
      final employees = list.map((e) {
        return Employee(
          fullName: e["full name"] ?? "",
          email: e["email"] ?? "",
          department: e["department"] ?? "",
          position: e["position"] ?? "",
          setup: e["setup"] ?? "OFFICE",
          records: const [],
        );
      }).toList();

      // Sort alphabetically
      employees.sort((a, b) => a.fullName.compareTo(b.fullName));

      return employees;
    } catch (e) {
      print("Employee API error: $e");
      return [];
    }
  }

  /// Add a new employee
  Future<Map<String, dynamic>> addEmployee({
    required String fullName,
    required String email,
    required String department,
    required String position,
    String setup = "OFFICE",
  }) async {
    final url = employeeApiUrl;
    if (url.isEmpty) return {"success": false, "message": "API URL missing"};

    final payload = {
      "action": "add",
      "fullName": fullName,
      "email": email,
      "department": department,
      "position": position,
      "setup": setup,
    };

    try {
      final response = await http.post(Uri.parse(url), body: payload);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Soft delete an employee using their employeeId
  Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
    final url = employeeApiUrl;
    if (url.isEmpty) return {"success": false, "message": "API URL missing"};

    final payload = {
      "action": "delete",
      "employeeId": employeeId,
    };

    try {
      final response = await http.post(Uri.parse(url), body: payload);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
