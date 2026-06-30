// lib/features/manager/presentation/widgets/shift_creation_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/models/shift_model.dart';

class ShiftCreationDialog extends StatefulWidget {
  final Function(Shift) onSave;

  const ShiftCreationDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<ShiftCreationDialog> createState() => _ShiftCreationDialogState();
}

class _ShiftCreationDialogState extends State<ShiftCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shiftNameController;
  late TextEditingController _overtimeRateController;
  
  ShiftType? _selectedType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isActive = true;
  bool _isSaving = false;

  final List<ShiftType> _shiftTypes = [
    ShiftType.morning,
    ShiftType.evening,
    ShiftType.night,
  ];

  @override
  void initState() {
    super.initState();
    _shiftNameController = TextEditingController();
    _overtimeRateController = TextEditingController(text: '1.5');
    _startTime = const TimeOfDay(hour: 6, minute: 0);
    _endTime = const TimeOfDay(hour: 14, minute: 0);
  }

  @override
  void dispose() {
    _shiftNameController.dispose();
    _overtimeRateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime!,
    );
    if (time != null && mounted) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime!,
    );
    if (time != null && mounted) {
      setState(() => _endTime = time);
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showError('Please select a shift type');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showError('Please select start and end times');
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final shift = Shift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType!,
      startTime: _startTime!,
      endTime: _endTime!,
      overtimeRate: double.tryParse(_overtimeRateController.text) ?? 1.5,
      isActive: _isActive,
    );

    widget.onSave(shift);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      child: const Icon(Icons.schedule, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Shift',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Shift Type
                const Text('Shift Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _shiftTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                      avatar: Icon(
                        type.icon,
                        color: isSelected ? Colors.white : type.color,
                        size: 16,
                      ),
                      selectedColor: type.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Start Time
                const Text('Start Time *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectStartTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.wb_sunny),
                    ),
                    child: Text(_formatTimeOfDay(_startTime!)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // End Time
                const Text('End Time *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectEndTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.nightlight_round),
                    ),
                    child: Text(_formatTimeOfDay(_endTime!)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Overtime Rate
                TextFormField(
                  controller: _overtimeRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Overtime Rate (x)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                    suffixText: 'x',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Please enter a valid rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Active Switch
                SwitchListTile(
                  title: const Text('Active Shift'),
                  subtitle: const Text('Shift will be available for assignment'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                  activeThumbColor: const Color(0xFF2ECC71),
                  contentPadding: EdgeInsets.zero,
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
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                            : const Text('CREATE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}