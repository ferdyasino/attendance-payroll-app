// screens/my_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_sheet_service.dart';
import '../models/employee.dart';

class MyAttendanceScreen extends StatelessWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Employee>>(
        future: GoogleSheetService().fetchEmployees(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          // Error or no data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No attendance data found"),
                ],
              ),
            );
          }

          // Get current signed-in Google user
          final currentUser = GoogleSignIn().currentUser;
          if (currentUser == null) {
            return const Center(child: Text("Not signed in"));
          }

          final currentEmail = currentUser.email.toLowerCase();

          // Find employee with matching email
          final myEmployee = snapshot.data!.firstWhere(
            (e) => e.email.toLowerCase() == currentEmail,
            orElse: () => Employee(
              department: "—",
              position: "—",
              setup: "—",
              fullName: currentUser.displayName ?? "You",
              email: currentEmail,
              records: [],
            ),
          );

          // No records
          if (myEmployee.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No attendance records yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Sort newest first
          final sortedRecords = myEmployee.records
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final record = sortedRecords[index];

              final bool hasOT = record.totalOT != null &&
                  record.totalOT!.trim().isNotEmpty &&
                  record.totalOT != "0";

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: record.isPresent
                    ? (hasOT ? Colors.green.shade50 : Colors.blue.shade50)
                    : Colors.red.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    "${record.date} • ${record.day}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.login,
                              size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text("In: ${record.inTime ?? "—"}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.logout,
                              size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text("Out: ${record.outTime ?? "—"}"),
                        ],
                      ),
                    ],
                  ),
                  trailing: hasOT
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${record.totalOT} mins",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : (record.isPresent
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
