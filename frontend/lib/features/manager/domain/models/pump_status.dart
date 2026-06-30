
class PumpStatus {
  final String id;
  final String number;
  final String status; // 'Active', 'Inactive', 'Maintenance', 'Offline'
  final String? attendantName;
  final String fuelType;
  final double todaySales;
  final double lastReading;
  final bool isActive;

  PumpStatus({
    required this.id,
    required this.number,
    required this.status,
    this.attendantName,
    required this.fuelType,
    required this.todaySales,
    required this.lastReading,
    required this.isActive,
  });
}