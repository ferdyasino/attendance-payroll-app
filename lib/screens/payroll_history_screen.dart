import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payroll_provider.dart';
import '../models/payroll.dart';

class PayrollHistoryScreen extends StatefulWidget {
  const PayrollHistoryScreen({super.key});

  @override
  State<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends State<PayrollHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollProvider>().getUserPayrolls();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll History'),
      ),
      body: Consumer<PayrollProvider>(
        builder: (context, payrollProvider, child) {
          if (payrollProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (payrollProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${payrollProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => payrollProvider.getUserPayrolls(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (payrollProvider.payrolls.isEmpty) {
            return const Center(
              child: Text('No payroll records found'),
            );
          }

          return ListView.builder(
            itemCount: payrollProvider.payrolls.length,
            itemBuilder: (context, index) {
              final payroll = payrollProvider.payrolls[index];
              return PayrollListItem(payroll: payroll);
            },
          );
        },
      ),
    );
  }
}

class PayrollListItem extends StatelessWidget {
  final Payroll payroll;

  const PayrollListItem({
    super.key,
    required this.payroll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Payroll for ${payroll.month}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base Salary: ₱${payroll.baseSalary.toStringAsFixed(2)}'),
            Text('Overtime Pay: ₱${payroll.overtimePay.toStringAsFixed(2)}'),
            Text('Deductions: ₱${payroll.deductions.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text(
              'Total Pay: ₱${payroll.totalPay.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: Text(
          'Paid on\n${_formatDate(payroll.payDate)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          // TODO: Navigate to PayrollDetailsScreen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => PayrollDetailsScreen(payroll: payroll),
          //   ),
          // );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}