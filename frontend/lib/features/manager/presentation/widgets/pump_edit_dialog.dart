// lib/features/manager/presentation/widgets/pump_edit_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/models/pump_config.dart';

class PumpEditDialog extends StatefulWidget {
  final PumpConfig pump;

  const PumpEditDialog({super.key, required this.pump});

  @override
  State<PumpEditDialog> createState() => _PumpEditDialogState();
}

class _PumpEditDialogState extends State<PumpEditDialog> {
  late TextEditingController _priceController;
  late TextEditingController _readingController;
  late TextEditingController _fuelLevelController;
  late FuelType _selectedFuelType;
  late PumpStatus _selectedStatus;
  bool _isLoading = false;
  bool _applyToAllSameFuelType = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.pump.pricePerLiter.toStringAsFixed(2),
    );
    _readingController = TextEditingController(
      text: widget.pump.currentReading.toStringAsFixed(1),
    );
    _fuelLevelController = TextEditingController(
      text: widget.pump.currentFuelLevel.toStringAsFixed(0),
    );
    _selectedFuelType = widget.pump.fuelType;
    _selectedStatus = widget.pump.status;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _readingController.dispose();
    _fuelLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Validate price
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice == null || newPrice <= 0) {
      _showError('Please enter a valid price');
      return;
    }

    // Validate meter reading
    final newReading = double.tryParse(_readingController.text);
    if (newReading == null || newReading < 0) {
      _showError('Please enter a valid meter reading');
      return;
    }

    // Validate fuel level
    final newFuelLevel = double.tryParse(_fuelLevelController.text);
    if (newFuelLevel == null || newFuelLevel < 0) {
      _showError('Please enter a valid fuel level');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final updatedPump = PumpConfig(
      id: widget.pump.id,
      number: widget.pump.number,
      fuelType: _selectedFuelType,
      status: _selectedStatus,
      pricePerLiter: newPrice,
      currentReading: newReading,
      tankCapacity: widget.pump.tankCapacity,
      currentFuelLevel: newFuelLevel,
      isActive: _selectedStatus == PumpStatus.active,
      priceHistory: widget.pump.priceHistory,
      maintenanceHistory: widget.pump.maintenanceHistory,
    );

    Navigator.pop(context, {
      'pump': updatedPump,
      'applyToAllSameFuelType': _applyToAllSameFuelType,
      'priceChanged': newPrice != widget.pump.pricePerLiter,
    });
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
        width: 500,
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
                      color: const Color(0xFF0B3D2E).withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF0B3D2E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit ${widget.pump.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Fuel Type Selection
              const Text(
                'Fuel Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: FuelType.values.map((type) {
                  final isSelected = _selectedFuelType == type;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFuelType = type);
                      }
                    },
                    avatar: Icon(
                      type.icon,
                      color: isSelected ? Colors.white : type.color,
                      size: 16,
                    ),
                    selectedColor: type.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Status Selection
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PumpStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = status);
                      }
                    },
                    avatar: Icon(
                      status.icon,
                      color: isSelected ? Colors.white : status.color,
                      size: 16,
                    ),
                    selectedColor: status.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Price per Liter
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per Liter (KES)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Current price: KES ${widget.pump.pricePerLiter.toStringAsFixed(2)}',
                ),
              ),
              
              // Option to apply price to all pumps of same fuel type
              if (_priceController.text != widget.pump.pricePerLiter.toStringAsFixed(2))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Apply this price to all pumps of the same fuel type',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _applyToAllSameFuelType,
                    onChanged: (value) {
                      setState(() {
                        _applyToAllSameFuelType = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Current Meter Reading
              TextField(
                controller: _readingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Meter Reading (L)',
                  prefixIcon: const Icon(Icons.speed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Previous reading: ${widget.pump.previousReading?.toStringAsFixed(1) ?? 'N/A'} L',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Current Fuel Level
              TextField(
                controller: _fuelLevelController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Fuel Level (L)',
                  prefixIcon: const Icon(Icons.local_gas_station),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Tank capacity: ${widget.pump.tankCapacity.toStringAsFixed(0)} L',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Low Fuel Warning
              if (double.tryParse(_fuelLevelController.text) != null &&
                  double.parse(_fuelLevelController.text) < 
                  widget.pump.tankCapacity * 0.15)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fuel level is below 15%. Consider scheduling a refill.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Price Change Warning
              if (widget.pump.pricePerLiter != double.tryParse(_priceController.text))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Price change will be recorded in price history.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
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
                          : const Text('Save Changes'),
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