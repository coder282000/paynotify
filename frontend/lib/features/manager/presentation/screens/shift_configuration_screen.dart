// lib/features/manager/presentation/screens/shift_configuration_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/shift_model.dart';
import '../../domain/models/shift_assignment.dart';
import '../../domain/models/shift_schedule.dart';
import '../../domain/models/employee_leave.dart';
import '../widgets/shift_card.dart';
import '../widgets/shift_assignment.dart';
import '../widgets/shift_creation_dialog.dart';
import '../widgets/day_type_dialog.dart';
import '../widgets/shift_schedule_view.dart';
import '../widgets/employee_off_days_dialog.dart';
import '../widgets/leave_request_dialog.dart';
import '../widgets/employee_leave_card.dart';

// MARK: - Constants
class _ShiftConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
}

class ShiftConfigurationScreen extends StatefulWidget {
  const ShiftConfigurationScreen({super.key});

  @override
  State<ShiftConfigurationScreen> createState() => _ShiftConfigurationScreenState();
}

class _ShiftConfigurationScreenState extends State<ShiftConfigurationScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;
  
  // Shifts
  List<Shift> _shifts = [];
  
  // Schedule
  ShiftSchedule? _currentSchedule;
  Map<String, List<ShiftAssignment>> _assignments = {};
  
  // Available attendants (mock - would come from employee management in production)
  final List<String> _availableAttendants = [
    'John Mwangi', 'Sarah Wanjiku', 'Peter Odhiambo', 
    'Grace Akinyi', 'Lucy Wambui', 'David Omondi', 
    'Mary Njeri', 'James Kariuki'
  ];
  
  // Employee Off Days
  final Map<String, EmployeeOffDays> _employeeOffDays = {};
  
  // Leave Requests
  List<EmployeeLeave> _leaveRequests = [];
  
  // Current week range
  DateTime _currentWeekStart = DateTime.now();
  
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeEmployeeOffDays();
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeEmployeeOffDays() {
    for (final attendant in _availableAttendants) {
      _employeeOffDays[attendant] = EmployeeOffDays(
        attendantId: attendant,
        attendantName: attendant,
        weeklyOffDays: [],
      );
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(_ShiftConstants.animationDuration);
      
      if (!mounted) return;
      
      _shifts = _generateMockShifts();
      _currentSchedule = _generateMockSchedule();
      _assignments = _currentSchedule!.dailyAssignments;
      _leaveRequests = _generateMockLeaveRequests();
      
      setState(() => _isLoading = false);
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('Load shifts error: $e\n$stackTrace');
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _showErrorSnackBar();
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Failed to load shift configuration. Please try again.';
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? 'An error occurred')),
          ],
        ),
        backgroundColor: _ShiftConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<Shift> _generateMockShifts() {
    return [
      Shift(
        id: '1',
        type: ShiftType.morning,
        startTime: const TimeOfDay(hour: 6, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        isActive: true,
      ),
      Shift(
        id: '2',
        type: ShiftType.evening,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        isActive: true,
      ),
      Shift(
        id: '3',
        type: ShiftType.night,
        startTime: const TimeOfDay(hour: 22, minute: 0),
        endTime: const TimeOfDay(hour: 6, minute: 0),
        isActive: true,
      ),
    ];
  }

  List<EmployeeLeave> _generateMockLeaveRequests() {
    final now = DateTime.now();
    return [
      EmployeeLeave(
        id: '1',
        attendantId: 'John Mwangi',
        attendantName: 'John Mwangi',
        type: LeaveType.annual,
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 12)),
        status: LeaveStatus.approved,
        reason: 'Family vacation',
        approvedBy: 'Manager',
        approvedAt: now,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      EmployeeLeave(
        id: '2',
        attendantId: 'Sarah Wanjiku',
        attendantName: 'Sarah Wanjiku',
        type: LeaveType.sick,
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        status: LeaveStatus.approved,
        reason: 'Flu',
        approvedBy: 'Manager',
        approvedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  ShiftSchedule _generateMockSchedule() {
    final assignments = <String, List<ShiftAssignment>>{};
    final dayTypes = <String, DayType>{};
    
    for (final day in _daysOfWeek) {
      dayTypes[day] = DayType.working;
      assignments[day] = [];
    }
    
    // Add some mock assignments only for attendants not on leave/off days
    final availableAttendants = _getAvailableAttendantsForDate(_currentWeekStart);
    
    if (availableAttendants.isNotEmpty) {
      assignments['Monday'] = [
        ShiftAssignment(
          id: 'a1',
          attendantId: availableAttendants[0],
          attendantName: availableAttendants[0],
          shiftId: '1',
          shiftType: ShiftType.morning,
          date: _currentWeekStart,
          status: ShiftAssignmentStatus.scheduled,
        ),
      ];
      
      if (availableAttendants.length > 1) {
        assignments['Monday']!.add(
          ShiftAssignment(
            id: 'a2',
            attendantId: availableAttendants[1],
            attendantName: availableAttendants[1],
            shiftId: '2',
            shiftType: ShiftType.evening,
            date: _currentWeekStart,
            status: ShiftAssignmentStatus.scheduled,
          ),
        );
      }
    }
    
    return ShiftSchedule(
      id: '1',
      stationId: '1',
      weekStarting: _getWeekStart(_currentWeekStart),
      dailyAssignments: assignments,
      dayTypes: dayTypes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday == 7 ? 6 : weekday - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  List<String> _getAvailableAttendantsForDate(DateTime date) {
    return _availableAttendants.where((attendant) {
      return _isAttendantAvailable(attendant, date);
    }).toList();
  }

  bool _isAttendantAvailable(String attendantName, DateTime date) {
    // Check off days
    final offDays = _employeeOffDays[attendantName];
    if (offDays != null && offDays.isOffDay(date)) {
      return false;
    }
    
    // Check active leave
    final activeLeave = _leaveRequests.any((leave) => 
      leave.attendantName == attendantName && 
      leave.status == LeaveStatus.approved &&
      leave.startDate.isBefore(date) &&
      leave.endDate.isAfter(date)
    );
    
    return !activeLeave;
  }

  void _addShift() async {
    final result = await showDialog<Shift>(
      context: context,
      builder: (context) => ShiftCreationDialog(
        onSave: (shift) {
          Navigator.pop(context, shift);
        },
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _shifts.add(result);
        _hasChanges = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.type.displayName} added successfully'),
          backgroundColor: _ShiftConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editShift(Shift shift) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${shift.type.displayName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleShiftActive(Shift shift, bool value) {
    setState(() {
      shift.isActive = value;
      _hasChanges = true;
    });
  }

  void _assignShift() async {
    final availableAttendants = _getAvailableAttendantsForDate(_currentWeekStart);
    
    if (availableAttendants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendants available for assignment this week'),
          backgroundColor: _ShiftConstants.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    await showDialog<List<ShiftAssignment>>(
      context: context,
      builder: (context) => ShiftAssignmentDialog(
        availableAttendants: availableAttendants,
        availableShifts: _shifts.where((s) => s.isActive).toList(),
        selectedDate: _currentWeekStart,
        onAssign: (assignments) {
          setState(() {
            for (final assignment in assignments) {
              final day = _getDayOfWeek(assignment.date);
              if (_assignments[day] == null) {
                _assignments[day] = [];
              }
              _assignments[day]!.add(assignment);
            }
            _hasChanges = true;
          });
        },
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  void _setDayType(String day, DayType type) {
    setState(() {
      _currentSchedule?.dayTypes[day] = type;
      _hasChanges = true;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _loadData();
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _loadData();
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift schedule saved successfully'),
          backgroundColor: _ShiftConstants.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save schedule: ${e.toString()}'),
          backgroundColor: _ShiftConstants.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAssignmentDetails(ShiftAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shift Details - ${assignment.attendantName}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Shift', assignment.shiftType.displayName),
            const SizedBox(height: 8),
            _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(assignment.date)),
            const SizedBox(height: 8),
            _buildDetailRow('Status', assignment.status.displayName),
            if (assignment.notes != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Notes', assignment.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          if (assignment.status == ShiftAssignmentStatus.scheduled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  for (final day in _assignments.keys) {
                    _assignments[day]?.removeWhere((a) => a.id == assignment.id);
                  }
                  _hasChanges = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assignment cancelled'),
                    backgroundColor: _ShiftConstants.warningOrange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('CANCEL ASSIGNMENT', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _updateEmployeeOffDays(String attendantName, List<int> offDays) {
    setState(() {
      _employeeOffDays[attendantName] = EmployeeOffDays(
        attendantId: attendantName,
        attendantName: attendantName,
        weeklyOffDays: offDays,
        customOffDays: _employeeOffDays[attendantName]?.customOffDays ?? {},
      );
      _hasChanges = true;
    });
    
    // Refresh schedule to reflect changes
    _currentSchedule = _generateMockSchedule();
    _assignments = _currentSchedule!.dailyAssignments;
  }

  void _submitLeaveRequest(EmployeeLeave leave) {
    setState(() {
      _leaveRequests.add(leave);
      _hasChanges = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave request submitted for ${leave.attendantName}'),
        backgroundColor: _ShiftConstants.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _approveLeave(EmployeeLeave leave) {
    setState(() {
      leave.status = LeaveStatus.approved;
      leave.approvedBy = 'Manager';
      leave.approvedAt = DateTime.now();
      _hasChanges = true;
    });
    
    // Refresh schedule to reflect changes
    _currentSchedule = _generateMockSchedule();
    _assignments = _currentSchedule!.dailyAssignments;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave approved for ${leave.attendantName}'),
        backgroundColor: _ShiftConstants.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectLeave(EmployeeLeave leave) {
    setState(() {
      leave.status = LeaveStatus.rejected;
      _hasChanges = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave rejected for ${leave.attendantName}'),
        backgroundColor: _ShiftConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getOffDaysString(List<int> offDays) {
    final dayNames = {
      1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'
    };
    return offDays.map((d) => dayNames[d]).join(', ');
  }

  String _getWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormat = DateFormat('dd MMM');
    final endFormat = DateFormat('dd MMM yyyy');
    return '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd)}';
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    return ((days - date.weekday + 10) / 7).floor();
  }

  // UPDATED: Fixed bottom overflow for weekly off days card
  Widget _buildLeaveAndOffDaysTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 200), // Increased to 200
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Off Days Configuration Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Weekly Off Days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set recurring off days for each employee',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableAttendants.length,
                    itemBuilder: (context, index) {
                      final attendant = _availableAttendants[index];
                      final offDays = _employeeOffDays[attendant]?.weeklyOffDays ?? [];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person, color: Color(0xFF0B3D2E), size: 20),
                        title: Text(attendant, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          offDays.isEmpty 
                              ? 'No off days set' 
                              : 'Off: ${_getOffDaysString(offDays)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: offDays.isEmpty ? Colors.grey : Colors.orange,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => EmployeeOffDaysDialog(
                                attendantId: attendant,
                                attendantName: attendant,
                                currentWeeklyOffDays: offDays,
                                onSave: (selectedDays) => _updateEmployeeOffDays(attendant, selectedDays),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Leave Requests Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Leave Requests',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final selectedAttendant = await showDialog<String>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Text('Select Attendant'),
                              children: _availableAttendants.map((attendant) {
                                return SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, attendant),
                                  child: Text(attendant),
                                );
                              }).toList(),
                            ),
                          );
                          if (selectedAttendant != null && mounted) {
                            await showDialog(
                              context: context,
                              builder: (context) => LeaveRequestDialog(
                                attendantId: selectedAttendant,
                                attendantName: selectedAttendant,
                                onRequest: _submitLeaveRequest,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _leaveRequests.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No leave requests'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaveRequests.length,
                          itemBuilder: (context, index) {
                            final leave = _leaveRequests[index];
                            return EmployeeLeaveCard(
                              leave: leave,
                              onApprove: () => _approveLeave(leave),
                              onReject: () => _rejectLeave(leave),
                              onCancel: () {
                                setState(() {
                                  _leaveRequests.removeAt(index);
                                  _hasChanges = true;
                                });
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // Active Leave Summary
          if (_leaveRequests.where((l) => l.isActive).isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currently On Leave',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._leaveRequests.where((l) => l.isActive).map((leave) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${leave.attendantName} - ${leave.type.displayName} until ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          
          // Extra bottom padding
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekRange = _getWeekRange(_currentWeekStart);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shift Configuration'),
        backgroundColor: _ShiftConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Shift Types'),
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Schedule'),
            Tab(icon: Icon(Icons.beach_access), text: 'Leave & Off Days'),
          ],
        ),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ShiftConstants.warningOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Unsaved',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red.shade700),
                          onPressed: () => setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Shift Types Tab
                      Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _shifts.length,
                              itemBuilder: (context, index) {
                                final shift = _shifts[index];
                                return ShiftCard(
                                  shift: shift,
                                  onEdit: () => _editShift(shift),
                                  onToggleActive: (value) => _toggleShiftActive(shift, value),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _addShift,
                                icon: const Icon(Icons.add),
                                label: const Text('Add New Shift'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: _ShiftConstants.primaryDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Schedule Tab
                      Column(
                        children: [
                          // Week Navigation
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _previousWeek,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        weekRange,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Week ${_getWeekNumber(_currentWeekStart)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _nextWeek,
                                ),
                              ],
                            ),
                          ),
                          
                          // Add Assignment Button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _assignShift,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Assign Shift'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ShiftConstants.accentGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          
                          // Schedule View
                          Expanded(
                            child: _currentSchedule != null
                                ? ShiftScheduleView(
                                    schedule: _currentSchedule!,
                                    assignments: _assignments,
                                    onAssignmentTap: (id, assignment) => _showAssignmentDetails(assignment),
                                    onDayTypeTap: (day) async {
                                      final currentType = _currentSchedule!.getDayType(day);
                                      await showDialog(
                                        context: context,
                                        builder: (context) => DayTypeDialog(
                                          day: day,
                                          currentType: currentType,
                                          onSave: (type) => _setDayType(day, type),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                      
                      // Leave & Off Days Tab
                      _buildLeaveAndOffDaysTab(),
                    ],
                  ),
                ),
                
                // Save Button (only on Schedule tab when changes exist)
                if (_hasChanges && _tabController.index == 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ShiftConstants.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'SAVE SCHEDULE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}