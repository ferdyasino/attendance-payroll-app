import 'package:flutter/material.dart';
import '../services/employee_onboarding_service.dart';
import '../services/department_service.dart';
import '../theme/app_colors.dart';

class EmployeeOnboardingScreen extends StatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  State<EmployeeOnboardingScreen> createState() => _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen> {
  bool _loading = true;
  bool _showInactive = true;

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
    final allDepartments = await _departmentService.fetchDepartmentsWithStatus();
    final current = allDepartments
        .where((d) => d['addedToNewTab'] == true && d['isOldSheet'] == false)
        .toList();
    if (!mounted) return;

    setState(() {
      _departments = current;
      if (_selectedDepartment == null && current.isNotEmpty) {
        _selectedDepartment = current.first;
        final defaultSetup = current.first['defaultSetup']?.toString().toUpperCase() ?? 'OFFICE';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a department'), backgroundColor: AppColors.error),
      );
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
        SnackBar(
          content: Text(_editingId == null ? 'Employee added' : 'Employee updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleStatus(String employeeId, bool activate) async {
    if (employeeId.isEmpty) return;
    try {
      final emp = _employees.firstWhere((e) => e['employee id'] == employeeId);
      if (activate) {
        await EmployeeOnboardingService.upsertEmployee(
          employeeId: emp['employee id'],
          fullName: emp['full name'],
          email: emp['email'],
          department: emp['department'] ?? '',
          position: emp['position'] ?? '',
          setup: emp['setup'] ?? 'OFFICE',
          status: 'Active',
        );
      } else {
        await EmployeeOnboardingService.setInactive(employeeId);
      }
      Navigator.of(context).pop(); // close form
      await _loadEmployees();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee ${activate ? 'activated' : 'deleted'} successfully'),
          backgroundColor: activate ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showFormDialog() async {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_editingId == null ? 'Add Employee' : 'Edit Employee'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                    readOnly: _editingId != null,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d['departmentName'] ?? '')))
                        .toList(),
                    onChanged: (d) {
                      if (d == null) return;
                      setState(() {
                        _selectedDepartment = d;
                        if (!_setupManuallyChanged) {
                          final defaultSetup = d['defaultSetup']?.toString().toUpperCase() ?? 'OFFICE';
                          _employeeSetup = _allowedSetups.contains(defaultSetup) ? defaultSetup : 'OFFICE';
                        }
                      });
                    },
                    decoration: InputDecoration(labelText: 'Department'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _positionCtrl, decoration: InputDecoration(labelText: 'Position')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _employeeSetup,
                    isExpanded: true,
                    items: _allowedSetups.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _employeeSetup = v;
                        _setupManuallyChanged = true;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Setup'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            if (_editingId != null)
              TextButton(
                onPressed: () => _toggleStatus(_editingId!, _status == 'Inactive'),
                child: Text(
                  _status == 'Inactive' ? 'Activate' : 'Delete',
                  style: TextStyle(color: _status == 'Inactive' ? AppColors.success : AppColors.error),
                ),
              ),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text(_editingId == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_showInactive) return _employees;
    return _employees.where((e) => EmployeeOnboardingService.normalizeStatus(e['status']) == 'Active').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Employee Onboarding', style: TextStyle(fontSize: 20)),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Text('Show Inactive'),
                    const Spacer(),
                    Switch(
                      value: _showInactive,
                      onChanged: (val) {
                        setState(() => _showInactive = val);
                        Navigator.pop(context);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredEmployees.isEmpty
              ? Center(child: Text('No employees found', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: _filteredEmployees.length,
                  itemBuilder: (_, i) {
                    final emp = _filteredEmployees[i];
                    final isInactive = EmployeeOnboardingService.normalizeStatus(emp['status']) == 'Inactive';

                    return GestureDetector(
                      onTap: () => _startEditing(emp),
                      child: Card(
                        color: isInactive ? AppColors.error.withOpacity(0.3) : null,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(emp['full name'] ?? 'No Name'),
                          subtitle: Text('${emp['department'] ?? 'No Dept'} • ${emp['email'] ?? 'No Email'}'),
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
            backgroundColor: AppColors.primary,
            onPressed: () {
              _editingId = null;
              _nameCtrl.clear();
              _emailCtrl.clear();
              _positionCtrl.clear();
              _setupManuallyChanged = false;
              _status = 'Active';
              if (_departments.isNotEmpty) {
                _selectedDepartment = _departments.first;
                final defaultSetup = _selectedDepartment!['defaultSetup']?.toString().toUpperCase() ?? 'OFFICE';
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
            backgroundColor: AppColors.primary,
            onPressed: _showImportDialog,
            icon: const Icon(Icons.download),
            label: const Text('Import Employees'),
          ),
        ],
      ),
    );
  }

  // Import dialog remains unchanged but uses theme colors
  Future<void> _showImportDialog() async {
    if (_employeesFromOldAttendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('No employees found in attendance sheet for import'), backgroundColor: AppColors.error),
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
                    color: isSelected ? AppColors.success : null,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Importing selected employees...'), backgroundColor: AppColors.primary),
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

                      if (!mounted) return;
                      await _loadEmployees();

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$successCount employee(s) imported successfully'),
                          backgroundColor: successCount > 0 ? AppColors.success : AppColors.warning,
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
}
