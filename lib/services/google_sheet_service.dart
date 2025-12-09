// services/google_sheet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';

class GoogleSheetService {
  final String sheetId = '1MILpQV-SM2cjYvqx2IermxhC169gEV0N5yZUGVoC_uU';
  final String sheetGid = '1146707741';

  // Helper: convert time string like "9PM-6AM" → { start: "9:00 PM", end: "6:00 AM" }
  Map<String, String?> parseShiftTimes(String? shift) {
    if (shift == null || shift.trim().isEmpty) return {'start': null, 'end': null};

    final regex = RegExp(r'(\d{1,2}(?::\d{2})?)\s*(AM|PM)?\s*[-–]\s*(\d{1,2}(?::\d{2})?)\s*(AM|PM)?', caseSensitive: false);
    final match = regex.firstMatch(shift);

    if (match == null) return {'start': null, 'end': null};

    String formatTime(String time, String? period) {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
      final p = (period ?? '').toUpperCase();

      if (p.isEmpty) {
        // Assume 24h logic
        final isPM = hour >= 12;
        hour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$hour:$minute ${isPM ? 'PM' : 'AM'}';
      } else {
        hour = hour == 12 ? 12 : (hour % 12 == 0 ? 12 : hour % 12);
        return '$hour:$minute ${p}';
      }
    }

    final start = formatTime(match.group(1)!, match.group(2));
    final end = formatTime(match.group(3)!, match.group(4));

    return {'start': start, 'end': end};
  }

  // Extract actual clock time from text like "POSTSHIFT 7:30 AM" or "LATE 10:15 PM"
  String? extractRealTime(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM))', caseSensitive: false).firstMatch(text);
    return match?.group(1);
  }

  Future<List<Employee>> fetchEmployees() async {
    final url = Uri.parse('https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:json&gid=$sheetGid');
    final response = await http.get(url);

    if (response.statusCode != 200) throw Exception('Failed to load sheet');

    final String jsonText = response.body.substring(47, response.body.length - 2);
    final Map<String, dynamic> data = json.decode(jsonText);
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

      // Detect department
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
          position: (get(r, 1)?.toString() ?? "").trim(),
          setup: (get(r, 2)?.toString() ?? "OFFICE").trim(),
          fullName: fullName,
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

        // Parse shift start/end times
        final shiftTimes = parseShiftTimes(rawShift);
        final String? shiftStart = shiftTimes['start'];
        final String? shiftEnd = shiftTimes['end'];

        // Resolve actual IN time
        String? inTime;
        if (rawIn != null) {
          final txt = rawIn.trim();
          if (txt.contains("ONTIME") || txt == "PRESHIFT" || txt == "LATE-COMMENT") {
            inTime = extractRealTime(txt) ?? shiftStart;
          }
        }

        // Resolve actual OUT time
        String? outTime;
        if (rawOut != null) {
          final txt = rawOut.trim();
          if (txt == "OUT-ONTIME") {
            outTime = shiftEnd;
          } else if (txt.contains("POSTSHIFT") || txt.contains("EARLY-OUT") || txt.contains("MANAGEMENT")) {
            outTime = extractRealTime(txt) ?? shiftEnd;
          }
        }

        // Only add if there's any data
        if (rawShift != null || inTime != null || outTime != null || totalOT != null) {
          emp.records.add(AttendanceRecord(
            date: date,
            day: day,
            shift: rawShift?.trim(),
            inTime: inTime,           // ← Now real time or null
            outTime: outTime,         // ← Now real time or null
            totalOT: totalOT,
          ));
        }
      }
    }

    final List<Employee> result = employeeMap.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return result;
  }
}