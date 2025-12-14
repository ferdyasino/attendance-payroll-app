import 'package:flutter/material.dart';
import '../services/department_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentService _service = DepartmentService();
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDepartments); // silent startup load
  }

  // -------------------- SILENT LOAD --------------------
  Future<void> _loadDepartments() async {
    final fetched = await _service.fetchDepartmentsWithStatus();
    if (!mounted) return;

    setState(() {
      _departments = fetched;
    });
  }

  // -------------------- IMPORT OLD --------------------
  Future<void> _importDepartment(int index) async {
    final dept = _departments[index];
    final success = await _service.addDepartment(dept);

    if (success) {
      _loadDepartments(); // silent refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department imported to new sheet')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import department')),
      );
    }
  }

  // -------------------- ADD / EDIT --------------------
  void _showAddEditDialog({Map<String, dynamic>? department}) {
    final isEditing = department != null;
    final bool isImported = department?['addedToNewTab'] == true;

    final nameController =
        TextEditingController(text: department?['departmentName'] ?? '');
    final headController =
        TextEditingController(text: department?['departmentHead'] ?? '');
    final setupController =
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
                controller: nameController,
                decoration: const InputDecoration(labelText: "Department Name"),
                readOnly: isImported,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headController,
                decoration: const InputDecoration(labelText: "Department Head"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: setupController,
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
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Department'),
                      content: const Text(
                          'Are you sure you want to delete this department?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  final success = await _service.deleteDepartment(department!);
                  if (success) {
                    Navigator.pop(context);
                    _loadDepartments(); // silent refresh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Department deleted')),
                    );
                  }
                },
                child: const Text('Delete'),
              ),

            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'departmentName': nameController.text.trim(),
                  'departmentHead': headController.text.trim(),
                  'defaultSetup': setupController.text.trim(),
                };

                bool success = false;

                if (isEditing) {
                  success = await _service.updateDepartment(payload);
                } else {
                  success = await _service.addDepartment(payload);
                }

                if (success) {
                  Navigator.pop(context);
                  _loadDepartments(); // silent refresh
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? "Department updated"
                            : "Department added",
                      ),
                    ),
                  );
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _service.deleteDepartment(dept);

    if (success) {
      _loadDepartments(); // silent refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department deleted')),
      );
    }
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
            onPressed: _loadDepartments, // silent refresh
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),

      body: RefreshIndicator(
        onRefresh: _loadDepartments, // pull to refresh
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _departments.length,
          itemBuilder: (_, index) {
            final dept = _departments[index];
            final added = dept['addedToNewTab'] ?? false;

            return ListTile(
              leading: !added
                  ? IconButton(
                      icon: const Icon(
                        Icons.download_outlined,
                        color: Colors.orange,
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
            );
          },
        ),
      ),
    );
  }
}
