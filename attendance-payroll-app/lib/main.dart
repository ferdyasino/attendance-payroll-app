import 'package:flutter/material.dart';
import 'screens/home_page.dart'; // Home page of the app

void main() {
  runApp(const MyApp()); // ✅ Start with MyApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(), // 📍 Home screen
    );
  }
}
