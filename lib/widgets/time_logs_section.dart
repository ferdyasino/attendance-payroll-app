import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TimeLogsSection extends StatefulWidget {
  final String userEmail;

  const TimeLogsSection({
    super.key,
    required this.userEmail,
  });

  @override
  State<TimeLogsSection> createState() => _TimeLogsSectionState();
}

class _TimeLogsSectionState extends State<TimeLogsSection> {
  static const String scriptUrl =
      "https://script.google.com/macros/s/AKfycbzNe-jFRlVoP1893v-sh3pdqXStAwUmilZB31LwB76c8bGYhbbAom1kaqCjEwy9Ewk-/exec";

  bool _isLoading = false;
  String _statusMessage = "";

  final List<Map<String, dynamic>> actions = [
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
      "title": "Break 1 In",
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

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // =========================
            // ACTION BUTTONS
            // =========================
            Expanded(
              flex: 2,
              child: GridView.builder(
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = actions[index];

                  return ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => logAttendance(item["title"]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item["color"],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item["icon"],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item["title"],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // TODAY LOGS PANEL
            // =========================
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Time Logs",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_statusMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                "No logs yet",
                                style: TextStyle(
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
