// lib/features/manager/presentation/widgets/shift_assignment.dart

import 'package:flutter/material.dart';
import '../../domain/models/shift_model.dart';
import '../../domain/models/shift_assignment.dart';

class ShiftAssignmentDialog extends StatefulWidget {
  final List<String> availableAttendants;
  final List<Shift> availableShifts;
  final DateTime selectedDate;
  final Function(List<ShiftAssignment>) onAssign;

  const ShiftAssignmentDialog({
    super.key,
    required this.availableAttendants,
    required this.availableShifts,
    required this.selectedDate,
    required this.onAssign,
  });

  @override
  State<ShiftAssignmentDialog> createState() => _ShiftAssignmentDialogState();
}

class _ShiftAssignmentDialogState extends State<ShiftAssignmentDialog> {
  final List<String> _selectedAttendants = [];
  String? _selectedShiftId;
  ShiftType? _selectedShiftType;
  String? _notes;
  bool _isSubmitting = false;
  
  final List<String> _selectedDays = [];
  
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    final shifts = widget.availableShifts.where((s) => s.isActive).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  child: const Icon(Icons.person_add, color: Color(0xFF0B3D2E)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Assign Shift (Weekly)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attendants Selection
                    const Text('Select Attendants *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.availableAttendants.length,
                        itemBuilder: (context, index) {
                          final attendant = widget.availableAttendants[index];
                          final isSelected = _selectedAttendants.contains(attendant);
                          return CheckboxListTile(
                            title: Text(attendant, style: const TextStyle(fontSize: 13)),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedAttendants.add(attendant);
                                } else {
                                  _selectedAttendants.remove(attendant);
                                }
                              });
                            },
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Shift Selection - Fixed dropdown with constrained menu
                    const Text('Select Shift *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text('Choose a shift'),
                          ),
                          value: _selectedShiftId,
                          items: shifts.map((shift) {
                            return DropdownMenuItem(
                              value: shift.id,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(shift.type.icon, size: 16, color: shift.type.color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(shift.type.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          Text(
                                            shift.formattedTime,
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final shift = shifts.firstWhere((s) => s.id == value);
                            setState(() {
                              _selectedShiftId = value;
                              _selectedShiftType = shift.type;
                            });
                          },
                          selectedItemBuilder: (context) {
                            return shifts.map((shift) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Text(shift.type.displayName),
                              );
                            }).toList();
                          },
                          menuMaxHeight: 200, // Limit dropdown menu height
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Days Selection
                    const Text('Select Days *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 180,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _daysOfWeek.length,
                        itemBuilder: (context, index) {
                          final day = _daysOfWeek[index];
                          final isSelected = _selectedDays.contains(day);
                          return CheckboxListTile(
                            title: Text(day, style: const TextStyle(fontSize: 13)),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note_outlined),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) => _notes = value,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_selectedAttendants.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select at least one attendant'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            if (_selectedShiftId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a shift'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            if (_selectedDays.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select at least one day'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            
                            setState(() => _isSubmitting = true);
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            if (!mounted) return;
                            
                            final List<ShiftAssignment> assignments = [];
                            
                            for (final attendant in _selectedAttendants) {
                              for (final day in _selectedDays) {
                                final date = _getDateForDayOfWeek(day, widget.selectedDate);
                                
                                assignments.add(
                                  ShiftAssignment(
                                    id: '${DateTime.now().millisecondsSinceEpoch}_${attendant}_$day',
                                    attendantId: attendant,
                                    attendantName: attendant,
                                    shiftId: _selectedShiftId!,
                                    shiftType: _selectedShiftType!,
                                    date: date,
                                    status: ShiftAssignmentStatus.scheduled,
                                    notes: _notes,
                                  ),
                                );
                              }
                            }
                            
                            widget.onAssign(assignments);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('ASSIGN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getDateForDayOfWeek(String dayName, DateTime referenceDate) {
    final weekdays = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    
    final targetWeekday = weekdays[dayName] ?? 1;
    final currentWeekday = referenceDate.weekday;
    final daysToAdd = targetWeekday - currentWeekday;
    
    return referenceDate.add(Duration(days: daysToAdd));
  }
}