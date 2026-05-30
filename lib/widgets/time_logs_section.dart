import 'dart:convert';

import 'package:flutter/material.dart';
import '../utils/api_helper.dart';
import '../services/attendance_cache.dart';

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

  List<Map<String, dynamic>> _logs = [];

  final List<Map<String, dynamic>> actions = [
    {"title": "Time In", "icon": Icons.login, "color": Colors.green},
    {"title": "Time Out", "icon": Icons.logout, "color": Colors.red},
    {"title": "Break 1 Out", "icon": Icons.coffee, "color": Colors.orange},
    {
      "title": "Break 1 In",
      "icon": Icons.coffee_outlined,
      "color": Colors.orangeAccent
    },
    {
      "title": "Break 2 Out",
      "icon": Icons.free_breakfast,
      "color": Colors.deepOrange
    },
    {
      "title": "Break 2 In",
      "icon": Icons.free_breakfast_outlined,
      "color": Colors.deepOrangeAccent
    },
    {"title": "Break 3 Out", "icon": Icons.local_cafe, "color": Colors.brown},
    {
      "title": "Break 3 In",
      "icon": Icons.local_cafe_outlined,
      "color": Colors.brown
    },
    {"title": "Lunch Out", "icon": Icons.lunch_dining, "color": Colors.blue},
    {"title": "Lunch In", "icon": Icons.restaurant, "color": Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedLogs();
  }

  Future<void> _loadCachedLogs() async {
    final cached = await AttendanceCache.getLogs();

    if (!mounted) return;

    setState(() {
      _logs = cached;
    });
  }

  Future<void> logAttendance(String actionType) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      final data = await ApiHelper.postWithRedirect(
        url: scriptUrl,
        body: {
          "action": "logAttendance",
          "email": widget.userEmail,
          "actionType": actionType,
        },
      );

      if (!mounted) return;

      if (data["error"] != null) {
        throw Exception(data["error"]);
      }

      final newLog = {
        "action": data["action"],
        "time": data["time"],
      };

      setState(() {
        _statusMessage = "${data["action"]} successful at ${data["time"]}";
        _logs.insert(0, newLog);
      });

      await AttendanceCache.saveLogs(_logs);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${data["action"]} logged successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = "Error: $e";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

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
                        Icon(item["icon"], size: 20),
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
            // LOGS LIST
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                "No logs yet",
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log["action"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        log["time"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
