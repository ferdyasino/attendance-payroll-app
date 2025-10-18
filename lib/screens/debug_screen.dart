import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _token = '';
  bool _healthy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await AuthService.getToken();
    setState(() {
      _token = t ?? '';
    });
  }

  Future<void> _checkHealth() async {
    setState(() => _loading = true);
    final ok = await ApiService.checkServerHealth();
    setState(() {
      _healthy = ok;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base URL: ${Constants.baseUrl}'),
            const SizedBox(height: 12),
            Text('Stored token: ${_token.isEmpty ? '<none>' : _token.substring(0, _token.length > 40 ? 40 : _token.length) + (_token.length>40? '...':'')}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _checkHealth,
              child: _loading ? const CircularProgressIndicator() : const Text('Check Health'),
            ),
            const SizedBox(height: 12),
            Text('Healthy: ${_healthy ? 'yes' : 'no'}'),
          ],
        ),
      ),
    );
  }
}
