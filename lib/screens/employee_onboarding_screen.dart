import 'package:flutter/material.dart';
import '../services/employee_onboarding_service.dart';

class EmployeeOnboardingScreen extends StatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  State<EmployeeOnboardingScreen> createState() =>
      _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _employees = [];

  // Controllers for add/edit form
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();

  String? _editingId; // null for adding new employee

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      final data = await EmployeeOnboardingService.getAllEmployees();
      setState(() {
        _employees = data;
        _loading = false;
      });
    } catch (e) {
      _showError(e.toString());
      setState(() => _loading = false);
    }
  }

  void _startEditing(Map<String, dynamic> emp) {
    _editingId = emp['employee id'];
    _fullNameCtrl.text = emp['full name'] ?? '';
    _emailCtrl.text = emp['email'] ?? '';
    _departmentCtrl.text = emp['department'] ?? '';
    _positionCtrl.text = emp['position'] ?? '';
    _showFormDialog();
  }

  void _startAdding() {
    _editingId = null;
    _fullNameCtrl.clear();
    _emailCtrl.clear();
    _departmentCtrl.clear();
    _positionCtrl.clear();
    _showFormDialog();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await EmployeeOnboardingService.upsertEmployee(
        employeeId: _editingId,
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        position: _positionCtrl.text.trim(),
        setup: "PENDING",
      );
      Navigator.of(context).pop(); // close form dialog
      _loadEmployees();
      _showMessage(
          _editingId == null ? 'Employee added' : 'Employee updated');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    try {
      await EmployeeOnboardingService.setInactive(employeeId);
      _loadEmployees();
      _showMessage('Employee set to inactive');
    } catch (e) {
      _showError(e.toString());
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
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: _editingId != null,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _departmentCtrl,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                TextFormField(
                  controller: _positionCtrl,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(_editingId == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Onboarding"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text("No employees found"))
              : ListView.builder(
                  itemCount: _employees.length,
                  itemBuilder: (_, i) {
                    final emp = _employees[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Chip(
                          label: Text(
                            emp['setup'] == 'DONE' ? 'DONE' : 'PENDING',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: emp['setup'] == 'DONE'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(emp['full name'] ?? ""),
                        subtitle: Text('${emp['email']} • ${emp['department']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEditing(emp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteEmployee(emp['employee id'] ?? ""),
                            ),
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
