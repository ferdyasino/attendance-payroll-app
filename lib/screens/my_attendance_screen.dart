import 'package:flutter/material.dart';
import '../widgets/header_section.dart';
import '../widgets/calendar_section.dart';
import '../widgets/time_logs_section.dart';
import '../widgets/admin_dashboard_section.dart';
import '../services/session_manager.dart';
import '../screens/login_screen.dart';

class MyAttendanceScreen extends StatefulWidget {
  final String userEmail;
  const MyAttendanceScreen({super.key, required this.userEmail});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  /// =========================
  /// LOGOUT FUNCTION (UNCHANGED)
  /// =========================
  Future<void> _logout() async {
    await SessionManager.clearSession();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      /// =========================
      /// BODY REPLACED WITH STACK ONLY (FIX)
      /// =========================
      body: Stack(
        children: [
          // =========================
          // MAIN UI (UNCHANGED)
          // =========================
          SafeArea(
            child: Column(
              children: [
                const HeaderSection(),

                // PAGE INDICATOR
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
                    children: [
                      TimeLogsSection(userEmail: widget.userEmail),
                      const CalendarSection(),
                      const AdminDashboardSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // FLOATING TOP BAR (NEW UI ONLY)
          // =========================
          Positioned(
            top: 5,
            left: 5,
            right: 5,
            child: _floatingTopBar(),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// FLOATING GLASS BAR
  /// =========================
  Widget _floatingTopBar() {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.logout,
            color: Colors.white,
            size: 22,
          ),
          onPressed: _logout,
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
