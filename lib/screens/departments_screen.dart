import 'package:flutter/material.dart';
import '../services/department_service.dart';
import '../theme/app_colors.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentService _service = DepartmentService();
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true; // start with loading

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDepartments);
  }

  // -------------------- LOAD --------------------
  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _service.fetchDepartmentsWithStatus();
      if (!mounted) return;
      setState(() => _departments = fetched);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------- IMPORT OLD --------------------
  Future<void> _importDepartment(int index) async {
    final dept = _departments[index];
    final success = await _service.addDepartment(dept);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Department imported to new sheet'
            : 'Failed to import department'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) _loadDepartments();
  }

  // -------------------- ADD / EDIT --------------------
  void _showAddEditDialog({Map<String, dynamic>? department}) {
    final isEditing = department != null;
    final isImported = department?['addedToNewTab'] == true;

    final nameCtrl =
        TextEditingController(text: department?['departmentName'] ?? '');
    final headCtrl =
        TextEditingController(text: department?['departmentHead'] ?? '');
    final setupCtrl =
        TextEditingController(text: department?['defaultSetup'] ?? 'OFFICE');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Department' : 'Add Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Department Name"),
                readOnly: isImported,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headCtrl,
                decoration: const InputDecoration(labelText: "Department Head"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: setupCtrl,
                decoration: const InputDecoration(labelText: "Default Setup"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (isEditing)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Department'),
                      content: const Text(
                          'Are you sure you want to delete this department?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(_, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(_, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  final success = await _service.deleteDepartment(department!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Department deleted'
                          : 'Failed to delete department'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );

                  if (success) {
                    Navigator.pop(context);
                    _loadDepartments();
                  }
                },
                child: const Text('Delete'),
              ),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'departmentName': nameCtrl.text.trim(),
                  'departmentHead': headCtrl.text.trim(),
                  'defaultSetup': setupCtrl.text.trim(),
                };

                bool success = false;
                if (isEditing) {
                  success = await _service.updateDepartment(payload);
                } else {
                  success = await _service.addDepartment(payload);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isEditing ? 'Department updated' : 'Department added')
                        : 'Operation failed'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );

                if (success) {
                  Navigator.pop(context);
                  _loadDepartments();
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- DELETE --------------------
  Future<void> _deleteDepartment(int index) async {
    final dept = _departments[index];
    if (!(dept['addedToNewTab'] ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Department'),
        content: const Text('Delete this department from new tab?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _service.deleteDepartment(dept);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Department deleted' : 'Failed to delete department'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );

    if (success) _loadDepartments();
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
              ? const Center(child: Text('No departments found'))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _departments.length,
                  itemBuilder: (_, index) {
                    final dept = _departments[index];
                    final added = dept['addedToNewTab'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: !added
                            ? IconButton(
                                icon: const Icon(
                                  Icons.download_outlined,
                                  color: AppColors.warning,
                              ),
                              onPressed: () => _importDepartment(index),
                            )
                          : null,
                      title: Text(dept['departmentName'] ?? ''),
                      subtitle: Text(
                        'Head: ${dept['departmentHead'] ?? ''} • Setup: ${dept['defaultSetup'] ?? ''}',
                      ),
                      trailing: added
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showAddEditDialog(department: dept),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteDepartment(index),
                                ),
                              ],
                            )
                          : null,
                      )
                    );
                  },
                ),
    );
  }
}
