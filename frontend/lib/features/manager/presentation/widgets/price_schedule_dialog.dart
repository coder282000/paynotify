// lib/features/manager/presentation/widgets/price_schedule_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pump_config.dart';

class PriceScheduleDialog extends StatefulWidget {
  final FuelType fuelType;
  final double currentPrice;
  final Function(double newPrice, DateTime date, String? reason) onSchedule;

  const PriceScheduleDialog({
    super.key,
    required this.fuelType,
    required this.currentPrice,
    required this.onSchedule,
  });

  @override
  State<PriceScheduleDialog> createState() => _PriceScheduleDialogState();
}

class _PriceScheduleDialogState extends State<PriceScheduleDialog> {
  final _priceController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  // ignore: prefer_final_fields
  bool _isLoading = false; // This changes state, so it cannot be final

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.fuelType.color,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.fuelType.color.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.fuelType.icon,
                      color: widget.fuelType.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Price Change',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.fuelType.displayName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Current price
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Price:',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'KES ${widget.currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // New price
              Semantics(
                label: 'Enter new price',
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'New Price (KES/L)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Enter the new price per liter',
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date selector
              Semantics(
                button: true,
                label: 'Select effective date for price change',
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Effective Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Reason
              Semantics(
                label: 'Reason for price change',
                child: TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for change (optional)',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'e.g., Market adjustment, Tax increase, Promotion',
                  ),
                  maxLines: 2,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Cancel price schedule',
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: widget.fuelType.color),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Schedule price change',
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_priceController.text.isEmpty) return;
                                
                                final newPrice = double.tryParse(_priceController.text);
                                if (newPrice == null || newPrice <= 0) return;
                                
                                widget.onSchedule(
                                  newPrice,
                                  _selectedDate,
                                  _reasonController.text.isNotEmpty ? _reasonController.text : null,
                                );
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.fuelType.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Schedule'),
                      ),
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
}