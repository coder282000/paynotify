import 'package:flutter/material.dart';
import '../../domain/models/employee_leave.dart';

class LeaveRequestDialog extends StatefulWidget {
  final String attendantId;
  final String attendantName;
  final Function(EmployeeLeave) onRequest;

  const LeaveRequestDialog({
    super.key,
    required this.attendantId,
    required this.attendantName,
    required this.onRequest,
  });

  @override
  State<LeaveRequestDialog> createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends State<LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  
  LeaveType? _selectedType;
  DateTimeRange? _dateRange;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _dateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 450,
        child: Form(
          key: _formKey,
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
                    child: const Icon(Icons.beach_access, color: Color(0xFF0B3D2E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Leave Request',
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
              DropdownButtonFormField<LeaveType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Leave Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: LeaveType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: type.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
                validator: (value) => value == null ? 'Please select leave type' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: _dateRange,
                  );
                  if (range != null && mounted) {
                    setState(() => _dateRange = range);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date Range *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(
                    '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)} (${_dateRange!.end.difference(_dateRange!.start).inDays + 1} days)',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_outlined),
                  hintText: 'Reason for leave request...',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : () {
                              if (_formKey.currentState!.validate() && _selectedType != null) {
                                setState(() => _isSubmitting = true);
                                
                                final leave = EmployeeLeave(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  attendantId: widget.attendantId,
                                  attendantName: widget.attendantName,
                                  type: _selectedType!,
                                  startDate: _dateRange!.start,
                                  endDate: _dateRange!.end,
                                  status: LeaveStatus.pending,
                                  reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
                                  createdAt: DateTime.now(),
                                );
                                widget.onRequest(leave);
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : const Text('SUBMIT REQUEST'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}