import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import 'payroll_history_screen.dart';
import 'payroll_summary_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.fetchTodayAttendance();
    });
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
              Consumer<AttendanceProvider>(
                builder: (context, attendanceProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Today's Status Card
                      if (attendanceProvider.todayAttendance != null)
                        Card(
                          color: attendanceProvider.isClockedIn
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      attendanceProvider.isClockedIn
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: attendanceProvider.isClockedIn
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      attendanceProvider.isClockedIn
                                          ? 'You are clocked in'
                                          : 'You have clocked out',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: attendanceProvider.isClockedIn
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (attendanceProvider.todayAttendance!.timeIn != null)
                                  Text(
                                    'Time In: ${attendanceProvider.todayAttendance!.timeIn}',
                                  ),
                                if (attendanceProvider.todayAttendance!.timeOut != null)
                                  Text(
                                    'Time Out: ${attendanceProvider.todayAttendance!.timeOut}',
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No attendance record for today',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Time In/Out Buttons
                      ElevatedButton.icon(
                        onPressed: attendanceProvider.isLoading
                            ? null
                            : () async {
                                final success = await attendanceProvider.timeIn();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? '✅ Time in successful'
                                          : '❌ ${attendanceProvider.error ?? "Time in failed"}'),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.login),
                        label: const Text("⏱ Time In"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: attendanceProvider.isLoading ||
                                !attendanceProvider.isClockedIn
                            ? null
                            : () async {
                                final success = await attendanceProvider.timeOut();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? '✅ Time out successful'
                                          : '❌ ${attendanceProvider.error ?? "Time out failed"}'),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.logout),
                        label: const Text("⏱ Time Out"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
