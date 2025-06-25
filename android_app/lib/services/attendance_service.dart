import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';

class AttendanceService {
  static Future<List<Attendance>> fetchAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/attendance'), // Use localhost if on Linux desktop
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Attendance.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
