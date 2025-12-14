import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await _loadEnv();

  // Check critical Google Apps Script URLs
  await _checkUrl("USERS_SCRIPT_URL", dotenv.env['USERS_SCRIPT_URL'] ?? '');
  await _checkUrl("ATTENDANCE_SHEET_URL", dotenv.env['ATTENDANCE_SHEET_URL'] ?? '');
  await _checkUrl("DEPARTMENTS_SCRIPT_URL", dotenv.env['DEPARTMENTS_SCRIPT_URL'] ?? '');

  runApp(const MyApp());
}

/// Load .env and log results
Future<void> _loadEnv() async {
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
      print("DEPARTMENTS_SCRIPT_URL: ${dotenv.env['DEPARTMENTS_SCRIPT_URL']}");
      print("DEV_EMAIL: ${dotenv.env['DEV_EMAIL']}");
    }
  } catch (e) {
    print("❌ Failed to load .env file: $e");
  }
}

/// Test if the given URL is reachable
Future<void> _checkUrl(String name, String url) async {
  if (url.isEmpty) {
    print("⚠️ $name is not set in .env");
    return;
  }

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print("✅ $name is reachable");
    } else {
      print("⚠️ $name returned HTTP ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Failed to reach $name: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance & Payroll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
      ),
      // Start with LoginScreen
      home: const LoginScreen(),
      // Centralized named routes
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        // Dashboard requires parameters, handle via Navigator.pushReplacement
      },
    );
  }
}

/// Centralized route names
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}
