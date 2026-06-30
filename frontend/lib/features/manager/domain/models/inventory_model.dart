// lib/features/manager/domain/models/inventory_model.dart

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
}

enum StockStatus {
  critical('Critical', Colors.red, Icons.warning),
  low('Low', Colors.orange, Icons.priority_high),
  moderate('Moderate', Colors.amber, Icons.info),
  good('Good', Colors.green, Icons.check_circle);

  final String displayName;
  final Color color;
  final IconData icon;
  const StockStatus(this.displayName, this.color, this.icon);
}

class FuelTank {
  final String id;
  final String name;
  final FuelType fuelType;
  final double capacity;
  double currentLevel;
  final double minThreshold;
  final double maxCapacity;
  final String? supplier;
  final DateTime? lastDeliveryDate;
  double? lastDeliveryAmount;
  final List<DeliveryRecord> deliveryHistory;
  final List<ConsumptionRecord> consumptionHistory;

  FuelTank({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.capacity,
    required this.currentLevel,
    required this.minThreshold,
    required this.maxCapacity,
    this.supplier,
    this.lastDeliveryDate,
    this.lastDeliveryAmount,
    this.deliveryHistory = const [],
    this.consumptionHistory = const [],
  });

  // Computed properties
  double get levelPercentage => (currentLevel / capacity) * 100;
  
  StockStatus get stockStatus {
    if (levelPercentage <= 5) return StockStatus.critical;
    if (levelPercentage <= 15) return StockStatus.low;
    if (levelPercentage <= 30) return StockStatus.moderate;
    return StockStatus.good;
  }
  
  bool get needsReorder => levelPercentage <= minThreshold;
  
  double get estimatedDaysRemaining {
    if (consumptionHistory.isEmpty) return 7;
    final avgDaily = _calculateAverageDailyConsumption();
    if (avgDaily <= 0) return 7;
    return currentLevel / avgDaily;
  }

  double _calculateAverageDailyConsumption() {
    if (consumptionHistory.length < 2) return 0;
    
    final sorted = List<ConsumptionRecord>.from(consumptionHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final total = sorted.fold<double>(0, (sum, record) => sum + record.amount);
    final days = sorted.last.date.difference(sorted.first.date).inDays;
    
    return days > 0 ? total / days : 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fuelType': fuelType.name,
    'capacity': capacity,
    'currentLevel': currentLevel,
    'minThreshold': minThreshold,
    'maxCapacity': maxCapacity,
    'supplier': supplier,
    'lastDeliveryDate': lastDeliveryDate?.toIso8601String(),
    'lastDeliveryAmount': lastDeliveryAmount,
  };
}

class DeliveryRecord {
  final String id;
  final DateTime date;
  final double amount;
  final double pricePerLiter;
  final double totalCost;
  final String? supplier;
  final String? invoiceNumber;
  final String? deliveredBy;

  DeliveryRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.pricePerLiter,
    required this.totalCost,
    this.supplier,
    this.invoiceNumber,
    this.deliveredBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'pricePerLiter': pricePerLiter,
    'totalCost': totalCost,
    'supplier': supplier,
    'invoiceNumber': invoiceNumber,
    'deliveredBy': deliveredBy,
  };
}

class ConsumptionRecord {
  final DateTime date;
  final double amount;
  final String? pumpId;
  final String? attendantId;

  ConsumptionRecord({
    required this.date,
    required this.amount,
    this.pumpId,
    this.attendantId,
  });
}

class InventorySummary {
  final double totalCapacity;
  final double totalCurrentLevel;
  final double totalValue;
  final int tanksCritical;
  final int tanksLow;
  final int tanksModerate;
  final int tanksGood;
  final double dailyConsumption;
  final double weeklyConsumption;
  final double monthlyConsumption;

  InventorySummary({
    required this.totalCapacity,
    required this.totalCurrentLevel,
    required this.totalValue,
    required this.tanksCritical,
    required this.tanksLow,
    required this.tanksModerate,
    required this.tanksGood,
    required this.dailyConsumption,
    required this.weeklyConsumption,
    required this.monthlyConsumption,
  });

  double get overallPercentage => totalCapacity > 0 
      ? (totalCurrentLevel / totalCapacity * 100) 
      : 0;
}