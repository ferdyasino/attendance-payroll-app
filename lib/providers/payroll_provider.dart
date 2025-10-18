import 'package:flutter/foundation.dart';
import '../models/payroll.dart';
import '../services/payroll_service.dart';

class PayrollProvider with ChangeNotifier {
  List<Payroll> _payrolls = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Payroll> get payrolls => _payrolls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get user's payroll history
  Future<void> getUserPayrolls() async {
    _setLoading(true);
    try {
      _payrolls = await PayrollService.getUserPayrolls();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _payrolls = [];
    } finally {
      _setLoading(false);
    }
  }

  // Get payroll summary (admin only)
  Future<Map<String, dynamic>> getPayrollSummary(String month) async {
    _setLoading(true);
    try {
      final summary = await PayrollService.getPayrollSummary(month);
      _error = null;
      return summary;
    } catch (e) {
      _error = e.toString();
      return {};
    } finally {
      _setLoading(false);
    }
  }

  // Compute payroll for a specific user and month
  Future<void> computePayroll(int userId, String month) async {
    _setLoading(true);
    try {
      await PayrollService.computePayroll(userId, month);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}