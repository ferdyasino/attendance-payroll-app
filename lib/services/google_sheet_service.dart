// services/google_sheet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/employee.dart';

class GoogleSheetService {
  // -------------------------
  // Load URLs from .env safely
  // -------------------------
  String get usersSheetUrl => dotenv.env['USERS_SHEET_URL'] ?? '';
  String get attendanceSheetUrl => dotenv.env['ATTENDANCE_SHEET_URL'] ?? '';

  // -------------------------
  // Parse shifts like "9PM-6AM"
  // -------------------------
  Map<String, String?> parseShiftTimes(String? shift) {
    if (shift == null || shift.trim().isEmpty) return {'start': null, 'end': null};
    final regex = RegExp(
      r'(\d{1,2}(?::\d{2})?)\s*(AM|PM)?\s*[-–]\s*(\d{1,2}(?::\d{2})?)\s*(AM|PM)?',
      caseSensitive: false,
    );
    final match = regex.firstMatch(shift);
    if (match == null) return {'start': null, 'end': null};

    String formatTime(String time, String? period) {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
      final p = (period ?? '').toUpperCase();

      if (p.isEmpty) {
        final isPM = hour >= 12;
        hour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$hour:$minute ${isPM ? 'PM' : 'AM'}';
      } else {
        hour = hour == 12 ? 12 : (hour % 12 == 0 ? 12 : hour % 12);
        return '$hour:$minute $p';
      }
    }

    final start = formatTime(match.group(1)!, match.group(2));
    final end = formatTime(match.group(3)!, match.group(4));
    return {'start': start, 'end': end};
  }

  String? extractRealTime(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM))', caseSensitive: false).firstMatch(text);
    return match?.group(1);
  }

  // -------------------------
  // Users
  // -------------------------
  Future<List<Map<String, String>>> fetchAllUsers() async {
    final url = usersSheetUrl;
    if (url.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      String jsonText = response.body;
      if (jsonText.startsWith('/*O_o*/')) {
        jsonText = jsonText.substring(jsonText.indexOf('{'));
        jsonText = jsonText.substring(0, jsonText.lastIndexOf(')'));
      } else if (jsonText.startsWith('google.visualization.Query.setResponse')) {
        jsonText = jsonText.substring(jsonText.indexOf('(') + 1, jsonText.lastIndexOf(')'));
      }

      final data = jsonDecode(jsonText);
      final rows = data['table']['rows'] as List<dynamic>? ?? [];
      final List<Map<String, String>> users = [];

      for (var row in rows.skip(1)) {
        final email = row['c']?[1]?['v']?.toString().trim() ?? "";
        final role = row['c']?[2]?['v']?.toString().trim() ?? "USER";
        if (email.isNotEmpty) users.add({'email': email, 'role': role});
      }

      return users;
    } catch (e) {
      print("Error fetching all users: $e");
      return [];
    }
  }

  Future<Map<String, String>?> fetchUserByEmail(String email) async {
    final users = await fetchAllUsers();
    return users.firstWhereOrNull((u) => u['email']?.toLowerCase() == email.toLowerCase());
  }

  Future<bool> isEmailAllowed(String email) async {
    final user = await fetchUserByEmail(email);
    return user != null;
  }

  Future<String> getUserRole(String email) async {
    final user = await fetchUserByEmail(email);
    return user?['role'] ?? "USER";
  }

  // -------------------------
  // Attendance / Employees
  // -------------------------
  Future<List<Employee>> fetchEmployees() async {
    final url = attendanceSheetUrl;
    if (url.isEmpty) return [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Failed to load attendance');

      String jsonText = response.body;
      if (jsonText.startsWith('/*O_o*/')) {
        jsonText = jsonText.substring(jsonText.indexOf('{'));
        jsonText = jsonText.substring(0, jsonText.lastIndexOf(')'));
      } else if (jsonText.startsWith('google.visualization.Query.setResponse')) {
        jsonText = jsonText.substring(jsonText.indexOf('(') + 1, jsonText.lastIndexOf(')'));
      }

      final Map<String, dynamic> data = jsonDecode(jsonText);
      final List<dynamic> rows = data['table']['rows'];

      dynamic get(int r, int c) {
        final cell = rows[r]['c']?[c];
        return cell != null ? (cell['f'] ?? cell['v']) : null;
      }

      final dayBlocks = <Map<String, dynamic>>[
        {'date': get(0,4),  'day': get(1,4),  'shift':4,  'in':5,  'out':6,  'tot':13},
        {'date': get(0,14), 'day': get(1,14), 'shift':14, 'in':15, 'out':16, 'tot':23},
        {'date': get(0,24), 'day': get(1,24), 'shift':24, 'in':25, 'out':26, 'tot':33},
        {'date': get(0,34), 'day': get(1,34), 'shift':34, 'in':35, 'out':36, 'tot':43},
        {'date': get(0,44), 'day': get(1,44), 'shift':44, 'in':45, 'out':46, 'tot':53},
        {'date': get(0,54), 'day': get(1,54), 'shift':54, 'in':55, 'out':56, 'tot':63},
        {'date': get(0,64), 'day': get(1,64), 'in':64, 'out':65},
      ].where((b) => b['date'] != null).toList();

      final Map<String, Employee> employeeMap = {};
      String currentDept = "Unknown";

      for (int r = 4; r < rows.length; r++) {
        final colA = get(r, 0);
        final name = get(r, 3);
        final email = get(r, 1)?.toString().trim() ?? "";

        if (colA is String && colA.trim().isNotEmpty && name == null) {
          currentDept = colA.trim();
          continue;
        }
        if (name == null) continue;

        final String fullName = name.toString().trim();
        final String key = fullName;

        if (!employeeMap.containsKey(key)) {
          employeeMap[key] = Employee(
            department: currentDept,
            position: (get(r, 2)?.toString() ?? "").trim(),
            setup: (get(r, 2)?.toString() ?? "OFFICE").trim(),
            fullName: fullName,
            email: email,
            records: [],
          );
        }

        final emp = employeeMap[key]!;

        for (final block in dayBlocks) {
          final date = block['date']?.toString().trim() ?? "";
          final day = block['day']?.toString().trim() ?? "";

          final rawShift = block.containsKey('shift') ? get(r, block['shift'])?.toString() : null;
          final rawIn = get(r, block['in'])?.toString();
          final rawOut = block.containsKey('out') ? get(r, block['out'])?.toString() : null;
          final totalOT = block.containsKey('tot') ? get(r, block['tot'])?.toString() : null;

          final shiftTimes = parseShiftTimes(rawShift);
          final String? shiftStart = shiftTimes['start'];
          final String? shiftEnd = shiftTimes['end'];

          String? inTime;
          if (rawIn != null) {
            final txt = rawIn.trim();
            if (txt.contains("ONTIME") || txt == "PRESHIFT" || txt == "LATE-COMMENT") {
              inTime = extractRealTime(txt) ?? shiftStart;
            }
          }

          String? outTime;
          if (rawOut != null) {
            final txt = rawOut.trim();
            if (txt == "OUT-ONTIME") {
              outTime = shiftEnd;
            } else if (txt.contains("POSTSHIFT") || txt.contains("EARLY-OUT") || txt.contains("MANAGEMENT")) {
              outTime = extractRealTime(txt) ?? shiftEnd;
            }
          }

          if (rawShift != null || inTime != null || outTime != null || totalOT != null) {
            emp.records.add(AttendanceRecord(
              date: date,
              day: day,
              shift: rawShift?.trim(),
              inTime: inTime,
              outTime: outTime,
              totalOT: totalOT,
            ));
          }
        }
      }

      final List<Employee> result = employeeMap.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      return result;
    } catch (e) {
      print("Error fetching employees: $e");
      return [];
    }
  }
}

/// Extension for firstWhereOrNull
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
