import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<Attendance>> futureAttendanceList;

  @override
  void initState() {
    super.initState();
    futureAttendanceList = AttendanceService.fetchAttendance();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green.shade200;
      case 'absent':
        return Colors.red.shade200;
      case 'late':
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Attendance>>(
        future: futureAttendanceList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance records found.'));
          } else {
            final attendanceList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final record = attendanceList[index];
                return Card(
                  color: getStatusColor(record.status),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 40, color: Colors.black54),
                    title: Text(
                      'Employee ID: ${record.employeeId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Date: ${record.date}\n'
                          'Time In: ${record.timeIn}\n'
                          'Time Out: ${record.timeOut}\n'
                          'Status: ${record.status}\n'
                          'Late: ${record.lateMinutes} mins',
                    ),

                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
