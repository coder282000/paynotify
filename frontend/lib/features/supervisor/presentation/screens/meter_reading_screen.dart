// lib/features/supervisor/presentation/screens/meter_reading_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

// MARK: - Constants
class _MeterReadingConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color readingPurple = Color(0xFF9B59B6);
}

// MARK: - Reading Type Enum
enum ReadingType {
  opening('Opening Reading', Icons.play_arrow, Colors.green, 'Start of shift'),
  closing('Closing Reading', Icons.stop, Colors.red, 'End of shift'),
  interim('Interim Reading', Icons.speed, Colors.blue, 'Mid-shift check'),
  spot('Spot Check', Icons.remove_red_eye, Colors.orange, 'Random verification');

  final String displayName;
  final IconData icon;
  final Color color;
  final String description;

  const ReadingType(this.displayName, this.icon, this.color, this.description);
}

// MARK: - Meter Reading Record Model
class MeterReadingRecord {
  final String id;
  final String pumpId;
  final String pumpName;
  final double readingValue;
  final ReadingType readingType;
  final String supervisorId;
  final String supervisorName;
  final DateTime timestamp;
  final double? previousReading;
  final double? calculatedDispensed;
  final String? notes;

  MeterReadingRecord({
    required this.id,
    required this.pumpId,
    required this.pumpName,
    required this.readingValue,
    required this.readingType,
    required this.supervisorId,
    required this.supervisorName,
    required this.timestamp,
    this.previousReading,
    this.calculatedDispensed,
    this.notes,
  });

  String get formattedReading => NumberFormat('#,##0.0').format(readingValue);
  String get formattedDispensed => calculatedDispensed != null 
      ? NumberFormat('#,##0.0').format(calculatedDispensed!) 
      : 'N/A';
}

class MeterReadingScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;
  final List<OverridePump> pumps;

  const MeterReadingScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
    required this.pumps,
  });

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  // Selection State
  OverridePump? _selectedPump;
  ReadingType _selectedReadingType = ReadingType.interim;
  
  // Form Controllers
  final TextEditingController _readingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // State
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  List<MeterReadingRecord> _recentReadings = [];
  
  // Focus Nodes
  final FocusNode _readingFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  // Mock previous readings (in real app, fetch from backend)
  final Map<String, double> _previousReadings = {
    '1': 12345.6,
    '2': 23456.7,
    '3': 34567.8,
    '4': 45678.9,
    '5': 56789.0,
    '6': 67890.1,
  };

  @override
  void initState() {
    super.initState();
    _loadRecentReadings();
  }

  @override
  void dispose() {
    _readingController.dispose();
    _notesController.dispose();
    _readingFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _loadRecentReadings() {
    final now = DateTime.now();
    _recentReadings = [
      MeterReadingRecord(
        id: '1',
        pumpId: '1',
        pumpName: 'Pump 1',
        readingValue: 12345.6,
        readingType: ReadingType.opening,
        supervisorId: widget.supervisorId,
        supervisorName: widget.supervisorName,
        timestamp: now.subtract(const Duration(hours: 8)),
        notes: 'Start of shift reading',
      ),
      MeterReadingRecord(
        id: '2',
        pumpId: '2',
        pumpName: 'Pump 2',
        readingValue: 23456.7,
        readingType: ReadingType.opening,
        supervisorId: widget.supervisorId,
        supervisorName: widget.supervisorName,
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
      MeterReadingRecord(
        id: '3',
        pumpId: '1',
        pumpName: 'Pump 1',
        readingValue: 12425.8,
        readingType: ReadingType.closing,
        supervisorId: widget.supervisorId,
        supervisorName: widget.supervisorName,
        timestamp: now.subtract(const Duration(hours: 1)),
        previousReading: 12345.6,
        calculatedDispensed: 80.2,
        notes: 'End of shift - 80.2L dispensed',
      ),
    ];
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return NumberFormat('#,##0.0').format(number);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', ''));
  }

  double? get _previousReadingForSelectedPump {
    if (_selectedPump == null) return null;
    return _previousReadings[_selectedPump!.id];
  }

  double? get _calculatedDispensed {
    final current = _parseNumber(_readingController.text);
    final previous = _previousReadingForSelectedPump;
    if (current != null && previous != null && current >= previous) {
      return current - previous;
    }
    return null;
  }

  bool get _isValidReading {
    final current = _parseNumber(_readingController.text);
    final previous = _previousReadingForSelectedPump;
    if (current == null) return false;
    if (previous != null && current < previous) return false;
    return true;
  }

  String? get _validationMessage {
    final current = _parseNumber(_readingController.text);
    final previous = _previousReadingForSelectedPump;
    if (current == null) return null;
    if (previous != null && current < previous) {
      return '⚠️ Current reading (${_formatNumber(current.toString())}) is less than previous reading (${_formatNumber(previous.toString())})';
    }
    return null;
  }

  Future<void> _submitReading() async {
    // Validate pump selection
    if (_selectedPump == null) {
      setState(() => _errorMessage = 'Please select a pump');
      return;
    }

    // Validate reading value
    final readingValue = _parseNumber(_readingController.text);
    if (readingValue == null || readingValue <= 0) {
      setState(() => _errorMessage = 'Please enter a valid meter reading');
      return;
    }

    if (!_isValidReading) {
      setState(() => _errorMessage = _validationMessage);
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(readingValue);
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Create reading record
    final newReading = MeterReadingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pumpId: _selectedPump!.id,
      pumpName: _selectedPump!.name,
      readingValue: readingValue,
      readingType: _selectedReadingType,
      supervisorId: widget.supervisorId,
      supervisorName: widget.supervisorName,
      timestamp: DateTime.now(),
      previousReading: _previousReadingForSelectedPump,
      calculatedDispensed: _calculatedDispensed,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _recentReadings.insert(0, newReading);
      _isProcessing = false;
      _successMessage = '${_selectedReadingType.displayName} recorded for ${_selectedPump!.name}\nNew reading: ${_formatNumber(readingValue.toString())} L';
    });

    HapticFeedback.mediumImpact();

    // Update previous reading for this pump
    _previousReadings[_selectedPump!.id] = readingValue;

    // Reset form after success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _resetForm();
      }
    });
  }

  Future<bool?> _showConfirmationDialog(double readingValue) async {
    final dispensed = _calculatedDispensed;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_selectedReadingType.icon, color: _selectedReadingType.color),
            const SizedBox(width: 8),
            Text(_selectedReadingType.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _MeterReadingConstants.readingPurple.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: _MeterReadingConstants.readingPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedReadingType.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: _MeterReadingConstants.readingPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Pump', _selectedPump!.name),
            _buildConfirmationRow('Fuel Type', _selectedPump!.fuelType.displayName),
            _buildConfirmationRow('Reading', '${_formatNumber(readingValue.toString())} L'),
            if (_previousReadingForSelectedPump != null)
              _buildConfirmationRow(
                'Previous Reading',
                '${_formatNumber(_previousReadingForSelectedPump!.toString())} L',
              ),
            if (dispensed != null)
              _buildConfirmationRow(
                'Dispensed Since Last',
                '${_formatNumber(dispensed.toString())} L',
                valueColor: _MeterReadingConstants.accentGreen,
              ),
            if (_notesController.text.trim().isNotEmpty)
              _buildConfirmationRow('Notes', _notesController.text.trim()),
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
              backgroundColor: _selectedReadingType.color,
            ),
            child: const Text('Confirm Reading'),
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
      _readingController.clear();
      _notesController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
    _readingFocus.requestFocus();
  }

  void _showReadingDetails(MeterReadingRecord reading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${reading.readingType.displayName} Details'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Pump', reading.pumpName),
            _buildDetailRow('Date', DateFormat('dd MMM yyyy, HH:mm').format(reading.timestamp)),
            _buildDetailRow('Reading', '${reading.formattedReading} L'),
            if (reading.previousReading != null)
              _buildDetailRow('Previous Reading', '${NumberFormat('#,##0.0').format(reading.previousReading!)} L'),
            if (reading.calculatedDispensed != null)
              _buildDetailRow('Dispensed', '${reading.formattedDispensed} L'),
            _buildDetailRow('Recorded By', reading.supervisorName),
            if (reading.notes != null)
              _buildDetailRow('Notes', reading.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter active pumps only
    final activePumps = widget.pumps.where(
      (p) => p.status != PumpStatus.maintenance
    ).toList();

    // Calculate warning count for the banner
    final int warningCount = activePumps.where(
      (p) => p.fuelPercentage <= 25
    ).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Meter Readings'),
        backgroundColor: _MeterReadingConstants.primaryDark,
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
              // Info Banner - Using readingPurple
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _MeterReadingConstants.readingPurple.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _MeterReadingConstants.readingPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Record meter readings to track fuel dispensed and monitor pump accuracy',
                        style: TextStyle(color: _MeterReadingConstants.readingPurple),
                      ),
                    ),
                  ],
                ),
              ),

              // Warning Banner - Using warningOrange
              if (warningCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _MeterReadingConstants.warningOrange.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _MeterReadingConstants.warningOrange.withAlpha(77),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: _MeterReadingConstants.warningOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$warningCount pump(s) have low fuel level (≤25%). Consider recording readings soon.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _MeterReadingConstants.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Pump Selection
              const Text(
                'Select Pump',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activePumps.map((pump) {
                  final bool isSelected = _selectedPump?.id == pump.id;
                  final bool isLowFuel = pump.fuelPercentage <= 25;
                  
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pump.fuelType.icon,
                          size: 16,
                          color: isSelected ? Colors.white : 
                                 (isLowFuel ? _MeterReadingConstants.warningOrange : pump.fuelType.color),
                        ),
                        const SizedBox(width: 4),
                        Text(pump.name),
                        if (pump.attendantName != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${pump.attendantName})',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPump = pump;
                        _readingController.clear();
                        _errorMessage = null;
                      });
                      HapticFeedback.lightImpact();
                    },
                    backgroundColor: isLowFuel && !isSelected
                        ? _MeterReadingConstants.warningOrange.withAlpha(26)
                        : Colors.grey.shade100,
                    selectedColor: pump.fuelType.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : 
                             (isLowFuel ? _MeterReadingConstants.warningOrange : Colors.black),
                    ),
                  );
                }).toList(),
              ),

              if (_selectedPump != null) ...[
                const SizedBox(height: 16),
                
                // Selected Pump Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedPump!.fuelType.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedPump!.fuelType.icon,
                            color: _selectedPump!.fuelType.color,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPump!.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedPump!.fuelType.color,
                                  ),
                                ),
                                Text(
                                  '${_selectedPump!.fuelType.displayName} • KES ${_selectedPump!.pricePerLiter.toStringAsFixed(2)}/L',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedPump!.fuelType.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_previousReadingForSelectedPump != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(77),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Last recorded reading:',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${_formatNumber(_previousReadingForSelectedPump!.toString())} L',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPump!.fuelType.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Low fuel warning - Using errorRed
                      if (_selectedPump!.fuelPercentage <= 15)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _MeterReadingConstants.errorRed.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, size: 16, color: _MeterReadingConstants.errorRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'CRITICAL: Fuel level at ${_selectedPump!.fuelPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _MeterReadingConstants.errorRed,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Reading Type Selection
              const Text(
                'Reading Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReadingType.values.map((type) {
                    final bool isSelected = _selectedReadingType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedReadingType = type);
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? type.color : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: type.color,
                              width: isSelected ? 0 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected ? Colors.white : type.color,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : type.color,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Reading Value Input
              const Text(
                'Meter Reading (Liters)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _readingController,
                focusNode: _readingFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter current meter reading',
                  prefixIcon: const Icon(Icons.speed),
                  border: const OutlineInputBorder(),
                  suffixText: 'L',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  errorText: _validationMessage,
                  errorMaxLines: 2,
                ),
                onChanged: (value) {
                  final cursorPos = _readingController.selection.start;
                  _readingController.text = _formatNumber(value);
                  _readingController.selection = TextSelection.collapsed(
                    offset: cursorPos + (_readingController.text.length - value.length),
                  );
                  setState(() {});
                },
              ),

              // Auto-calculated dispensed
              if (_calculatedDispensed != null && _calculatedDispensed! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _MeterReadingConstants.accentGreen.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, color: _MeterReadingConstants.accentGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calculated Fuel Dispensed',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${_formatNumber(_calculatedDispensed!.toString())} L',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _MeterReadingConstants.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                focusNode: _notesFocus,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g., Meter calibrated, unusual reading, etc.',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message - Using errorRed
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _MeterReadingConstants.errorRed.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _MeterReadingConstants.errorRed.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: _MeterReadingConstants.errorRed, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: _MeterReadingConstants.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Success Message - Using accentGreen
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _MeterReadingConstants.accentGreen.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _MeterReadingConstants.accentGreen.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: _MeterReadingConstants.accentGreen, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: _MeterReadingConstants.accentGreen, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _submitReading,
                  icon: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_selectedReadingType.icon),
                  label: _isProcessing
                      ? const Text('Recording...')
                      : Text('Record ${_selectedReadingType.displayName}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedReadingType.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Readings Section
              if (_recentReadings.isNotEmpty) ...[
                const Text(
                  'Recent Readings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _recentReadings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showReadingDetails(reading),
                        leading: CircleAvatar(
                          backgroundColor: reading.readingType.color.withAlpha(26),
                          child: Icon(
                            reading.readingType.icon,
                            color: reading.readingType.color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${reading.pumpName} - ${reading.readingType.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reading: ${reading.formattedReading} L',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (reading.calculatedDispensed != null)
                              Text(
                                'Dispensed: ${reading.formattedDispensed} L',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _MeterReadingConstants.accentGreen,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          DateFormat('HH:mm, dd MMM').format(reading.timestamp),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}