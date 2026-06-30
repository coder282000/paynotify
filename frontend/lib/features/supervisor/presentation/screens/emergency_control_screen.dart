// lib/features/supervisor/presentation/screens/emergency_control_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/override_pump.dart';

// MARK: - Constants
class _EmergencyConstants {
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color resolvedGreen = Color(0xFF4CAF50);
}

// MARK: - Emergency Event Model
class EmergencyEvent {
  final String id;
  final String pumpId;
  final String pumpName;
  final String supervisorId;
  final String supervisorName;
  final DateTime timestamp;
  final EmergencyType type;
  final String reason;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  EmergencyEvent({
    required this.id,
    required this.pumpId,
    required this.pumpName,
    required this.supervisorId,
    required this.supervisorName,
    required this.timestamp,
    required this.type,
    required this.reason,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  String get formattedTime => DateFormat('HH:mm:ss').format(timestamp);
  String get formattedDate => DateFormat('dd MMM yyyy').format(timestamp);
  Duration get duration => isResolved && resolvedAt != null 
      ? resolvedAt!.difference(timestamp) 
      : DateTime.now().difference(timestamp);
  String get durationFormatted {
    final diff = duration;
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds.remainder(60);
    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}

enum EmergencyType {
  fuelLeak('Fuel Leak', Icons.dangerous, 'Immediate fuel leak detected', Colors.red),
  fire('Fire', Icons.local_fire_department, 'Fire hazard detected', Colors.orange),
  pumpMalfunction('Pump Malfunction', Icons.build, 'Pump not functioning correctly', _EmergencyConstants.warningOrange),
  powerFailure('Power Failure', Icons.power, 'Electrical power issue', Colors.blue),
  security('Security Issue', Icons.security, 'Security threat detected', Colors.purple),
  other('Other Emergency', Icons.warning, 'Other emergency situation', Colors.grey);

  final String displayName;
  final IconData icon;
  final String description;
  final Color color;

  const EmergencyType(this.displayName, this.icon, this.description, this.color);
}

class EmergencyControlScreen extends StatefulWidget {
  final String supervisorName;
  final String supervisorId;
  final List<OverridePump> pumps;

  const EmergencyControlScreen({
    super.key,
    required this.supervisorName,
    required this.supervisorId,
    required this.pumps,
  });

  @override
  State<EmergencyControlScreen> createState() => _EmergencyControlScreenState();
}

class _EmergencyControlScreenState extends State<EmergencyControlScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // State
  OverridePump? _selectedPump;
  EmergencyType _selectedEmergencyType = EmergencyType.pumpMalfunction;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _resolutionNotesController = TextEditingController();
  
  // Emergency status tracking - made final
  final Map<String, bool> _emergencyActive = {};
  List<EmergencyEvent> _emergencyHistory = [];
  
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Focus nodes
  final FocusNode _reasonFocus = FocusNode();
  final FocusNode _resolutionNotesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeEmergencyStatus();
    _loadEmergencyHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _resolutionNotesController.dispose();
    _reasonFocus.dispose();
    _resolutionNotesFocus.dispose();
    super.dispose();
  }

  void _initializeEmergencyStatus() {
    for (final pump in widget.pumps) {
      _emergencyActive[pump.id] = false;
    }
  }

  void _loadEmergencyHistory() {
    final now = DateTime.now();
    _emergencyHistory = [
      EmergencyEvent(
        id: '1',
        pumpId: '3',
        pumpName: 'Pump 3',
        supervisorId: widget.supervisorId,
        supervisorName: widget.supervisorName,
        timestamp: now.subtract(const Duration(hours: 2)),
        type: EmergencyType.pumpMalfunction,
        reason: 'Meter not displaying correctly',
        isResolved: true,
        resolvedAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        resolvedBy: widget.supervisorName,
        resolutionNotes: 'Restarted the pump, now working normally',
      ),
      EmergencyEvent(
        id: '2',
        pumpId: '5',
        pumpName: 'Pump 5',
        supervisorId: 'SUP002',
        supervisorName: 'Mary Gathoni',
        timestamp: now.subtract(const Duration(days: 1)),
        type: EmergencyType.powerFailure,
        reason: 'Power surge detected',
        isResolved: true,
        resolvedAt: now.subtract(const Duration(days: 1, hours: 23, minutes: 30)),
        resolvedBy: 'Mary Gathoni',
        resolutionNotes: 'Power restored after resetting breaker',
      ),
    ];
  }

  Future<void> _activateEmergency() async {
    // Validate pump selection
    if (_selectedPump == null) {
      setState(() => _errorMessage = 'Please select a pump');
      return;
    }

    // Check if emergency already active
    if (_emergencyActive[_selectedPump!.id] == true) {
      setState(() => _errorMessage = 'Emergency already active on this pump. Resolve it first.');
      return;
    }

    // Validate reason
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for emergency activation');
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showEmergencyConfirmation();
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Create emergency event
    final emergencyEvent = EmergencyEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pumpId: _selectedPump!.id,
      pumpName: _selectedPump!.name,
      supervisorId: widget.supervisorId,
      supervisorName: widget.supervisorName,
      timestamp: DateTime.now(),
      type: _selectedEmergencyType,
      reason: reason,
    );

    setState(() {
      _emergencyActive[_selectedPump!.id] = true;
      _emergencyHistory.insert(0, emergencyEvent);
      _isProcessing = false;
      _successMessage = '🚨 EMERGENCY ACTIVATED on ${_selectedPump!.name}\nMaintenance team has been alerted.';
    });

    HapticFeedback.heavyImpact();
    _simulateEmergencyAlert();

    // Reset form
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _resetForm();
      }
    });
  }

  Future<void> _resolveEmergency(OverridePump pump) async {
    _resolutionNotesController.clear();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _EmergencyConstants.resolvedGreen),
            const SizedBox(width: 8),
            Text('Resolve Emergency - ${pump.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that the emergency has been resolved:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resolutionNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes (Optional)',
                hintText: 'What was done to resolve the emergency?',
                border: OutlineInputBorder(),
              ),
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
              backgroundColor: _EmergencyConstants.resolvedGreen,
            ),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _emergencyActive[pump.id] = false;
        // Update the emergency event in history
        final index = _emergencyHistory.indexWhere((e) => e.pumpId == pump.id && !e.isResolved);
        if (index != -1) {
          _emergencyHistory[index] = EmergencyEvent(
            id: _emergencyHistory[index].id,
            pumpId: _emergencyHistory[index].pumpId,
            pumpName: _emergencyHistory[index].pumpName,
            supervisorId: _emergencyHistory[index].supervisorId,
            supervisorName: _emergencyHistory[index].supervisorName,
            timestamp: _emergencyHistory[index].timestamp,
            type: _emergencyHistory[index].type,
            reason: _emergencyHistory[index].reason,
            isResolved: true,
            resolvedAt: DateTime.now(),
            resolvedBy: widget.supervisorName,
            resolutionNotes: _resolutionNotesController.text.trim().isEmpty 
                ? null 
                : _resolutionNotesController.text.trim(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Emergency resolved on ${pump.name}'),
          backgroundColor: _EmergencyConstants.resolvedGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _emergencyStopAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _EmergencyConstants.errorRed),
            const SizedBox(width: 8),
            const Text('EMERGENCY STOP ALL PUMPS'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will immediately stop ALL pumps and alert all staff.\n\n'
              'Only use in genuine emergencies like:\n'
              '• Fire\n'
              '• Major fuel leak\n'
              '• Security threat',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Type "CONFIRM" to proceed:',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              backgroundColor: _EmergencyConstants.errorRed,
            ),
            child: const Text('EMERGENCY STOP ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        for (final pump in widget.pumps) {
          _emergencyActive[pump.id] = true;
        }
      });

      HapticFeedback.heavyImpact();
      _simulateEmergencyAlert();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 EMERGENCY STOP ACTIVATED - ALL PUMPS STOPPED 🚨'),
          backgroundColor: _EmergencyConstants.errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _simulateEmergencyAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Emergency alert sent to all staff'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('ALERT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: _EmergencyConstants.emergencyRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool?> _showEmergencyConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_selectedEmergencyType.icon, color: _selectedEmergencyType.color),
            const SizedBox(width: 8),
            Text(_selectedEmergencyType.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedEmergencyType.color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: _selectedEmergencyType.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedEmergencyType.description,
                      style: TextStyle(color: _selectedEmergencyType.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Pump', _selectedPump!.name),
            _buildConfirmationRow('Emergency Type', _selectedEmergencyType.displayName),
            _buildConfirmationRow('Reason', _reasonController.text.trim()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _EmergencyConstants.errorRed.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: _EmergencyConstants.errorRed, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ This will immediately stop the pump and alert all staff',
                      style: TextStyle(fontSize: 12, color: _EmergencyConstants.errorRed),
                    ),
                  ),
                ],
              ),
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
              backgroundColor: _EmergencyConstants.errorRed,
            ),
            child: const Text('Activate Emergency'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedPump = null;
      _reasonController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
  }

  int get _activeEmergencyCount {
    return _emergencyActive.values.where((active) => active == true).length;
  }

  @override
  Widget build(BuildContext context) {
    // Filter active pumps only (excluding maintenance)
    final activePumps = widget.pumps.where(
      (p) => p.status != PumpStatus.maintenance
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Emergency Control'),
        backgroundColor: _EmergencyConstants.emergencyRed,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Activate'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          if (_activeEmergencyCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _EmergencyConstants.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_activeEmergencyCount Active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _EmergencyConstants.errorRed,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Activate Emergency Tab
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Stop All Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: _emergencyStopAll,
                      icon: const Icon(Icons.power_settings_new, size: 28),
                      label: const Text(
                        'EMERGENCY STOP - ALL PUMPS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EmergencyConstants.errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Warning Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: _EmergencyConstants.warningOrange.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _EmergencyConstants.warningOrange.withAlpha(77),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _EmergencyConstants.warningOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Emergency stop will immediately halt pump operations and notify all staff. Use only for genuine emergencies.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _EmergencyConstants.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      final bool isEmergencyActive = _emergencyActive[pump.id] == true;
                      
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEmergencyActive) ...[
                              Icon(Icons.warning, size: 14, color: _EmergencyConstants.errorRed),
                              const SizedBox(width: 4),
                            ],
                            Icon(
                              pump.fuelType.icon,
                              size: 16,
                              color: isSelected ? Colors.white : 
                                     (isEmergencyActive ? _EmergencyConstants.errorRed : pump.fuelType.color),
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
                        onSelected: isEmergencyActive ? null : (_) {
                          setState(() {
                            _selectedPump = pump;
                            _errorMessage = null;
                          });
                          HapticFeedback.lightImpact();
                        },
                        backgroundColor: isEmergencyActive 
                            ? _EmergencyConstants.errorRed.withAlpha(26)
                            : Colors.grey.shade100,
                        selectedColor: pump.fuelType.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : 
                                 (isEmergencyActive ? _EmergencyConstants.errorRed : Colors.black),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_selectedPump != null && _emergencyActive[_selectedPump!.id] == true) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _EmergencyConstants.errorRed.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _EmergencyConstants.errorRed, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: _EmergencyConstants.errorRed),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EMERGENCY ACTIVE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _EmergencyConstants.errorRed,
                                  ),
                                ),
                                Text(
                                  'This pump is currently in emergency state',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _EmergencyConstants.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _resolveEmergency(_selectedPump!),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Resolve'),
                            style: TextButton.styleFrom(
                              foregroundColor: _EmergencyConstants.resolvedGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Emergency Type Selection
                  const Text(
                    'Emergency Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EmergencyType.values.map((type) {
                      final bool isSelected = _selectedEmergencyType == type;
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedEmergencyType = type;
                          });
                          HapticFeedback.lightImpact();
                        },
                        avatar: Icon(
                          type.icon,
                          size: 16,
                          color: isSelected ? Colors.white : type.color,
                        ),
                        selectedColor: type.color,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Reason
                  TextFormField(
                    controller: _reasonController,
                    focusNode: _reasonFocus,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason for Emergency *',
                      hintText: 'Describe the emergency situation in detail...',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: const OutlineInputBorder(),
                      helperText: 'This will be logged for audit purposes',
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

                  // Activate Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _activateEmergency,
                      icon: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.warning, size: 24),
                      label: _isProcessing
                          ? const Text('ACTIVATING...')
                          : const Text('ACTIVATE EMERGENCY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _EmergencyConstants.errorRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History Tab
          SafeArea(
            child: _emergencyHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 72, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No emergency history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _emergencyHistory.length,
                    itemBuilder: (context, index) {
                      final event = _emergencyHistory[index];
                      return _buildEmergencyHistoryCard(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyHistoryCard(EmergencyEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !event.isResolved
            ? BorderSide(color: _EmergencyConstants.errorRed, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: event.type.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    event.type.icon,
                    color: event.type.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.pumpName} - ${event.type.displayName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isResolved 
                        ? _EmergencyConstants.resolvedGreen.withAlpha(26)
                        : _EmergencyConstants.errorRed.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.isResolved ? 'RESOLVED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: event.isResolved 
                          ? _EmergencyConstants.resolvedGreen
                          : _EmergencyConstants.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${event.reason}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (event.resolutionNotes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Resolution: ${event.resolutionNotes}',
                style: TextStyle(fontSize: 12, color: _EmergencyConstants.resolvedGreen),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'By: ${event.supervisorName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  event.formattedTime,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                if (event.isResolved && event.resolvedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 14, color: _EmergencyConstants.resolvedGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Resolved after ${event.durationFormatted}',
                    style: TextStyle(fontSize: 11, color: _EmergencyConstants.resolvedGreen),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}