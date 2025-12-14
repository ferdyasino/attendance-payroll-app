// screens/user_attendance_detail_page.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
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

  // Smart background color based on attendance
  Color getCardColor(AttendanceRecord r) {
    if (r.inTime == null && r.outTime == null) {
      if (r.shift == "NO SHIFT") return Colors.grey.shade200;
      return Colors.red.shade100; // Absent / Leave
    }
    if (r.totalOT != null && r.totalOT!.trim().isNotEmpty && r.totalOT != "0") {
      return Colors.green.shade100; // Has OT
    }
    return Colors.blue.shade100; // Regular present
  }

  // Smart status chip
  String getStatus(AttendanceRecord r) {
    if (r.inTime == null && r.outTime == null) {
      return r.shift == "NO SHIFT" ? "No Shift" : "Absent";
    }
    if (r.totalOT != null && r.totalOT!.trim().isNotEmpty && r.totalOT != "0") {
      return "Present + OT";
    }
    return "Present";
  }

  Color getStatusColor(AttendanceRecord r) {
    if (r.inTime == null && r.outTime == null) {
      return r.shift == "NO SHIFT" ? Colors.grey : Colors.red;
    }
    if (r.totalOT != null && r.totalOT!.trim().isNotEmpty && r.totalOT != "0") {
      return Colors.green;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Employee>>(
        future: futureEmployees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load data",
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No employees found"));
          }

          final employees = snapshot.data!;
          final employee = employees.firstWhere(
            (e) => e.fullName.toLowerCase().trim() == widget.userName.toLowerCase().trim(),
            orElse: () => Employee(
              department: "Unknown",
              position: "",
              setup: "",
              fullName: widget.userName,
              email: "",  
              records: [],
            ),
          );

          if (employee.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No records found for ${widget.userName}",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Sort newest first
          final sortedRecords = List<AttendanceRecord>.from(employee.records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final r = sortedRecords[index];

              return Card(
                elevation: 8,
                shadowColor: Colors.deepPurple.withOpacity(0.15),
                color: getCardColor(r),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.date,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Chip(
                            label: Text(
                              getStatus(r),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: getStatusColor(r),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.day,
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // Shift
                      if (r.shift != null && r.shift!.trim().isNotEmpty)
                        _buildRow(Icons.schedule, "Shift", r.shift!, Colors.deepPurple),

                      // Time In
                      _buildRow(
                        Icons.login,
                        "Time In",
                        r.inTime ?? "—",
                        r.inTime != null ? Colors.green.shade700 : Colors.grey,
                      ),

                      // Time Out
                      _buildRow(
                        Icons.logout,
                        "Time Out",
                        r.outTime ?? "—",
                        r.outTime != null ? Colors.orange.shade700 : Colors.grey,
                      ),

                      // Total OT
                      if (r.totalOT != null && r.totalOT!.trim().isNotEmpty && r.totalOT != "0")
                        _buildRow(
                          Icons.monetization_on_outlined,
                          "Total OT",
                          "${r.totalOT} mins",
                          Colors.green.shade700,
                          isBold: true,
                          fontSize: 18,
                        ),

                      const SizedBox(height: 8),
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

  Widget _buildRow(
    IconData icon,
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.deepPurple.shade400),
          const SizedBox(width: 14),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}