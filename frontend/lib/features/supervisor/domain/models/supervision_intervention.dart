// lib/features/supervisor/domain/models/supervision_intervention.dart

import 'package:flutter/material.dart';
import 'override_pump.dart';

enum InterventionType {
  sale,
  override,
  emergencyStop,
  refill,
  reading,
  shiftApproval;

  String get displayName {
    switch (this) {
      case sale:
        return 'Sale';
      case override:
        return 'Override';
      case emergencyStop:
        return 'Emergency Stop';
      case refill:
        return 'Fuel Refill';
      case reading:
        return 'Meter Reading';
      case shiftApproval:
        return 'Shift Approval';
    }
  }

  IconData get icon {
    switch (this) {
      case sale:
        return Icons.payment;
      case override:
        return Icons.lock_open;
      case emergencyStop:
        return Icons.warning;
      case refill:
        return Icons.local_gas_station;
      case reading:
        return Icons.speed;
      case shiftApproval:
        return Icons.approval;
    }
  }

  Color get color {
    switch (this) {
      case sale:
        return Colors.green;
      case override:
        return Colors.orange;
      case emergencyStop:
        return Colors.red;
      case refill:
        return Colors.blue;
      case reading:
        return Colors.purple;
      case shiftApproval:
        return Colors.teal;
    }
  }
  
  String get backendValue {
    switch (this) {
      case sale:
        return 'sale';
      case override:
        return 'override';
      case emergencyStop:
        return 'emergency_stop';
      case refill:
        return 'refill';
      case reading:
        return 'reading';
      case shiftApproval:
        return 'shift_approval';
    }
  }
  
  static InterventionType fromString(String value) {
    switch (value) {
      case 'sale':
        return InterventionType.sale;
      case 'override':
        return InterventionType.override;
      case 'emergency_stop':
        return InterventionType.emergencyStop;
      case 'refill':
        return InterventionType.refill;
      case 'reading':
        return InterventionType.reading;
      case 'shift_approval':
        return InterventionType.shiftApproval;
      default:
        return InterventionType.override;
    }
  }
}

class SupervisionIntervention {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String pumpId;
  final String pumpName;
  final InterventionType type;
  final double? amount;
  final String? customerPhone;
  final String? customerName;
  final DateTime timestamp;
  final String reason;
  final String? notes;
  final bool isSynced;
  final FuelType? fuelType;
  final PumpStatus? pumpStatus;

  const SupervisionIntervention({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.pumpId,
    required this.pumpName,
    required this.type,
    this.amount,
    this.customerPhone,
    this.customerName,
    required this.timestamp,
    required this.reason,
    this.notes,
    this.isSynced = false,
    this.fuelType,
    this.pumpStatus,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'pump_id': pumpId,
      'amount': amount,
      'reason': reason,
      'customer_name': customerName,
      'intervention_type': type.backendValue,
    };
  }

  // Create from backend JSON response
  factory SupervisionIntervention.fromBackendJson(Map<String, dynamic> json) {
    return SupervisionIntervention(
      id: json['id'].toString(),
      supervisorId: json['supervisor_id'].toString(),
      supervisorName: json['supervisor_name'],
      pumpId: json['pump_id'].toString(),
      pumpName: json['pump_name'],
      type: InterventionType.fromString(json['intervention_type']),
      amount: json['amount'] != null 
          ? (json['amount'] as num).toDouble() 
          : null,
      customerPhone: json['customer_phone'],
      customerName: json['customer_name'],
      timestamp: DateTime.parse(json['created_at']),
      reason: json['reason'],
      notes: json['notes'],
      isSynced: json['is_synced'] ?? true,
    );
  }
}