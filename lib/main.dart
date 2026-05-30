import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'screens/login_screen.dart';
import 'screens/my_attendance_screen.dart';
import 'services/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");

    if (dotenv.env.isEmpty) {
      print("⚠️ .env failed to load or is empty");
    } else {
      print("✅ .env loaded successfully");
      print("USERS_SHEET_URL: ${dotenv.env['USERS_SHEET_URL']}");
      print("ATTENDANCE_SHEET_URL: ${dotenv.env['ATTENDANCE_SHEET_URL']}");
      print("USERS_GID: ${dotenv.env['USERS_GID']}");
      print("ATTENDANCE_GID: ${dotenv.env['ATTENDANCE_GID']}");
      print("USERS_SCRIPT_URL: ${dotenv.env['USERS_SCRIPT_URL']}");
    }
  } catch (e) {
    print("❌ Failed to load .env file: $e");
  }

  // Check if the Google Apps Script URL is accessible
  final scriptUrl = dotenv.env['USERS_SCRIPT_URL'] ?? '';
  if (scriptUrl.isEmpty) {
    print("⚠️ USERS_SCRIPT_URL is not set in .env");
  } else {
    try {
      final response = await http.get(Uri.parse(scriptUrl));
      if (response.statusCode == 200) {
        print("✅ USERS_SCRIPT_URL is reachable");
      } else {
        print("⚠️ USERS_SCRIPT_URL returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Failed to reach USERS_SCRIPT_URL: $e");
    }
  }

  // 🔥 NEW: check session BEFORE app starts
  final savedEmail = await SessionManager.getEmail();

  runApp(MyApp(initialEmail: savedEmail));
}

class MyApp extends StatelessWidget {
  final String? initialEmail;

  const MyApp({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance & Payroll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
      ),

      // 🔥 UPDATED: persistent login routing
      home: initialEmail == null
          ? const LoginScreen()
          : MyAttendanceScreen(userEmail: initialEmail!),

      // Centralized routes (UNCHANGED)
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
      },
    );
  }
}

/// Centralized route names
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}
