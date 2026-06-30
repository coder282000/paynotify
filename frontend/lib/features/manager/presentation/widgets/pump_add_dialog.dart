// lib/features/manager/presentation/widgets/pump_add_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/models/pump_config.dart';

class PumpAddDialog extends StatefulWidget {
  final Function(PumpConfig) onSave;

  const PumpAddDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<PumpAddDialog> createState() => _PumpAddDialogState();
}

class _PumpAddDialogState extends State<PumpAddDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _pumpNumberController = TextEditingController();
  final _attendantNameController = TextEditingController();
  final _currentReadingController = TextEditingController();
  final _tankCapacityController = TextEditingController();
  final _currentFuelLevelController = TextEditingController();
  
  // Selections
  FuelType _selectedFuelType = FuelType.petrol;
  PumpStatus _selectedStatus = PumpStatus.active;
  double _pricePerLiter = 180.50;
  bool _isSaving = false;
  
  // Price depends on fuel type
  void _updatePriceForFuelType(FuelType type) {
    switch (type) {
      case FuelType.petrol:
        _pricePerLiter = 180.50;
        break;
      case FuelType.diesel:
        _pricePerLiter = 165.00;
        break;
      case FuelType.kerosene:
        _pricePerLiter = 120.00;
        break;
      case FuelType.premium:
        _pricePerLiter = 195.00;
        break;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _updatePriceForFuelType(_selectedFuelType);
  }
  
  @override
  void dispose() {
    _pumpNumberController.dispose();
    _attendantNameController.dispose();
    _currentReadingController.dispose();
    _tankCapacityController.dispose();
    _currentFuelLevelController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_gas_station, color: Color(0xFF0B3D2E)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Pump',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Pump Number
                const Text('Pump Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pumpNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Pump 1, Pump A, Pump 7',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a pump number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Fuel Type
                const Text('Fuel Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: FuelType.values.map((type) {
                    final isSelected = _selectedFuelType == type;
                    return FilterChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFuelType = type;
                          _updatePriceForFuelType(type);
                        });
                      },
                      avatar: Icon(
                        type.icon,
                        size: 16,
                        color: isSelected ? Colors.white : type.color,
                      ),
                      selectedColor: type.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Price (auto-filled but can be edited)
                const Text('Price per Liter (KES) *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _pricePerLiter.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'KES/L',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null && price > 0) {
                      _pricePerLiter = price;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Status
                const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      selectedColor: status.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Attendant Name (Optional)
                const Text('Attendant Name (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _attendantNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., John Mwangi',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Current Reading
                const Text('Current Meter Reading (Liters) *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentReadingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Current meter reading',
                    prefixIcon: Icon(Icons.speed),
                    suffixText: 'L',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current reading';
                    }
                    final reading = double.tryParse(value);
                    if (reading == null || reading < 0) {
                      return 'Please enter a valid reading';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Tank Capacity
                const Text('Tank Capacity (Liters) *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tankCapacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Total tank capacity',
                    prefixIcon: Icon(Icons.local_gas_station),
                    suffixText: 'L',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter tank capacity';
                    }
                    final capacity = double.tryParse(value);
                    if (capacity == null || capacity <= 0) {
                      return 'Please enter a valid capacity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Current Fuel Level
                const Text('Current Fuel Level (Liters) *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentFuelLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Current fuel in tank',
                    prefixIcon: Icon(Icons.incomplete_circle),
                    suffixText: 'L',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current fuel level';
                    }
                    final level = double.tryParse(value);
                    if (level == null || level < 0) {
                      return 'Please enter a valid fuel level';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
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
                            : const Text('ADD PUMP'),
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
  
  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final currentReading = double.parse(_currentReadingController.text);
    final tankCapacity = double.parse(_tankCapacityController.text);
    final currentFuelLevel = double.parse(_currentFuelLevelController.text);
    
    final pump = PumpConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: _pumpNumberController.text.trim(),
      fuelType: _selectedFuelType,
      status: _selectedStatus,
      currentAttendantName: _attendantNameController.text.trim().isEmpty 
          ? null 
          : _attendantNameController.text.trim(),
      pricePerLiter: _pricePerLiter,
      currentReading: currentReading,
      previousReading: currentReading, // Initial reading same as current
      lastReadingDate: DateTime.now(),
      tankCapacity: tankCapacity,
      currentFuelLevel: currentFuelLevel,
      lowFuelThreshold: 15,
      isActive: _selectedStatus == PumpStatus.active,
      priceHistory: [],
      maintenanceHistory: [],
    );
    
    widget.onSave(pump);
    if (mounted) Navigator.pop(context);
  }
}