import 'package:flutter/material.dart';

class AdminDashboardSection extends StatelessWidget {
  const AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _buildCard(
              context,
              title: "Employees / Users",
              icon: Icons.people,
              color: Colors.purple,
              subtitle: "Manage users",
            ),
            _buildCard(
              context,
              title: "Accounts / Department",
              icon: Icons.apartment,
              color: Colors.blue,
              subtitle: "Organize structure",
            ),
            _buildCard(
              context,
              title: "Shifts",
              icon: Icons.schedule,
              color: Colors.orange,
              subtitle: "Work schedules",
            ),
            _buildCard(
              context,
              title: "Payroll",
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              subtitle: "Salary system",
            ),
            _buildCard(
              context,
              title: "Reports",
              icon: Icons.bar_chart,
              color: Colors.red,
              subtitle: "Analytics & exports",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title clicked")),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
