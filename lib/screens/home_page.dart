import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../providers/auth_provider.dart';
import 'payroll_history_screen.dart';
import 'payroll_summary_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final int employeeId = 1; // Replace with actual logged-in employee ID

  void _handleAction(BuildContext context, Future<void> Function() action,
      String successMsg) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("✅ $successMsg")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Payroll Actions
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isAdmin) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PayrollSummaryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.summarize),
                      label: const Text("Payroll Summary"),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PayrollHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text("My Payroll"),
              ),
              const Divider(height: 20),
              // Attendance Actions
              ElevatedButton(
                onPressed: () => _handleAction(context,
                    () => AttendanceService.clockIn(employeeId), "Clocked In"),
                child: const Text("⏱ Clock In"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.clockOut(employeeId),
                    "Clocked Out"),
                child: const Text("⏱ Clock Out"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break1In(employeeId),
                    "Break 1 Started"),
                child: const Text("☕ Break 1 In"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break1Out(employeeId),
                    "Break 1 Ended"),
                child: const Text("☕ Break 1 Out"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.lunchIn(employeeId),
                    "Lunch Started"),
                child: const Text("🍽 Lunch In"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.lunchOut(employeeId),
                    "Lunch Ended"),
                child: const Text("🍽 Lunch Out"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break2In(employeeId),
                    "Break 2 Started"),
                child: const Text("☕ Break 2 In"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break2Out(employeeId),
                    "Break 2 Ended"),
                child: const Text("☕ Break 2 Out"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break3In(employeeId),
                    "Break 3 Started"),
                child: const Text("☕ Break 3 In"),
              ),
              ElevatedButton(
                onPressed: () => _handleAction(
                    context,
                    () => AttendanceService.break3Out(employeeId),
                    "Break 3 Ended"),
                child: const Text("☕ Break 3 Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
