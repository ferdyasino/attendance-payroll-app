import 'package:flutter/material.dart';
import '../services/shift_service.dart';
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
  bool _isLoading = true;
  String _debugMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _debugMessage = 'Loading schedules and shift types...';
    });

    try {
      final schedules = await ShiftService.getSchedules();
      final shiftTypes = await ShiftService.getShiftTypes();

      setState(() {
        _schedules = schedules;
        _shiftTypes = shiftTypes;
        _debugMessage =
            'Loaded ${_schedules.length} schedules, ${_shiftTypes.length} shift types';
      });
    } catch (e, st) {
      debugPrint('LOAD ERROR: $e\n$st');
      setState(() {
        _debugMessage = 'ERROR: $e';
        _schedules = [];
        _shiftTypes = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ------------------ Add New Schedule Dialog ------------------
  void _showAddScheduleDialog() {
    String? selectedEmail;
    String? selectedShiftName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Employee Email'),
                value: selectedEmail,
                items: _schedules.map((s) {
                  return DropdownMenuItem(
                    value: s.email,
                    child: Text(s.email),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedEmail = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Base Shift'),
                value: selectedShiftName,
                items: _shiftTypes.map((s) {
                  return DropdownMenuItem(
                    value: s.shiftName,
                    child: Text(s.shiftName),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedShiftName = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedEmail != null && selectedShiftName != null)
                  ? () async {
                      final success = await ShiftService.postShiftAction('add', {
                        'email': selectedEmail!,
                        'baseShift': selectedShiftName!,
                        'cycleStart': DateTime.now().toIso8601String(),
                      });

                      if (success) {
                        Navigator.pop(context);
                        _loadAll();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add schedule')),
                        );
                      }
                    }
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesTable() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('NO SCHEDULE DATA RETURNED'));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Base Shift')),
              DataColumn(label: Text('Cycle Start')),
              DataColumn(label: Text('Cycle End')),
              DataColumn(label: Text('Schedule JSON')),
              DataColumn(label: Text('Reason')),
            ],
            rows: _schedules.map((s) {
              return DataRow(cells: [
                DataCell(Text(s.email)),
                DataCell(Text(s.baseShift)),
                DataCell(Text(s.cycleStart.split('T')[0])),
                DataCell(Text(s.cycleEnd.split('T')[0])),
                DataCell(Text(s.schedule.toJson().toString())),
                DataCell(const Text('Initial')),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTypesTable() {
    if (_shiftTypes.isEmpty) {
      return const Center(child: Text('NO SHIFT TYPES RETURNED'));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('Shift Name')),
              DataColumn(label: Text('Start Time')),
              DataColumn(label: Text('End Time')),
            ],
            rows: _shiftTypes.map((s) {
              return DataRow(cells: [
                DataCell(Text(s.shiftName)),
                DataCell(Text(s.startTime)),
                DataCell(Text(s.endTime)),
              ]);
            }).toList(),
          ),
        ],
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
            Tab(text: 'Schedules'),
            Tab(text: 'Shift Types'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSchedulesTable(),
                _buildShiftTypesTable(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
