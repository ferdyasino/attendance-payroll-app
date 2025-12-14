import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  late final TextEditingController _emailController;
  late final String devEmail;
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
    devEmail = dotenv.env['DEV_EMAIL'] ?? '';
    _emailController = TextEditingController(text: devEmail);
    _prefillSavedEmail();
    _loadAllUsers();
  }

  Future<void> _prefillSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_email');
    if (saved != null && saved.isNotEmpty) _emailController.text = saved;
  }

  Future<void> _loadAllUsers() async {
    try {
      _allUsers = await AuthService.fetchAllUsers();
    } catch (e) {
      _showMessage("Failed to load users: $e");
    }
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();

    // Safely find the user
    User? user;
    try {
      user = _allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email,
      );
    } catch (e) {
      user = null; // Not found
    }

    if (user == null) {
      _showMessage("Email not found or access denied");
    } else if (user.passwordHash.isEmpty) {
      // First-time login → set password
      await _setupPasswordFlow(user);
    } else {
      // Existing password → login
      await _passwordLoginFlow(user);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _setupPasswordFlow(User user) async {
    String? pass1 = await _promptPassword("Set Password");
    if (pass1 == null) return;

    String? pass2 = await _promptPassword("Verify Password");
    if (pass2 == null || pass1 != pass2) {
      _showMessage("Passwords do not match");
      return;
    }

    final res = await AuthService.setupPassword(email: user.email, password: pass1);
    if (res['success'] == true) {
      _showMessage("Password setup successful. Logging in...");
      await _passwordLoginFlow(user, password: pass1);
    } else {
      _showMessage(res['message'] ?? "Failed to setup password");
    }
  }

  Future<void> _passwordLoginFlow(User user, {String? password}) async {
    final pwd = password ?? await _promptPassword("Enter Password");
    if (pwd == null) return;

    final loginRes = await AuthService.login(user.email, pwd);
    if (loginRes['success'] == true) {
      final loggedInUser = loginRes['user'] as User;
      await AuthService.saveLoginInfo(loggedInUser.email, loggedInUser.role);
      _goToDashboard(loggedInUser.email, loggedInUser.role);
    } else {
      _showMessage(loginRes['message'] ?? "Invalid credentials");
    }
  }

  Future<String?> _promptPassword(String title) async {
    String? pass;
    await showDialog(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                pass = ctrl.text.trim();
                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
    if (pass != null && pass!.isEmpty) return null;
    return pass;
  }

  void _goToDashboard(String email, String role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashboardScreen(userEmail: email, userRole: role)),
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Login'),
              ),
              const SizedBox(height: 40),
              Text(
                "Only authorized employees can access this app.\nContact HR if you need access.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
