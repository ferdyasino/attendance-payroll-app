import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart'; // Centralized theme

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Validate essential URLs
  _checkEnv();

  runApp(const MyApp());
}

/// Validate that essential environment variables are loaded
void _checkEnv() {
  final usersSheetUrl = dotenv.env['USERS_SHEET_URL'] ?? '';
  final shiftsScriptUrl = dotenv.env['SHIFTS_SCRIPT_URL'] ?? '';
  final employeesScriptUrl = dotenv.env['EMPLOYEES_SCRIPT_URL'] ?? '';

  if (usersSheetUrl.isEmpty) {
    print("⚠️ USERS_SHEET_URL is not set in .env");
  } else {
    print("✅ USERS_SHEET_URL loaded: $usersSheetUrl");
  }

  if (shiftsScriptUrl.isEmpty) {
    print("⚠️ SHIFTS_SCRIPT_URL is not set in .env");
  } else {
    print("✅ SHIFTS_SCRIPT_URL loaded: $shiftsScriptUrl");
  }

  if (employeesScriptUrl.isEmpty) {
    print("⚠️ EMPLOYEES_SCRIPT_URL is not set in .env");
  } else {
    print("✅ EMPLOYEES_SCRIPT_URL loaded: $employeesScriptUrl");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance & Payroll',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Centralized theme
      home: const LoginScreen(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.dashboard: (context) => const LoginScreen(), // Replace with actual dashboard later
      },
    );
  }
}

/// Centralized route names
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}
