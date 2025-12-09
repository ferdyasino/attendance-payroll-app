// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/google_sheet_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final GoogleSheetService _sheetService = GoogleSheetService();

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    print("Attempting login with email: '$email'");

    bool authorized = false;

    try {
      // Fetch user by email from Google Sheet
      final user = await _sheetService.fetchUserByEmail(email);

      if (user != null) {
        final sheetEmail = (user['email'] ?? "").toString().trim().toLowerCase();
        final role = (user['role'] ?? "USER").toString();
        print("User found in sheet: email='$sheetEmail', role='$role'");

        // Compare input email with sheet email
        authorized = email == sheetEmail;
        print("Authorization check result: $authorized");
      } else {
        print("User not found in Google Sheet.");
        // Optionally, fetch and print all users for debugging
        final allUsers = await _sheetService.fetchAllUsers();
        print("All users in sheet for debugging:");
        for (var u in allUsers) {
          print(" - ${u['email']} (role: ${u['role']})");
        }
      }
    } catch (e) {
      print("Error fetching user from sheet: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authorized) {
      _goToDashboard();
    } else {
      _showAccessDenied();
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _showAccessDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Text("Access denied. Your email is not authorized."),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_history_outlined,
                  size: 80,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Attendance Payroll',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with your company email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Login'),
              ),
              const SizedBox(height: 40),
              Text(
                "Only authorized employees can access this app.\nContact HR if you need access.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}