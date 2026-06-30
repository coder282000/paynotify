// lib/features/manager/presentation/widgets/employee_off_days_dialog.dart

import 'package:flutter/material.dart';

class EmployeeOffDaysDialog extends StatefulWidget {
  final String attendantId;
  final String attendantName;
  final List<int> currentWeeklyOffDays;
  final Function(List<int>) onSave;

  const EmployeeOffDaysDialog({
    super.key,
    required this.attendantId,
    required this.attendantName,
    required this.currentWeeklyOffDays,
    required this.onSave,
  });

  @override
  State<EmployeeOffDaysDialog> createState() => _EmployeeOffDaysDialogState();
}

class _EmployeeOffDaysDialogState extends State<EmployeeOffDaysDialog> {
  late List<int> _selectedDays;
  bool _isSaving = false;
  
  final List<Map<String, dynamic>> _daysOfWeek = [
    {'name': 'Monday', 'value': 1},
    {'name': 'Tuesday', 'value': 2},
    {'name': 'Wednesday', 'value': 3},
    {'name': 'Thursday', 'value': 4},
    {'name': 'Friday', 'value': 5},
    {'name': 'Saturday', 'value': 6},
    {'name': 'Sunday', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.currentWeeklyOffDays);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      widget.onSave(_selectedDays);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit height to 70% of screen
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today, color: Color(0xFF0B3D2E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Off Days',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.attendantName,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Select weekly off days for this attendant:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ..._daysOfWeek.map((day) {
                      final isSelected = _selectedDays.contains(day['value']);
                      return CheckboxListTile(
                        title: Text(day['name']),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedDays.add(day['value']);
                            } else {
                              _selectedDays.remove(day['value']);
                            }
                          });
                        },
                        activeColor: const Color(0xFF0B3D2E),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Attendant will not be assigned shifts on selected off days',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF0B3D2E)),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('SAVE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}