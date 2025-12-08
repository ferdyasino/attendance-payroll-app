import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/attendance.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'all'; // all, present, absent, leave
  String? _selectedMonth;
  String? _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useDateRange = false;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  void _initializeDates() {
    final now = DateTime.now();
    _selectedMonth = '${now.month.toString().padLeft(2, '0')}';
    _selectedYear = now.year.toString();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _loadReports() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

    if (authProvider.isAdmin || authProvider.isSuperAdmin) {
      // Admin can see all attendance
      await attendanceProvider.fetchAllAttendance(
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        status: _selectedFilter != 'all' ? _selectedFilter : null,
      );
    } else {
      // Employee can see only their own attendance
      final userId = authProvider.currentUser?.id.toString();
      if (userId != null) {
        await attendanceProvider.fetchUserAttendance(
          userId: userId,
          month: _selectedMonth,
          year: _selectedYear,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin || authProvider.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, isAdmin),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${attendanceProvider.error}',
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReports,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final attendanceList = _filterAttendance(attendanceProvider.attendanceList);

          if (attendanceList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(attendanceList),
              
              // Filter Info
              _buildFilterInfo(),
              
              // Attendance List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return _buildAttendanceCard(attendance, isAdmin);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<Attendance> attendanceList) {
    final presentCount = attendanceList.where((a) => a.isPresent).length;
    final absentCount = attendanceList.where((a) => a.isAbsent).length;
    final leaveCount = attendanceList.where((a) => a.isLeave).length;
    final totalHours = attendanceList.fold<double>(
      0.0,
      (sum, a) => sum + a.totalHours,
    );
    final totalLate = attendanceList.fold<int>(
      0,
      (sum, a) => sum + a.lateMinutes,
    );
    final totalOvertime = attendanceList.fold<int>(
      0,
      (sum, a) => sum + a.overtimeMinutes,
    );

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Present', presentCount, Colors.green),
                ),
                Expanded(
                  child: _buildSummaryItem('Absent', absentCount, Colors.red),
                ),
                Expanded(
                  child: _buildSummaryItem('Leave', leaveCount, Colors.orange),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total Hours', totalHours.toStringAsFixed(1), Colors.blue),
                ),
                Expanded(
                  child: _buildSummaryItem('Late (min)', totalLate, Colors.orange),
                ),
                Expanded(
                  child: _buildSummaryItem('Overtime (min)', totalOvertime, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getFilterDescription(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            '${_getFilteredCount()} records',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(attendance.status),
          child: Icon(
            _getStatusIcon(attendance.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          isAdmin ? attendance.userName : _formatDate(attendance.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) Text(_formatDate(attendance.date)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.login, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(attendance.timeIn ?? 'Not recorded'),
                const SizedBox(width: 16),
                Icon(Icons.logout, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(attendance.timeOut ?? 'Not recorded'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Hours: ${attendance.formattedTotalHours}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (attendance.lateMinutes > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Late: ${attendance.lateMinutes}m',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
                if (attendance.overtimeMinutes > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    'OT: ${attendance.overtimeMinutes}m',
                    style: TextStyle(fontSize: 12, color: Colors.purple),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            attendance.status.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: _getStatusColor(attendance.status),
        ),
      ),
    );
  }

  List<Attendance> _filterAttendance(List<Attendance> attendanceList) {
    if (_selectedFilter == 'all') {
      return attendanceList;
    }
    return attendanceList.where((a) => a.status == _selectedFilter).toList();
  }

  int _getFilteredCount() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    return _filterAttendance(provider.attendanceList).length;
  }

  String _getFilterDescription() {
    if (_useDateRange && _startDate != null && _endDate != null) {
      return 'Date Range: ${_formatDate(_startDate!.toIso8601String())} - ${_formatDate(_endDate!.toIso8601String())}';
    } else if (_selectedMonth != null && _selectedYear != null) {
      return 'Month: ${_getMonthName(int.parse(_selectedMonth!))} $_selectedYear';
    }
    return 'All Records';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'leave':
        return Icons.event_busy;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.split(' ')[0]);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _showFilterDialog(BuildContext context, bool isAdmin) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Filter
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'leave', child: Text('Leave')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Date Range Option
              if (isAdmin) ...[
                CheckboxListTile(
                  title: const Text('Use Date Range'),
                  value: _useDateRange,
                  onChanged: (value) {
                    setState(() {
                      _useDateRange = value ?? false;
                    });
                  },
                ),
                if (_useDateRange) ...[
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate != null ? _formatDate(_startDate!.toIso8601String()) : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate != null ? _formatDate(_endDate!.toIso8601String()) : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ] else ...[
                  // Month/Year Selector
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      final month = (index + 1).toString().padLeft(2, '0');
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_getMonthName(index + 1)),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      final year = (DateTime.now().year - index).toString();
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ],
              ] else ...[
                // Employee view - Month/Year only
                DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (index) {
                    final month = (index + 1).toString().padLeft(2, '0');
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_getMonthName(index + 1)),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(5, (index) {
                    final year = (DateTime.now().year - index).toString();
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReports();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
