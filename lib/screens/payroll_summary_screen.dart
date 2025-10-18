import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payroll_provider.dart';
import '../providers/auth_provider.dart';
import '../models/payroll.dart';

class PayrollSummaryScreen extends StatefulWidget {
  const PayrollSummaryScreen({super.key});

  @override
  State<PayrollSummaryScreen> createState() => _PayrollSummaryScreenState();
}

class _PayrollSummaryScreenState extends State<PayrollSummaryScreen> {
  final String _selectedMonth = _getCurrentMonth();
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  static String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSummary() async {
    final provider = context.read<PayrollProvider>();
    try {
      final summary = await provider.getPayrollSummary(_selectedMonth);
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    if (!authProvider.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied: Admin privileges required'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMonthPicker(),
          ),
        ],
      ),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildEmployeeList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComputePayrollDialog(),
        child: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month: $_selectedMonth',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryItem('Total Employees', _summary['totalEmployees']?.toString() ?? '0'),
            _buildSummaryItem('Total Payout', '₱${(_summary['totalPayout'] ?? 0.0).toStringAsFixed(2)}'),
            _buildSummaryItem('Total Overtime', '₱${(_summary['totalOvertime'] ?? 0.0).toStringAsFixed(2)}'),
            _buildSummaryItem('Total Deductions', '₱${(_summary['totalDeductions'] ?? 0.0).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    final payrolls = (_summary['payrolls'] as List?)?.cast<Payroll>() ?? [];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Employee Payrolls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payrolls.length,
            itemBuilder: (context, index) {
              final payroll = payrolls[index];
              return ListTile(
                title: Text(payroll.userName ?? 'Unknown Employee'),
                subtitle: Text(payroll.userEmail ?? ''),
                trailing: Text('₱${payroll.totalPay.toStringAsFixed(2)}'),
                onTap: () {
                  // TODO: Navigate to PayrollDetailsScreen
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    // TODO: Implement month picker dialog
    // For now, just showing a simple dialog with current month
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: const Text('Month picker to be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showComputePayrollDialog() async {
    // TODO: Implement compute payroll dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compute Payroll'),
        content: const Text('Select employee and month to compute payroll'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement payroll computation
              Navigator.pop(context);
            },
            child: const Text('Compute'),
          ),
        ],
      ),
    );
  }
}