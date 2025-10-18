import '../utils/constants.dart';
import 'api_service.dart';
import '../models/payroll.dart';

class PayrollService {
  static Future<List<Payroll>> getUserPayrolls() async {
    final response = await ApiService.get(Constants.userPayrollEndpoint);
    
    if (response['success'] == true && response['data'] != null) {
      final List<dynamic> payrollsJson = response['data'];
      return payrollsJson.map((json) => Payroll.fromJson(json)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch payroll data');
    }
  }

  static Future<Map<String, dynamic>> getPayrollSummary(String month) async {
    final response = await ApiService.get(
      '${Constants.payrollSummaryEndpoint}?month=$month',
    );
    
    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    } else {
      throw Exception(response['message'] ?? 'Failed to fetch payroll summary');
    }
  }

  static Future<void> computePayroll(int userId, String month) async {
    final response = await ApiService.post(
      Constants.computePayrollEndpoint,
      body: {
        'userId': userId,
        'month': month,
      },
    );
    
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to compute payroll');
    }
  }
}