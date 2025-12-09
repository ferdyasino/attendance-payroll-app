// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'employees_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userEmail = '';
  String _userRole = 'USER';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final email = await AuthService.getCurrentUserEmail() ?? '';
    final role = email.isNotEmpty ? await AuthService.getUserRole(email) : 'USER';
    if (mounted) {
      setState(() {
        _userEmail = email;
        _userRole = role;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') _handleLogout(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
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
              // Welcome Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back!",
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _userRole,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions Title
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
              const SizedBox(height: 16),

              // Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildActionCard(
                    context,
                    title: "Employees",
                    subtitle: "View all attendance",
                    icon: Icons.group,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmployeesScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: "My Attendance",
                    subtitle: "Your time records",
                    icon: Icons.access_time,
                    color: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming soon!")),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: "Payroll",
                    subtitle: "Salary summary",
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Payroll module coming soon!")),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: "Reports",
                    subtitle: "Export data",
                    icon: Icons.bar_chart,
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reports coming soon!")),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "App Info",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Version", "1.0.0"),
                      _buildInfoRow("Database", "Google Sheets"),
                      _buildInfoRow("Authentication", "Email / Google Sheet"),
                      _buildInfoRow("User Email", _userEmail.isEmpty ? "-" : _userEmail),
                      _buildInfoRow("Role", _userRole),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(": $value", style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
