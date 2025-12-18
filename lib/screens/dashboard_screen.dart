import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/employee_onboarding_service.dart' as onboardingService;
import 'employees_screen.dart';
import 'employee_onboarding_screen.dart';
import 'login_screen.dart';
import 'users_screen.dart';
import 'departments_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  final String userRole;

  const DashboardScreen({
    super.key,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _userEmail;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _userEmail = widget.userEmail;
    _userRole = widget.userRole;
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildAppInfo(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI SECTIONS =================

  Widget _buildUserCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade700],
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back!",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userRole,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _actionCard(
              title: "Employees",
              subtitle: "View employees",
              icon: Icons.group,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeesScreen()),
              ),
            ),
            _actionCard(
              title: "My Attendance",
              subtitle: "Time records",
              icon: Icons.access_time,
              color: Colors.blue,
              onTap: () => _comingSoon(),
            ),
            _actionCard(
              title: "Payroll",
              subtitle: "Salary summary",
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              onTap: () => _comingSoon(),
            ),
            _actionCard(
              title: "Reports",
              subtitle: "Export data",
              icon: Icons.bar_chart,
              color: Colors.orange,
              onTap: () => _comingSoon(),
            ),
            _actionCard(
              title: "Departments",
              subtitle: "Manage departments",
              icon: Icons.apartment,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DepartmentsScreen()),
              ),
            ),
            _actionCard(
              title: "Users",
              subtitle: "Manage roles",
              icon: Icons.admin_panel_settings,
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              ),
            ),
            _actionCard(
              title: "Employee Onboarding",
              subtitle: "Complete profile",
              icon: Icons.person_add,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmployeeOnboardingScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("App Info", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _infoRow("Version", "1.0.0"),
            _infoRow("Database", "Google Sheets"),
            _infoRow("User", _userEmail),
            _infoRow("Role", _userRole),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(child: Text(": $value")),
        ],
      ),
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coming soon")),
    );
  }
}
