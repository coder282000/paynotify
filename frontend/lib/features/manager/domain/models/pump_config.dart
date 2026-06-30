// lib/features/manager/domain/models/pump_config.dart

import 'package:flutter/material.dart';

enum FuelType {
  petrol('Petrol', Icons.local_gas_station, Color(0xFF0B3D2E)),
  diesel('Diesel', Icons.local_gas_station_outlined, Color(0xFF2ECC71)),
  kerosene('Kerosene', Icons.oil_barrel, Color(0xFFF39C12)),
  premium('Premium', Icons.star, Color(0xFF9B59B6));

  final String displayName;
  final IconData icon;
  final Color color;
  const FuelType(this.displayName, this.icon, this.color);
  
  // Convert string from backend to enum
  static FuelType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'petrol':
        return FuelType.petrol;
      case 'diesel':
        return FuelType.diesel;
      case 'kerosene':
        return FuelType.kerosene;
      case 'premium':
        return FuelType.premium;
      default:
        return FuelType.petrol;
    }
  }
  
  String get backendValue {
    switch (this) {
      case FuelType.petrol:
        return 'petrol';
      case FuelType.diesel:
        return 'diesel';
      case FuelType.kerosene:
        return 'kerosene';
      case FuelType.premium:
        return 'premium';
    }
  }
}

enum PumpStatus {
  active('Active', Icons.play_circle, Colors.green),
  inactive('Inactive', Icons.pause_circle, Colors.orange),
  maintenance('Maintenance', Icons.build_circle, Colors.red),
  offline('Offline', Icons.remove_circle, Colors.grey);

  final String displayName;
  final IconData icon;
  final Color color;
  const PumpStatus(this.displayName, this.icon, this.color);
  
  static PumpStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return PumpStatus.active;
      case 'inactive':
        return PumpStatus.inactive;
      case 'maintenance':
        return PumpStatus.maintenance;
      case 'offline':
        return PumpStatus.offline;
      default:
        return PumpStatus.active;
    }
  }
  
  String get backendValue {
    switch (this) {
      case PumpStatus.active:
        return 'active';
      case PumpStatus.inactive:
        return 'inactive';
      case PumpStatus.maintenance:
        return 'maintenance';
      case PumpStatus.offline:
        return 'offline';
    }
  }
}

class PumpPriceHistory {
  final DateTime date;
  final double oldPrice;
  final double newPrice;
  final String changedBy;

  PumpPriceHistory({
    required this.date,
    required this.oldPrice,
    required this.newPrice,
    required this.changedBy,
  });

  double get change => newPrice - oldPrice;
  double get changePercentage => ((newPrice - oldPrice) / oldPrice) * 100;
  
  factory PumpPriceHistory.fromBackendJson(Map<String, dynamic> json) {
    return PumpPriceHistory(
      date: DateTime.parse(json['date']),
      oldPrice: (json['old_price'] as num).toDouble(),
      newPrice: (json['new_price'] as num).toDouble(),
      changedBy: json['changed_by'],
    );
  }
}

class PumpMaintenanceRecord {
  final DateTime date;
  final String description;
  final String technician;
  final double cost;
  final DateTime? nextDueDate;

  PumpMaintenanceRecord({
    required this.date,
    required this.description,
    required this.technician,
    required this.cost,
    this.nextDueDate,
  });
  
  factory PumpMaintenanceRecord.fromBackendJson(Map<String, dynamic> json) {
    return PumpMaintenanceRecord(
      date: DateTime.parse(json['date']),
      description: json['description'],
      technician: json['technician'],
      cost: (json['cost'] as num).toDouble(),
      nextDueDate: json['next_due_date'] != null 
          ? DateTime.parse(json['next_due_date']) 
          : null,
    );
  }
}

class PumpConfig {
  final String id;
  final String number;
  final FuelType fuelType;
  PumpStatus status;
  String? currentAttendantId;
  String? currentAttendantName;
  double pricePerLiter;
  double currentReading;
  double? previousReading;
  DateTime? lastReadingDate;
  double tankCapacity;
  double currentFuelLevel;
  double lowFuelThreshold;
  bool isActive;
  List<PumpPriceHistory> priceHistory;
  List<PumpMaintenanceRecord> maintenanceHistory;

  PumpConfig({
    required this.id,
    required this.number,
    required this.fuelType,
    required this.status,
    this.currentAttendantId,
    this.currentAttendantName,
    required this.pricePerLiter,
    required this.currentReading,
    this.previousReading,
    this.lastReadingDate,
    required this.tankCapacity,
    required this.currentFuelLevel,
    this.lowFuelThreshold = 15.0,
    required this.isActive,
    List<PumpPriceHistory>? priceHistory,
    List<PumpMaintenanceRecord>? maintenanceHistory,
  }) : priceHistory = priceHistory ?? [],
       maintenanceHistory = maintenanceHistory ?? [];

  // Computed properties
  double get fuelUsedToday => previousReading != null 
      ? currentReading - previousReading! 
      : 0.0;
  
  double get fuelPercentage => tankCapacity > 0 ? (currentFuelLevel / tankCapacity) * 100 : 0;
  
  bool get needsMaintenance => fuelPercentage < lowFuelThreshold;
  
  String get fuelLevelStatus {
    if (fuelPercentage <= 5) return 'Critical';
    if (fuelPercentage <= 15) return 'Low';
    if (fuelPercentage <= 30) return 'Moderate';
    return 'Good';
  }
  
  Color get fuelLevelColor {
    if (fuelPercentage <= 5) return Colors.red;
    if (fuelPercentage <= 15) return Colors.orange;
    if (fuelPercentage <= 30) return Colors.yellow.shade700;
    return Colors.green;
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'pump_number': number,
    'fuel_type': fuelType.backendValue,
    'price_per_liter': pricePerLiter,
    'tank_capacity': tankCapacity,
    'status': status.backendValue,
  };
  
  // Create from backend JSON response
  factory PumpConfig.fromBackendJson(Map<String, dynamic> json) {
    return PumpConfig(
      id: json['id'].toString(),
      number: json['pump_number'],
      fuelType: FuelType.fromString(json['fuel_type']),
      status: PumpStatus.fromString(json['status']),
      pricePerLiter: (json['price_per_liter'] as num).toDouble(),
      currentReading: (json['current_reading'] as num?)?.toDouble() ?? 0,
      tankCapacity: (json['tank_capacity'] as num?)?.toDouble() ?? 0,
      currentFuelLevel: (json['current_fuel_level'] as num?)?.toDouble() ?? 0,
      lowFuelThreshold: (json['low_fuel_threshold'] as num?)?.toDouble() ?? 15,
      isActive: json['is_active'] ?? true,
      currentAttendantId: json['current_attendant_id']?.toString(),
    );
  }
}

// Simple pump status for dashboard display
class PumpStatusSimple {
  final String id;
  final String number;
  final String status;
  final String? attendantName;
  final String fuelType;
  final double todaySales;
  final double lastReading;
  final bool isActive;

  PumpStatusSimple({
    required this.id,
    required this.number,
    required this.status,
    this.attendantName,
    required this.fuelType,
    required this.todaySales,
    required this.lastReading,
    required this.isActive,
  });
  
  factory PumpStatusSimple.fromBackendJson(Map<String, dynamic> json) {
    return PumpStatusSimple(
      id: json['id'].toString(),
      number: json['pump_number'],
      status: json['status'],
      attendantName: json['current_attendant_name'],
      fuelType: json['fuel_type'],
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0,
      lastReading: (json['current_reading'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}