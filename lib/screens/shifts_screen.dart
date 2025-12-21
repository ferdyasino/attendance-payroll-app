import 'package:flutter/material.dart';
import '../services/shift_service.dart';
import '../services/employee_onboarding_service.dart';
import '../models/shift.dart';
import '../models/shift_type.dart';
import '../theme/app_colors.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Shift> _schedules = [];
  List<ShiftType> _shiftTypes = [];
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      _employees = await EmployeeOnboardingService.getAllEmployees();
      _schedules = await ShiftService.getSchedules();
      _shiftTypes = await ShiftService.getShiftTypes();
    } catch (e) {
      debugPrint('Error loading data: $e');
      _employees = [];
      _schedules = [];
      _shiftTypes = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEmployeeSchedulesDialog(Map<String, dynamic> emp) {
    final empEmail = (emp['email'] ?? '').toString();
    final empName = (emp['full name'] ?? 'No Name').toString();
    final empSchedules = _schedules.where((s) => s.email == empEmail).toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(empName),
          content: SizedBox(
            width: double.maxFinite,
            child: empSchedules.isEmpty
                ? const Text('No schedules assigned')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: empSchedules.length,
                    itemBuilder: (_, i) {
                      final s = empSchedules[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(s.baseShift),
                          subtitle: Text('${s.cycleStart.split('T')[0]} → ${s.cycleEnd.split('T')[0]}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ShiftService.postShiftAction('delete', {
                                'email': empEmail,
                                'baseShift': s.baseShift,
                              });
                              setState(() => empSchedules.removeAt(i));
                              await _loadAll();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () => _showAddScheduleDialog(emp),
              child: const Text('Add Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(Map<String, dynamic> employee) {
    String? selectedShift;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Schedule for ${(employee['full name'] ?? 'No Name')}'),
          content: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select Shift'),
            items: _shiftTypes
                .map((s) => DropdownMenuItem(value: s.shiftName, child: Text(s.shiftName)))
                .toList(),
            onChanged: (v) => setState(() => selectedShift = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedShift == null
                  ? null
                  : () async {
                      await ShiftService.postShiftAction('add', {
                        'email': (employee['email'] ?? '').toString(),
                        'baseShift': selectedShift!,
                        'cycleStart': DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                      await _loadAll();
                      _showEmployeeSchedulesDialog(employee);
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCards() {
    if (_employees.isEmpty) return const Center(child: Text('No employees found'));

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (_, i) {
          final emp = _employees[i];
          final empEmail = (emp['email'] ?? '').toString();
          final empName = (emp['full name'] ?? 'No Name').toString();
          final empSchedules = _schedules.where((s) => s.email == empEmail).toList();

          return GestureDetector(
            onTap: () => _showEmployeeSchedulesDialog(emp),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('${empSchedules.length} schedule(s) assigned'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftTypeCards() {
    if (_shiftTypes.isEmpty) return const Center(child: Text('No shift types found'));

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        itemCount: _shiftTypes.length,
        itemBuilder: (_, i) {
          final s = _shiftTypes[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(s.shiftName),
              subtitle: Text('${s.startTime} → ${s.endTime}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: implement edit shift type dialog
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Shifts'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Employee Schedules'),
            Tab(text: 'Shift Types'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeCards(),
                _buildShiftTypeCards(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          if (_tabController.index == 1) {
            // TODO: show add shift type dialog
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
