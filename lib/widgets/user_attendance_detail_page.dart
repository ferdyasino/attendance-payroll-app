// screens/user_attendance_detail_page.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/google_sheet_service.dart';

class UserAttendanceDetailPage extends StatefulWidget {
  final String userName;

  const UserAttendanceDetailPage({
    super.key,
    required this.userName,
  });

  @override
  State<UserAttendanceDetailPage> createState() => _UserAttendanceDetailPageState();
}

class _UserAttendanceDetailPageState extends State<UserAttendanceDetailPage> {
  late Future<List<Employee>> futureEmployees;

  @override
  void initState() {
    super.initState();
    futureEmployees = GoogleSheetService().fetchEmployees();
  }

  Color getCardColor(AttendanceRecord record) {
    if (record.inTime == null && record.outTime == null) {
      return Colors.red.shade100; // Absent
    }
    if (record.totalOT != null && record.totalOT > 0) {
      return Colors.green.shade100; // Has OT
    }
    if (record.inTime != null) {
      return Colors.blue.shade100; // Present
    }
    return Colors.grey.shade200;
  }

  String getStatusText(AttendanceRecord record) {
    if (record.inTime == null && record.outTime == null) return "Absent";
    if (record.totalOT != null && record.totalOT > 0) return "Present + OT";
    return "Present";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.userName} - Attendance",  // Fixed: was 'userName'
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: FutureBuilder<List<Employee>>(
        future: futureEmployees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data found"));
          }

          final employee = snapshot.data!.firstWhere(
            (e) => e.fullName.toLowerCase().trim() == widget.userName.toLowerCase().trim(),
            orElse: () => Employee(
              department: "Not Found",
              position: "",
              setup: "",
              fullName: widget.userName,
              records: [],
            ),
          );

          if (employee.records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No attendance records found", style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final sortedRecords = List<AttendanceRecord>.from(employee.records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final record = sortedRecords[index];

              return Card(
                elevation: 6,
                color: getCardColor(record),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${record.date} (${record.day})",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              getStatusText(record),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            backgroundColor: getCardColor(record).withOpacity(0.8),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (record.shift != null)
                        _infoRow(Icons.schedule, "Shift", record.shift!),
                      _infoRow(Icons.login, "Time In", record.inTime ?? "—"),
                      _infoRow(Icons.logout, "Time Out", record.outTime ?? "—"),
                      if (record.breakIn != null || record.breakOut != null) ...[
                        _infoRow(Icons.coffee, "Break In", record.breakIn ?? "—"),
                        _infoRow(Icons.coffee_outlined, "Break Out", record.breakOut ?? "—"),
                      ],
                      if (record.preShiftOT != null)
                        _infoRow(Icons.access_time, "Pre-OT", "${record.preShiftOT} hrs"),
                      if (record.postShiftOT != null)
                        _infoRow(Icons.nights_stay, "Post-OT", "${record.postShiftOT} hrs"),
                      if (record.totalOT != null && record.totalOT > 0)
                        _infoRow(Icons.monetization_on, "Total OT", "${record.totalOT} hrs", isHighlight: true),
                      if (record.approvedBy != null)
                        _infoRow(Icons.verified_user, "Approved By", record.approvedBy!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isHighlight ? Colors.green.shade700 : Colors.grey[700]),
          const SizedBox(width: 12),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlight ? 17 : 15,
                color: isHighlight ? Colors.green.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}