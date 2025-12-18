import 'package:flutter/material.dart';
import '../services/employee_onboarding_service.dart';
import '../services/department_service.dart';

class EmployeeOnboardingScreen extends StatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  State<EmployeeOnboardingScreen> createState() => _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _employees = [];

  final DepartmentService _departmentService = DepartmentService();
  List<Map<String, dynamic>> _departments = [];

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  Map<String, dynamic>? _selectedDepartment;
  String _employeeSetup = 'OFFICE';
  bool _setupManuallyChanged = false;
  String _status = 'Active';
  String? _editingId;

  final List<String> _allowedSetups = ['OFFICE', 'WFH', 'HYBRID'];
  final List<String> _statusItems = ['Active', 'Inactive']; // normalized

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadEmployees();
  }

  Future<void> _loadDepartments() async {
    final all = await _departmentService.fetchDepartmentsWithStatus();
    final current = all.where((d) => d['addedToNewTab'] == true && d['isOldSheet'] == false).toList();
    if (!mounted) return;

    setState(() {
      _departments = current;
      if (_selectedDepartment == null && current.isNotEmpty) {
        _selectedDepartment = current.first;
        _employeeSetup = _allowedSetups.contains(current.first['defaultSetup'])
            ? current.first['defaultSetup']
            : 'OFFICE';
      }
    });
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      final data = await EmployeeOnboardingService.getAllEmployees();
      if (!mounted) return;
      setState(() {
        _employees = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _startAdding() {
    _editingId = null;
    _nameCtrl.clear();
    _emailCtrl.clear();
    _positionCtrl.clear();
    _setupManuallyChanged = false;
    _status = 'Active';
    if (_departments.isNotEmpty) {
      _selectedDepartment = _departments.first;
      _employeeSetup = _allowedSetups.contains(_selectedDepartment!['defaultSetup'])
          ? _selectedDepartment!['defaultSetup']
          : 'OFFICE';
    }
    _showFormDialog();
  }

  void _startEditing(Map<String, dynamic> emp) {
    _editingId = emp['employee id'];
    _nameCtrl.text = emp['full name'] ?? '';
    _emailCtrl.text = emp['email'] ?? '';
    _positionCtrl.text = emp['position'] ?? '';
    _status = EmployeeOnboardingService.normalizeStatus(emp['status'] ?? 'Active');

    _selectedDepartment = _departments.isNotEmpty
      ? _departments.firstWhere(
          (d) => d['departmentName'] == emp['department'],
          orElse: () => _departments.first,
        )
      : null;

    _employeeSetup = _allowedSetups.contains(emp['setup'])
        ? emp['setup']
        : (_selectedDepartment != null && _allowedSetups.contains(_selectedDepartment!['defaultSetup'])
            ? _selectedDepartment!['defaultSetup']
            : 'OFFICE');

    _setupManuallyChanged = true;
    _showFormDialog();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await EmployeeOnboardingService.upsertEmployee(
        employeeId: _editingId,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        department: _selectedDepartment!['departmentName'],
        position: _positionCtrl.text.trim(),
        setup: _employeeSetup,
        status: _status,
      );
      Navigator.of(context).pop();
      _loadEmployees();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Employee added' : 'Employee updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    try {
      await EmployeeOnboardingService.setInactive(employeeId);
      _loadEmployees();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee set to inactive')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_editingId == null ? 'Add Employee' : 'Edit Employee'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: _editingId != null,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedDepartment,
                  items: _departments
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d['departmentName']),
                          ))
                      .toList(),
                  onChanged: (d) {
                    setState(() {
                      _selectedDepartment = d;
                      if (!_setupManuallyChanged) {
                        _employeeSetup = _allowedSetups.contains(d?['defaultSetup'])
                            ? d!['defaultSetup']
                            : 'OFFICE';
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionCtrl,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _employeeSetup,
                  items: _allowedSetups
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _employeeSetup = v!;
                      _setupManuallyChanged = true;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Setup'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _statusItems.contains(_status) ? _status : _statusItems.first,
                  items: _statusItems
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _submitForm, child: Text(_editingId == null ? 'Add' : 'Update')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Onboarding')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text('No employees found'))
              : ListView.builder(
                  itemCount: _employees.length,
                  itemBuilder: (_, i) {
                    final emp = _employees[i];
                    final normalizedStatus = EmployeeOnboardingService.normalizeStatus(emp['status']);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Chip(
                          label: Text(normalizedStatus, style: const TextStyle(color: Colors.white)),
                          backgroundColor: normalizedStatus == 'Active' ? Colors.green : Colors.red,
                        ),
                        title: Text(emp['full name'] ?? ''),
                        subtitle: Text('${emp['email']} • ${emp['department']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _startEditing(emp)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEmployee(emp['employee id'] ?? '')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _startAdding,
      ),
    );
  }
}
