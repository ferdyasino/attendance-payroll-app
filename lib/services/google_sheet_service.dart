// services/google_sheet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';

class GoogleSheetService {
  final String sheetId = '1MILpQV-SM2cjYvqx2IermxhC169gEV0N5yZUGVoC_uU';
  final String sheetGid = '1146707741';

  Future<List<Employee>> fetchEmployees() async {
    final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:json&gid=$sheetGid');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load data');
    }

    final String body = response.body;
    final String jsonText = body.substring(47, body.length - 2);
    final Map<String, dynamic> data = json.decode(jsonText);
    final List<dynamic> rows = data['table']['rows'];

    // Helper to safely get cell value
    dynamic get(int row, int col) {
      final cell = rows[row]['c']?[col];
      return cell != null ? (cell['f'] ?? cell['v']) : null;
    }

    // Define day blocks (start column for each day)
    final dayBlocks = <Map<String, dynamic>>[
      {'date': get(0,4),  'day': get(1,4),  'shift':4,  'in':5,  'out':6,  'breakIn':7,  'breakOut':8,  'pre':9,  'post':10, 'app':11, 'tot_wop':12, 'tot':13},
      {'date': get(0,14), 'day': get(1,14), 'shift':14, 'in':15, 'out':16, 'breakIn':17, 'breakOut':18, 'pre':19, 'post':20, 'app':21, 'tot_wop':22, 'tot':23},
      {'date': get(0,24), 'day': get(1,24), 'shift':24, 'in':25, 'out':26, 'breakIn':27, 'breakOut':28, 'pre':29, 'post':30, 'app':31, 'tot_wop':32, 'tot':33},
      {'date': get(0,34), 'day': get(1,34), 'shift':34, 'in':35, 'out':36, 'breakIn':37, 'breakOut':38, 'pre':39, 'post':40, 'app':41, 'tot_wop':42, 'tot':43},
      {'date': get(0,44), 'day': get(1,44), 'shift':44, 'in':45, 'out':46, 'breakIn':47, 'breakOut':48, 'pre':49, 'post':50, 'app':51, 'tot_wop':52, 'tot':53},
      {'date': get(0,54), 'day': get(1,54), 'shift':54, 'in':55, 'out':56, 'breakIn':57, 'breakOut':58, 'pre':59, 'post':60, 'app':61, 'tot_wop':62, 'tot':63},
      // Saturday: only IN/OUT
      {'date': get(0,64), 'day': get(1,64), 'in':64, 'out':65},
    ].where((b) => b['date'] != null).toList();

    final Map<String, Employee> employeeMap = {};
    String currentDept = "Unknown";

    for (int r = 4; r < rows.length; r++) {
      final colA = get(r, 0);
      final colB = get(r, 1); // Position
      final colC = get(r, 2); // Setup
      final name = get(r, 3);

      // Department header
      if (colA is String && colA.contains("-") && name == null) {
        currentDept = colA.trim();
        continue;
      }
      if (name == null) continue;

      final String fullName = name.toString().trim();
      final String key = fullName;

      if (!employeeMap.containsKey(key)) {
        employeeMap[key] = Employee(
          department: currentDept,
          position: (colB?.toString() ?? "").trim(),
          setup: (colC?.toString() ?? "OFFICE").trim(),
          fullName: fullName,
          records: [],
        );
      }

      final emp = employeeMap[key]!;

      for (final block in dayBlocks) {
        final date = block['date'].toString();
        final day = block['day']?.toString() ?? "";

        final shift = block.containsKey('shift') ? get(r, block['shift'])?.toString() : null;
        final inTime = get(r, block['in'])?.toString();
        final outTime = block.containsKey('out') ? get(r, block['out'])?.toString() : null;
        final totalOT = block.containsKey('tot') ? (get(r, block['tot']) ?? get(r, block['tot_wop'])) : null;

        if (shift != null || inTime != null || outTime != null || totalOT != null) {
          emp.records.add(AttendanceRecord(
            date: date,
            day: day,
            shift: shift,
            inTime: inTime,
            outTime: outTime,
            breakIn: block.containsKey('breakIn') ? get(r, block['breakIn'])?.toString() : null,
            breakOut: block.containsKey('breakOut') ? get(r, block['breakOut'])?.toString() : null,
            preShiftOT: block.containsKey('pre') ? get(r, block['pre'])?.toString() : null,
            postShiftOT: block.containsKey('post') ? get(r, block['post'])?.toString() : null,
            approvedBy: block.containsKey('app') ? get(r, block['app'])?.toString() : null,
            totalOT: totalOT,
          ));
        }
      }
    }

    return employeeMap.values.toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
  }
}