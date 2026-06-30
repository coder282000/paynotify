// lib/features/supervisor/domain/models/override_pump.dart

import 'package:flutter/material.dart';

enum FuelType {
  petrol('Petrol', Icons.local_gas_station, Color(0xFF2ECC71)),
  diesel('Diesel', Icons.local_gas_station, Color(0xFF3498DB)),
  kerosene('Kerosene', Icons.local_gas_station, Color(0xFFF39C12)),
  premium('Premium', Icons.local_gas_station, Color(0xFF9B59B6));

  final String displayName;
  final IconData icon;
  final Color color;

  const FuelType(this.displayName, this.icon, this.color);

  // ✅ ADD THIS - Convert to backend string format
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

  // ✅ ADD THIS - Create from backend string
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
}

enum PumpStatus {
  active('Active', Icons.play_circle, Colors.green),
  occupied('Occupied', Icons.person, Colors.orange),
  idle('Idle', Icons.pause_circle, Colors.grey),
  maintenance('Maintenance', Icons.build, Colors.red),
  emergency('Emergency', Icons.warning, Color(0xFFE74C3C));

  final String displayName;
  final IconData icon;
  final Color color;

  const PumpStatus(this.displayName, this.icon, this.color);

  // ✅ ADD THIS - Convert to backend string format
  String get backendValue {
    switch (this) {
      case PumpStatus.active:
        return 'active';
      case PumpStatus.occupied:
        return 'occupied';
      case PumpStatus.idle:
        return 'idle';
      case PumpStatus.maintenance:
        return 'maintenance';
      case PumpStatus.emergency:
        return 'emergency';
    }
  }

  // ✅ ADD THIS - Create from backend string
  static PumpStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return PumpStatus.active;
      case 'occupied':
        return PumpStatus.occupied;
      case 'idle':
        return PumpStatus.idle;
      case 'maintenance':
        return PumpStatus.maintenance;
      case 'emergency':
        return PumpStatus.emergency;
      default:
        return PumpStatus.active;
    }
  }
}

class OverridePump {
  final String id;
  final String name;
  final FuelType fuelType;
  final PumpStatus status;
  final String? attendantName;
  final double pricePerLiter;
  final double currentFuelLevel;
  final double tankCapacity;
  final double todaySales;
  final bool needsAttention;
  final String? alertMessage;

  OverridePump({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.status,
    this.attendantName,
    required this.pricePerLiter,
    required this.currentFuelLevel,
    required this.tankCapacity,
    required this.todaySales,
    this.needsAttention = false,
    this.alertMessage,
  });

  double get fuelPercentage => (currentFuelLevel / tankCapacity) * 100;
  
  String get fuelLevelStatus {
    if (fuelPercentage <= 10) return 'CRITICAL';
    if (fuelPercentage <= 25) return 'LOW';
    if (fuelPercentage <= 50) return 'MODERATE';
    return 'GOOD';
  }
  
  Color get fuelLevelColor {
    if (fuelPercentage <= 10) return const Color(0xFFE74C3C);
    if (fuelPercentage <= 25) return const Color(0xFFF39C12);
    if (fuelPercentage <= 50) return Colors.orange;
    return const Color(0xFF2ECC71);
  }

  // ✅ OPTIONAL - Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'pump_id': id,
      'pump_name': name,
      'fuel_type': fuelType.backendValue,
      'status': status.backendValue,
      'price_per_liter': pricePerLiter,
      'current_fuel_level': currentFuelLevel,
    };
  }

  // ✅ OPTIONAL - Create from backend JSON response
  factory OverridePump.fromBackendJson(Map<String, dynamic> json) {
    return OverridePump(
      id: json['id'].toString(),
      name: json['pump_number'],
      fuelType: FuelType.fromString(json['fuel_type']),
      status: PumpStatus.fromString(json['status']),
      attendantName: json['current_attendant_name'],
      pricePerLiter: (json['price_per_liter'] as num).toDouble(),
      currentFuelLevel: (json['current_fuel_level'] as num).toDouble(),
      tankCapacity: (json['tank_capacity'] as num?)?.toDouble() ?? 0,
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0,
      needsAttention: json['status'] == 'emergency' || json['status'] == 'maintenance',
      alertMessage: json['status'] == 'emergency' ? 'Emergency stop active' : null,
    );
  }
}