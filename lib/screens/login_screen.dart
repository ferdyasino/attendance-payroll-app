// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/google_sheet_service.dart';
import '../services/session_manager.dart';
import '../screens/my_attendance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  final GoogleSheetService _sheetService = GoogleSheetService();

  late final String devEmail;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    devEmail = dotenv.env['DEV_EMAIL'] ?? '';
    _emailController = TextEditingController(text: devEmail);

    _prefillSavedEmail();
  }

  /// PREFILL SAVED EMAIL (NO AUTO LOGIN)
  Future<void> _prefillSavedEmail() async {
    final savedEmail = await SessionManager.getEmail();

    if (savedEmail != null && savedEmail.isNotEmpty) {
      print("Prefilling login field: $savedEmail");
      _emailController.text = savedEmail;
    }
  }

  /// LOGIN
  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    print("Attempting login: $email");

    bool authorized = false;

    try {
      final user = await _sheetService.fetchUserByEmail(email);

      if (user != null) {
        final sheetEmail =
            (user['email'] ?? "").toString().trim().toLowerCase();

        authorized = email == sheetEmail;
      }
    } catch (e) {
      print("Login error: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authorized) {
      // SAVE SESSION USING SESSION MANAGER
      await SessionManager.saveEmail(email);

      _goToDashboard(email: email);
    } else {
      _showAccessDenied();
    }
  }

  /// NAVIGATE
  void _goToDashboard({required String email}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MyAttendanceScreen(userEmail: email),
      ),
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}
