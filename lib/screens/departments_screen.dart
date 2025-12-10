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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    final data = await _service.fetchDepartmentsWithStatus();
    setState(() {
      _departments = data;
      _isLoading = false;
    });
  }

  Future<void> _importDepartment(int index) async {
    final dept = _departments[index];
    final added = await _service.addDepartment(dept);
    if (added) {
      setState(() {
        _departments[index]['addedToNewTab'] = true;
        _departments[index]['isOldSheet'] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department added to new tab')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add department')),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? department, int? index}) {
    final isImported = department != null && department['addedToNewTab'] == true;
    final isReadOnlyName = isImported; // department name readonly if imported/newly added
    final TextEditingController nameController =
        TextEditingController(text: department?['departmentName']?.toString() ?? '');
    final TextEditingController headController =
        TextEditingController(text: department?['departmentHead']?.toString() ?? '');
    final TextEditingController setupController =
        TextEditingController(text: department?['defaultSetup']?.toString() ?? 'OFFICE');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(department != null ? 'Edit Department' : 'Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Department Name'),
              readOnly: isReadOnlyName,
            ),
            TextField(
              controller: headController,
              decoration: const InputDecoration(labelText: 'Department Head'),
            ),
            TextField(
              controller: setupController,
              decoration: const InputDecoration(labelText: 'Default Setup'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newDept = {
                'departmentName': nameController.text.trim(),
                'departmentHead': headController.text.trim(),
                'defaultSetup': setupController.text.trim(),
              };

              bool success = false;
              if (department == null) {
                success = await _service.addDepartment(newDept);
              } else {
                success = await _service.updateDepartment(newDept);
              }

              if (success) {
                setState(() {
                  if (index != null) {
                    _departments[index] = {
                      ..._departments[index],
                      ...newDept,
                      'addedToNewTab': true,
                      'isOldSheet': false,
                    };
                  } else {
                    _departments.add({
                      ...newDept,
                      'addedToNewTab': true,
                      'isOldSheet': false,
                    });
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(department == null ? 'Department added' : 'Department updated')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to ${department == null ? 'add' : 'update'} department')),
                );
              }
            },
            child: Text(department == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDepartment(int index) async {
    final dept = _departments[index];
    final isOld = dept['isOldSheet'] == true;
    if (!(dept['addedToNewTab'] as bool? ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Department'),
        content: const Text('Delete from new tab?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _service.deleteDepartment(dept);
    if (success) {
      setState(() {
        if (isOld) {
          _departments[index]['addedToNewTab'] = false; // revert to old readonly list
        } else {
          _departments.removeAt(index);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete department')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (_, index) {
                final dept = _departments[index];
                final added = dept['addedToNewTab'] as bool? ?? false;

                return ListTile(
                  leading: !added
                      ? IconButton(
                          tooltip: 'Import to new tab',
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          onPressed: () => _importDepartment(index),
                        )
                      : null,
                  title: Text(dept['departmentName']?.toString() ?? ''),
                  subtitle: Text(
                      'Head: ${dept['departmentHead'] ?? ''}, Setup: ${dept['defaultSetup'] ?? ''}'),
                  trailing: added
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(department: dept, index: index),
                            ),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteDepartment(index)),
                          ],
                        )
                      : null,
                );
              },
            ),
    );
  }
}
