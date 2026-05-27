// screens/attendance_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  final String userEmail;

  const AttendanceScreen({
    super.key,
    required this.userEmail,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ================= CONFIG =================

  // Replace with your deployed Apps Script Web App URL
  static const String scriptUrl =
      "https://script.google.com/macros/s/AKfycbzNe-jFRlVoP1893v-sh3pdqXStAwUmilZB31LwB76c8bGYhbbAom1kaqCjEwy9Ewk-/exec";

  bool _isLoading = false;
  String _statusMessage = "";

  // ================= ACTION BUTTONS =================

  final List<Map<String, dynamic>> attendanceActions = [
    {
      "title": "Time In",
      "icon": Icons.login,
      "color": Colors.green,
    },
    {
      "title": "Time Out",
      "icon": Icons.logout,
      "color": Colors.red,
    },
    {
      "title": "Break 1 Out",
      "icon": Icons.coffee,
      "color": Colors.orange,
    },
    {
      "title": "Break 1 in",
      "icon": Icons.coffee_outlined,
      "color": Colors.orangeAccent,
    },
    {
      "title": "Break 2 Out",
      "icon": Icons.free_breakfast,
      "color": Colors.deepOrange,
    },
    {
      "title": "Break 2 In",
      "icon": Icons.free_breakfast_outlined,
      "color": Colors.deepOrangeAccent,
    },
    {
      "title": "Break 3 Out",
      "icon": Icons.local_cafe,
      "color": Colors.brown,
    },
    {
      "title": "Break 3 In",
      "icon": Icons.local_cafe_outlined,
      "color": Colors.brown,
    },
    {
      "title": "Lunch Out",
      "icon": Icons.lunch_dining,
      "color": Colors.blue,
    },
    {
      "title": "Lunch In",
      "icon": Icons.restaurant,
      "color": Colors.indigo,
    },
  ];

  // ================= API =================

  Future<void> logAttendance(String actionType) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "action": "logAttendance",
          "email": widget.userEmail,
          "actionType": actionType,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["error"] != null) {
        throw Exception(data["error"]);
      }

      setState(() {
        _statusMessage = "${data["action"]} successful at ${data["time"]}";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${data["action"]} logged successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ================= HEADER =================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Logged In User",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.userEmail,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),

          // ================= STATUS =================

          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ================= BUTTON GRID =================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: attendanceActions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final item = attendanceActions[index];

                  return ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => logAttendance(item["title"]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item["color"],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item["icon"],
                          size: 38,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ================= LOADING =================

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
