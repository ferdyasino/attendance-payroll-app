import 'package:flutter/material.dart';
import '../widgets/header_section.dart';
import '../widgets/calendar_section.dart';
import '../widgets/time_logs_section.dart';
import '../widgets/admin_dashboard_section.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),

            // PAGE INDICATOR (optional but useful)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(0),
                  const SizedBox(width: 6),
                  _dot(1),
                  const SizedBox(width: 6),
                  _dot(2),
                ],
              ),
            ),

            // SWIPEABLE CONTENT
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: const [
                  TimeLogsSection(),
                  CalendarSection(),
                  AdminDashboardSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    final isActive = currentPage == index;

    return Container(
      width: isActive ? 10 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange : Colors.grey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
