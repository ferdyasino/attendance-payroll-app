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
  List<Map<String, dynamic>> _employeesFromOldAttendance = [];

  final DepartmentService _departmentService = DepartmentService();
  List<Map<String, dynamic>> _departments = [];

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
  final List<String> _statusItems = ['Active', 'Inactive'];

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
        final defaultSetup = current.first['defaultSetup'];
        _employeeSetup = _allowedSetups.contains(defaultSetup) ? defaultSetup : 'OFFICE';
      }
    });
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      _employees = await EmployeeOnboardingService.getAllEmployees();
      _employeesFromOldAttendance = await EmployeeOnboardingService.fetchEmployeesFromOldAttendance();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateEmail(String fullName) {
    final base = fullName.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim().split(' ').join('.');
    final existing = _employees.map((e) => (e['email'] ?? '').toString().toLowerCase()).toSet();

    String email = '$base@company.local';
    int i = 1;
    while (existing.contains(email)) {
      email = '$base$i@company.local';
      i++;
    }
    return email;
  }

  void _startEditing(Map<String, dynamic> emp) {
    _editingId = emp['employee id'] ?? '';
    _nameCtrl.text = emp['full name'] ?? '';
    _emailCtrl.text = emp['email'] ?? '';
    _positionCtrl.text = emp['position'] ?? '';
    _status = EmployeeOnboardingService.normalizeStatus(emp['status'] ?? 'Active');

    _selectedDepartment = _departments.isNotEmpty
        ? _departments.firstWhere(
            (d) => d['departmentName'] == (emp['department'] ?? ''),
            orElse: () => _departments.first,
          )
        : null;

    final setup = (emp['setup'] ?? 'OFFICE').toString().toUpperCase();
    _employeeSetup = _allowedSetups.contains(setup)
        ? setup
        : (_selectedDepartment != null && _allowedSetups.contains(_selectedDepartment!['defaultSetup'])
            ? _selectedDepartment!['defaultSetup']
            : 'OFFICE');

    _setupManuallyChanged = true;
    _showFormDialog();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a department')));
      return;
    }

    try {
      await EmployeeOnboardingService.upsertEmployee(
        employeeId: _editingId,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        department: _selectedDepartment!['departmentName'] ?? '',
        position: _positionCtrl.text.trim(),
        setup: _employeeSetup,
        status: _status,
      );
      Navigator.of(context).pop();
      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Employee added' : 'Employee updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    if (employeeId.isEmpty) return;
    try {
      await EmployeeOnboardingService.setInactive(employeeId);
      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee set to inactive')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showFormDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_editingId == null ? 'Add Employee' : 'Edit Employee'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), readOnly: _editingId != null, validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedDepartment,
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d['departmentName'] ?? ''))).toList(),
                  onChanged: (d) {
                    if (d == null) return;
                    setState(() {
                      _selectedDepartment = d;
                      if (!_setupManuallyChanged) {
                        final defaultSetup = d['defaultSetup'];
                        _employeeSetup = _allowedSetups.contains(defaultSetup) ? defaultSetup : 'OFFICE';
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _positionCtrl, decoration: const InputDecoration(labelText: 'Position')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _employeeSetup,
                  items: _allowedSetups.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _employeeSetup = v;
                      _setupManuallyChanged = true;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Setup'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _statusItems.contains(_status) ? _status : _statusItems.first,
                  items: _statusItems.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _status = v);
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 20),
                if (_editingId != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Employee'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEmployee(_editingId!);
                    },
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

  /// FINAL SAFE IMPORT DIALOG - NO MORE CRASHES
  Future<void> _showImportDialog() async {
    if (_employeesFromOldAttendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees found in attendance sheet for import')),
      );
      return;
    }

    final selected = <Map<String, dynamic>>{};

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Import Employees (${_employeesFromOldAttendance.length} available)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _employeesFromOldAttendance.length,
              itemBuilder: (_, i) {
                final emp = _employeesFromOldAttendance[i];
                final isSelected = selected.contains(emp);

                final subtitleParts = <String>[
                  emp['department'] ?? '',
                  if ((emp['position'] ?? '').toString().trim().isNotEmpty) emp['position'],
                  emp['setup'] ?? 'OFFICE',
                ].where((s) => s.trim().isNotEmpty).join(' • ');

                return ListTile(
                  title: Text(emp['fullName'] ?? 'No Name'),
                  subtitle: Text(subtitleParts),
                  trailing: Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? Colors.green : null,
                  ),
                  onTap: () {
                    setState(() {
                      isSelected ? selected.remove(emp) : selected.add(emp);
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);

                      // Immediate feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Importing selected employees...')),
                      );

                      int successCount = 0;
                      for (final emp in selected) {
                        final success = await EmployeeOnboardingService.upsertEmployee(
                          fullName: emp['fullName'],
                          email: _generateEmail(emp['fullName']),
                          department: emp['department'],
                          position: emp['position'] ?? '',
                          setup: emp['setup'],
                          status: 'Active',
                        );
                        if (success) successCount++;
                      }

                      // Critical: Check if still mounted before using context
                      if (!mounted) return;

                      await _loadEmployees();

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$successCount employee(s) imported successfully'),
                          backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
                        ),
                      );
                    },
              child: const Text('Import Selected'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Onboarding'), backgroundColor: Colors.blue, centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text('No employees found'))
              : ListView.builder(
                  itemCount: _employees.length,
                  itemBuilder: (_, i) {
                    final emp = _employees[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(emp['full name'] ?? 'No Name'),
                        subtitle: Text('${emp['department'] ?? 'No Dept'} • ${emp['email'] ?? 'No Email'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _startEditing(emp),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () {
              _editingId = null;
              _nameCtrl.clear();
              _emailCtrl.clear();
              _positionCtrl.clear();
              _setupManuallyChanged = false;
              _status = 'Active';
              if (_departments.isNotEmpty) {
                _selectedDepartment = _departments.first;
                final defaultSetup = _selectedDepartment!['defaultSetup'];
                _employeeSetup = _allowedSetups.contains(defaultSetup) ? defaultSetup : 'OFFICE';
              }
              _showFormDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Employee'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: _showImportDialog,
            icon: const Icon(Icons.download),
            label: const Text('Import Employees'),
          ),
        ],
      ),
    );
  }
}