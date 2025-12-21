import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/shift.dart';
import '../models/shift_type.dart';

class ShiftService {
  static String get shiftsScriptUrl => dotenv.env['SHIFTS_SCRIPT_URL'] ?? '';

  // ================= GET SCHEDULES =================
  static Future<List<Shift>> getSchedules({
    String? email,
    String? date,
    String? from,
    String? to,
  }) async {
    final url = shiftsScriptUrl;
    debugPrint('ShiftService.getSchedules URL: $url');
    if (url.isEmpty) return [];

    try {
      final uri = Uri.parse(url).replace(queryParameters: {
        if (email != null) 'email': email,
        if (date != null) 'date': date,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final rawList = List<Map<String, dynamic>>.from(data['data']);
        return rawList.map((e) => Shift.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e, st) {
      print('Error fetching schedules: $e\n$st');
      return [];
    }
  }

  // ================= GET SHIFT TYPES =================
  static Future<List<ShiftType>> getShiftTypes() async {
    final url = shiftsScriptUrl;
    if (url.isEmpty) return [];

    try {
      final uri = Uri.parse(url).replace(queryParameters: {'type': 'shifttypes'});

      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // GAS returns List<List<dynamic>> like [["DAY","08:00","17:00"], ...]
        final rawList = List<List<dynamic>>.from(
          (data['data'] as List).map((e) => List<dynamic>.from(e)),
        );

        return rawList.map((list) {
          return ShiftType(
            shiftName: list[0]?.toString() ?? '',
            startTime: list[1]?.toString() ?? '',
            endTime: list[2]?.toString() ?? '',
          );
        }).toList();
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e, st) {
      print('Error fetching shift types: $e\n$st');
      return [];
    }
  }

  // ================= POST SHIFT ACTION =================
  static Future<bool> postShiftAction(String action, Map<String, dynamic> payload) async {
    final url = shiftsScriptUrl;
    if (url.isEmpty) return false;

    try {
      final body = {'action': action, ...payload};

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e, st) {
      print('Error posting shift action: $e\n$st');
      return false;
    }
  }

  // ================= POST SHIFT TYPE ACTION =================
  static Future<bool> postShiftTypeAction(String action, Map<String, dynamic> payload) async {
    final body = {'actionType': 'shifttype', 'action': action, ...payload};
    return postShiftAction(action, body);
  }
}
