// lib/features/supervisor/domain/models/fuel_refill_record.dart

import 'package:flutter/material.dart';
import 'override_pump.dart';

class FuelRefillRecord {
  final String id;
  final String tankId;
  final String tankName;
  final FuelType fuelType;
  final double litersAdded;
  final double costPerLiter;
  final double totalCost;
  final String supplierName;
  final String? invoiceNumber;
  final double meterBefore;
  final double meterAfter;
  final String supervisorId;
  final String supervisorName;
  final DateTime timestamp;
  final String? notes;
  final bool isSynced;

  const FuelRefillRecord({
    required this.id,
    required this.tankId,
    required this.tankName,
    required this.fuelType,
    required this.litersAdded,
    required this.costPerLiter,
    required this.totalCost,
    required this.supplierName,
    this.invoiceNumber,
    required this.meterBefore,
    required this.meterAfter,
    required this.supervisorId,
    required this.supervisorName,
    required this.timestamp,
    this.notes,
    this.isSynced = false,
  });

  double get fuelDifference => meterAfter - meterBefore;
  bool get isValidReading => fuelDifference >= 0;
  
  String get fuelTypeDisplayName => fuelType.displayName;
  IconData get fuelTypeIcon => fuelType.icon;
  Color get fuelTypeColor => fuelType.color;

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'tank_name': tankName,
      'fuel_type': fuelType.backendValue,
      'liters_added': litersAdded,
      'cost_per_liter': costPerLiter,
      'total_cost': totalCost,
      'supplier_name': supplierName,
      'invoice_number': invoiceNumber,
      'meter_before': meterBefore,
      'meter_after': meterAfter,
      'notes': notes,
    };
  }

  // Create from backend JSON response
  factory FuelRefillRecord.fromBackendJson(Map<String, dynamic> json) {
    return FuelRefillRecord(
      id: json['id'].toString(),
      tankId: json['tank_id']?.toString() ?? json['id'].toString(),
      tankName: json['tank_name'],
      fuelType: FuelType.fromString(json['fuel_type']),
      litersAdded: (json['liters_added'] as num).toDouble(),
      costPerLiter: (json['cost_per_liter'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
      supplierName: json['supplier_name'],
      invoiceNumber: json['invoice_number'],
      meterBefore: (json['meter_before'] as num).toDouble(),
      meterAfter: (json['meter_after'] as num).toDouble(),
      supervisorId: json['supervisor_id'].toString(),
      supervisorName: json['supervisor_name'],
      timestamp: DateTime.parse(json['delivery_date'] ?? json['created_at']),
      notes: json['notes'],
      isSynced: json['is_synced'] ?? true,
    );
  }
}