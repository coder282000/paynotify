// lib/features/supervisor/presentation/screens/fuel_refill_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

// MARK: - Constants
class _FuelRefillConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color refillBlue = Color(0xFF3498DB);
}

// MARK: - Fuel Tank Model
class FuelTank {
  final String id;
  final String name;
  final FuelType fuelType;
  final double currentLevel;
  final double capacity;
  final double? lastDeliveryAmount;
  final DateTime? lastDeliveryDate;

  FuelTank({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.currentLevel,
    required this.capacity,
    this.lastDeliveryAmount,
    this.lastDeliveryDate,
  });

  double get levelPercentage => (currentLevel / capacity) * 100;
  double get remainingCapacity => capacity - currentLevel;
  
  String get levelStatus {
    if (levelPercentage <= 10) return 'CRITICAL';
    if (levelPercentage <= 25) return 'LOW';
    if (levelPercentage <= 50) return 'MODERATE';
    return 'GOOD';
  }
  
  Color get levelColor {
    if (levelPercentage <= 10) return _FuelRefillConstants.errorRed;
    if (levelPercentage <= 25) return _FuelRefillConstants.warningOrange;
    if (levelPercentage <= 50) return Colors.orange;
    return _FuelRefillConstants.accentGreen;
  }
}

// Helper function to get default price for fuel type
double _getDefaultPrice(FuelType fuelType) {
  switch (fuelType) {
    case FuelType.petrol:
      return 180.50;
    case FuelType.diesel:
      return 165.00;
    case FuelType.kerosene:
      return 120.00;
    case FuelType.premium:
      return 195.00;
  }
}

class FuelRefillScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;
  final List<OverridePump> pumps;

  const FuelRefillScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
    required this.pumps,
  });

  @override
  State<FuelRefillScreen> createState() => _FuelRefillScreenState();
}

class _FuelRefillScreenState extends State<FuelRefillScreen> {
  // Selection State
  FuelTank? _selectedTank;
  
  // Form Controllers
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _costPerLiterController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Meter Reading Controllers
  final TextEditingController _meterBeforeController = TextEditingController();
  final TextEditingController _meterAfterController = TextEditingController();
  
  // State
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  DateTime _selectedDate = DateTime.now();
  
  // Focus Nodes
  final FocusNode _litersFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();
  final FocusNode _supplierFocus = FocusNode();
  final FocusNode _invoiceFocus = FocusNode();
  final FocusNode _meterBeforeFocus = FocusNode();
  final FocusNode _meterAfterFocus = FocusNode();

  // Mock fuel tanks (in real app, fetch from backend)
  List<FuelTank> _tanks = [];

  @override
  void initState() {
    super.initState();
    _loadTanks();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _costPerLiterController.dispose();
    _supplierController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    _meterBeforeController.dispose();
    _meterAfterController.dispose();
    _litersFocus.dispose();
    _costFocus.dispose();
    _supplierFocus.dispose();
    _invoiceFocus.dispose();
    _meterBeforeFocus.dispose();
    _meterAfterFocus.dispose();
    super.dispose();
  }

  void _loadTanks() {
    // Aggregate pumps by fuel type to create tanks
    final Map<FuelType, double> fuelVolumes = {};
    final Map<FuelType, String> tankNames = {
      FuelType.petrol: 'Tank 1 - Petrol',
      FuelType.diesel: 'Tank 2 - Diesel',
      FuelType.kerosene: 'Tank 5 - Kerosene',
      FuelType.premium: 'Tank 6 - Premium',
    };
    
    for (final pump in widget.pumps) {
      fuelVolumes[pump.fuelType] = (fuelVolumes[pump.fuelType] ?? 0) + pump.currentFuelLevel;
    }
    
    _tanks = fuelVolumes.entries.map((entry) {
      final double capacity = entry.key == FuelType.diesel ? 15000.0 : 10000.0;
      return FuelTank(
        id: entry.key.name,
        name: tankNames[entry.key] ?? '${entry.key.displayName} Tank',
        fuelType: entry.key,
        currentLevel: entry.value,
        capacity: capacity,
        lastDeliveryDate: DateTime.now().subtract(const Duration(days: 5)),
        lastDeliveryAmount: 5000.0,
      );
    }).toList();
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return NumberFormat('#,##0.##').format(number);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', ''));
  }

  void _updateInventoryCalculation() {
    final liters = _parseNumber(_litersController.text);
    final costPerLiter = _parseNumber(_costPerLiterController.text);
    
    if (liters != null && costPerLiter != null && mounted) {
      setState(() {});
    }
  }

  double get _totalCost {
    final liters = _parseNumber(_litersController.text);
    final costPerLiter = _parseNumber(_costPerLiterController.text);
    if (liters != null && costPerLiter != null) {
      return liters * costPerLiter;
    }
    return 0;
  }

  bool get _isMeterReadingValid {
    final before = _parseNumber(_meterBeforeController.text);
    final after = _parseNumber(_meterAfterController.text);
    if (before != null && after != null) {
      return after >= before;
    }
    return true;
  }

  double? get _calculatedDispensed {
    final before = _parseNumber(_meterBeforeController.text);
    final after = _parseNumber(_meterAfterController.text);
    if (before != null && after != null && after >= before) {
      return after - before;
    }
    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _FuelRefillConstants.primaryDark,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _recordRefill() async {
    // Validate tank selection
    if (_selectedTank == null) {
      setState(() => _errorMessage = 'Please select a fuel tank');
      return;
    }

    // Validate liters
    final liters = _parseNumber(_litersController.text);
    if (liters == null || liters <= 0) {
      setState(() => _errorMessage = 'Please enter a valid number of liters');
      return;
    }

    if (liters > _selectedTank!.remainingCapacity) {
      setState(() => _errorMessage = 'Liters exceed remaining capacity (${_formatNumber(_selectedTank!.remainingCapacity.toString())} L available)');
      return;
    }

    // Validate cost per liter
    final costPerLiter = _parseNumber(_costPerLiterController.text);
    if (costPerLiter == null || costPerLiter <= 0) {
      setState(() => _errorMessage = 'Please enter a valid cost per liter');
      return;
    }

    // Validate supplier
    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty) {
      setState(() => _errorMessage = 'Please enter supplier name');
      return;
    }

    // Validate meter readings if both entered
    if (!_isMeterReadingValid) {
      setState(() => _errorMessage = 'Meter after reading must be greater than or equal to meter before');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(liters, costPerLiter, supplier);
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Calculate new fuel level
    final newLevel = _selectedTank!.currentLevel + liters;
    
    setState(() {
      _isProcessing = false;
      _successMessage = 'Successfully recorded ${_formatNumber(liters.toString())}L of ${_selectedTank!.fuelType.displayName}!\nNew fuel level: ${_formatNumber(newLevel.toString())}L';
    });

    HapticFeedback.mediumImpact();

    // Reset form after success
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _resetForm();
      }
    });
  }

  Future<bool?> _showConfirmationDialog(double liters, double costPerLiter, String supplier) async {
    final totalCost = liters * costPerLiter;
    final newLevel = _selectedTank!.currentLevel + liters;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_gas_station, color: _FuelRefillConstants.refillBlue),
            const SizedBox(width: 8),
            const Text('Confirm Fuel Refill'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _FuelRefillConstants.refillBlue.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: _FuelRefillConstants.refillBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will update inventory automatically',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _FuelRefillConstants.refillBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Tank', _selectedTank!.name),
            _buildConfirmationRow('Fuel Type', _selectedTank!.fuelType.displayName),
            _buildConfirmationRow('Liters Added', '${_formatNumber(liters.toString())} L'),
            _buildConfirmationRow('Cost per Liter', 'KES ${_formatNumber(costPerLiter.toString())}'),
            _buildConfirmationRow('Total Cost', 'KES ${_formatNumber(totalCost.toString())}'),
            _buildConfirmationRow('Supplier', supplier),
            if (_invoiceController.text.trim().isNotEmpty)
              _buildConfirmationRow('Invoice #', _invoiceController.text.trim()),
            const Divider(height: 24),
            _buildConfirmationRow(
              'Current Level',
              '${_formatNumber(_selectedTank!.currentLevel.toString())} L',
            ),
            _buildConfirmationRow(
              'New Level',
              '${_formatNumber(newLevel.toString())} L',
              valueColor: _FuelRefillConstants.accentGreen,
            ),
            if (_calculatedDispensed != null)
              _buildConfirmationRow(
                'Meter Difference',
                '${_formatNumber(_calculatedDispensed!.toString())} L',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _FuelRefillConstants.refillBlue,
            ),
            child: const Text('Confirm Refill'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _litersController.clear();
      _costPerLiterController.clear();
      _supplierController.clear();
      _invoiceController.clear();
      _notesController.clear();
      _meterBeforeController.clear();
      _meterAfterController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
    _litersFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Fuel Refill - Record Delivery'),
        backgroundColor: _FuelRefillConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _FuelRefillConstants.refillBlue.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _FuelRefillConstants.refillBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record fuel deliveries to automatically update inventory levels',
                        style: TextStyle(color: _FuelRefillConstants.refillBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tank Selection
              const Text(
                'Select Fuel Tank',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tanks.length,
                  itemBuilder: (context, index) {
                    final tank = _tanks[index];
                    final bool isSelected = _selectedTank?.id == tank.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTank = tank;
                          // Auto-populate cost per liter with default price using helper function
                          _costPerLiterController.text = _getDefaultPrice(tank.fuelType).toString();
                          _errorMessage = null;
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? tank.fuelType.color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tank.fuelType.color,
                            width: isSelected ? 0 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: tank.fuelType.color.withAlpha(77),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tank.fuelType.icon,
                                  color: isSelected ? Colors.white : tank.fuelType.color,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tank.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatNumber(tank.currentLevel.toString())} L',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : tank.fuelType.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'of ${_formatNumber(tank.capacity.toString())} L',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white.withAlpha(204) : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withAlpha(77) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: tank.levelPercentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : tank.levelColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_selectedTank != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedTank!.fuelType.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Level: ${_formatNumber(_selectedTank!.currentLevel.toString())} L',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remaining Capacity: ${_formatNumber(_selectedTank!.remainingCapacity.toString())} L',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedTank!.levelColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedTank!.levelStatus,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Refill Details
              const Text(
                'Refill Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Date Selection
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Delivery Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                onTap: _selectDate,
              ),

              const SizedBox(height: 8),

              // Liters Added
              TextFormField(
                controller: _litersController,
                focusNode: _litersFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Liters Added *',
                  hintText: 'e.g., 5000',
                  prefixIcon: const Icon(Icons.local_gas_station),
                  border: const OutlineInputBorder(),
                  suffixText: 'L',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onChanged: (value) {
                  final cursorPos = _litersController.selection.start;
                  _litersController.text = _formatNumber(value);
                  _litersController.selection = TextSelection.collapsed(
                    offset: cursorPos + (_litersController.text.length - value.length),
                  );
                  _updateInventoryCalculation();
                },
              ),

              const SizedBox(height: 12),

              // Cost per Liter
              TextFormField(
                controller: _costPerLiterController,
                focusNode: _costFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cost per Liter (KES) *',
                  hintText: 'e.g., 180.50',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  suffixText: 'KES/L',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onChanged: (value) {
                  final cursorPos = _costPerLiterController.selection.start;
                  _costPerLiterController.text = _formatNumber(value);
                  _costPerLiterController.selection = TextSelection.collapsed(
                    offset: cursorPos + (_costPerLiterController.text.length - value.length),
                  );
                  _updateInventoryCalculation();
                },
              ),

              // Total Cost Display
              if (_totalCost > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _FuelRefillConstants.accentGreen.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Cost:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'KES ${_formatNumber(_totalCost.toString())}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _FuelRefillConstants.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Supplier Name
              TextFormField(
                controller: _supplierController,
                focusNode: _supplierFocus,
                decoration: InputDecoration(
                  labelText: 'Supplier Name *',
                  hintText: 'e.g., Total Energies, Vivo Energy',
                  prefixIcon: const Icon(Icons.business),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Invoice Number (Optional)
              TextFormField(
                controller: _invoiceController,
                focusNode: _invoiceFocus,
                decoration: InputDecoration(
                  labelText: 'Invoice Number (Optional)',
                  hintText: 'e.g., INV-2024-001',
                  prefixIcon: const Icon(Icons.receipt),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Meter Readings Section (Optional but recommended)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, color: _FuelRefillConstants.warningOrange),
                        const SizedBox(width: 8),
                        const Text(
                          'Meter Readings (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _meterBeforeController,
                            focusNode: _meterBeforeFocus,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Before (L)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _meterAfterController,
                            focusNode: _meterAfterFocus,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'After (L)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (_calculatedDispensed != null && _calculatedDispensed! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Dispensed since last reading: ${_formatNumber(_calculatedDispensed!.toString())} L',
                          style: TextStyle(
                            fontSize: 12,
                            color: _FuelRefillConstants.warningOrange,
                          ),
                        ),
                      ),
                    if (!_isMeterReadingValid && _meterAfterController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ Meter after must be >= meter before',
                          style: TextStyle(
                            fontSize: 12,
                            color: _FuelRefillConstants.errorRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional notes about delivery, quality, etc.',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Success Message
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _recordRefill,
                      icon: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: _isProcessing
                          ? const Text('Recording...')
                          : const Text('Record Refill', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _FuelRefillConstants.refillBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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