// lib/features/owner/domain/models/fuel_inventory_model.dart

class FuelInventory {
  final String id;
  final String stationId;
  final String stationName;
  final String fuelType;
  final double currentLevel;
  final double capacity;
  final double minThreshold;

  FuelInventory({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.fuelType,
    required this.currentLevel,
    required this.capacity,
    required this.minThreshold,
  });

  factory FuelInventory.fromJson(Map<String, dynamic> json) {
    return FuelInventory(
      id: json['id'].toString(),
      stationId: json['station_id'].toString(),
      stationName: json['station_name'],
      fuelType: json['fuel_type'],
      currentLevel: (json['current_level'] as num).toDouble(),
      capacity: (json['capacity'] as num).toDouble(),
      minThreshold: (json['min_threshold'] as num).toDouble(),
    );
  }

  // Computed properties (no Flutter UI dependencies)
  double get percentage => (currentLevel / capacity) * 100;
  
  String get status {
    if (percentage <= minThreshold) return 'critical';
    if (percentage <= minThreshold + 10) return 'low';
    if (percentage <= 50) return 'moderate';
    return 'good';
  }
  
  String get statusColorValue {
    switch (status) {
      case 'critical': return 'red';
      case 'low': return 'orange';
      case 'moderate': return 'yellow';
      default: return 'green';
    }
  }
  
  String get formattedLevel => '${currentLevel.toStringAsFixed(0)}L';
  String get formattedCapacity => '${capacity.toStringAsFixed(0)}L';
  String get formattedPercentage => '${percentage.toStringAsFixed(0)}%';
}