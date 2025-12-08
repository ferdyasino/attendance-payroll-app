// screens/employees_screen.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/google_sheet_service.dart';
import '../widgets/user_attendance_detail_page.dart'; // Now using the beautiful detail page

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GoogleSheetService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Attendance"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 6,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Employee>>(
        future: service.fetchEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text("Loading attendance data...", style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text("Failed to load data", style: TextStyle(fontSize: 18)),
                  Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No employees found", style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final employees = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];

              // Get latest record for OT display
              final latestRecord = emp.records.isNotEmpty
                  ? emp.records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
                  : null;

              final latestOT = latestRecord?.totalOT?.toString() ?? "0";

              return Card(
                elevation: 8,
                shadowColor: Colors.deepPurple.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserAttendanceDetailPage(
                          userName: emp.fullName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            emp.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emp.department,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${emp.position.isEmpty ? '—' : emp.position} • ${emp.setup}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              "Latest OT",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestOT,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: latestOT == "0" ? Colors.grey : Colors.green,
                              ),
                            ),
                            Text(
                              "hrs",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}