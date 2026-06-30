// lib/features/supervisor/domain/models/meter_reading.dart

import 'package:flutter/material.dart';
import 'override_pump.dart';  // Import FuelType, PumpStatus

enum ReadingType {
  opening('Opening Reading', Icons.play_arrow, Colors.green),
  closing('Closing Reading', Icons.stop, Colors.red),
  interim('Interim Reading', Icons.speed, Colors.blue),
  spot('Spot Check', Icons.remove_red_eye, Colors.orange);

  final String displayName;
  final IconData icon;
  final Color color;

  const ReadingType(this.displayName, this.icon, this.color);
}

class MeterReading {
  final String id;
  final String pumpId;
  final String pumpName;
  final double readingValue;
  final ReadingType readingType;
  final String supervisorId;
  final String supervisorName;
  final DateTime timestamp;
  final String? notes;
  final double? previousReading;
  final bool isSynced;
  final FuelType? fuelType;  // ADDED - using FuelType from override_pump
  final PumpStatus? pumpStatus;  // ADDED - using PumpStatus from override_pump

  const MeterReading({
    required this.id,
    required this.pumpId,
    required this.pumpName,
    required this.readingValue,
    required this.readingType,
    required this.supervisorId,
    required this.supervisorName,
    required this.timestamp,
    this.notes,
    this.previousReading,
    this.isSynced = false,
    this.fuelType,
    this.pumpStatus,
  });

  double get dispensedSinceLast {
    if (previousReading == null) return 0;
    return readingValue - previousReading!;
  }

  bool get isValidReading => previousReading == null || readingValue >= previousReading!;

  String get fuelTypeDisplayName => fuelType?.displayName ?? 'Unknown';
  Color get fuelTypeColor => fuelType?.color ?? Colors.grey;
  IconData get fuelTypeIcon => fuelType?.icon ?? Icons.local_gas_station;

  String get pumpStatusDisplayName => pumpStatus?.displayName ?? 'Unknown';
  Color get pumpStatusColor => pumpStatus?.color ?? Colors.grey;
  IconData get pumpStatusIcon => pumpStatus?.icon ?? Icons.help_outline;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pumpId': pumpId,
      'pumpName': pumpName,
      'readingValue': readingValue,
      'readingType': readingType.index,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'previousReading': previousReading,
      'isSynced': isSynced,
      'fuelType': fuelType?.index,
      'pumpStatus': pumpStatus?.index,
    };
  }

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    return MeterReading(
      id: json['id'],
      pumpId: json['pumpId'],
      pumpName: json['pumpName'],
      readingValue: json['readingValue'].toDouble(),
      readingType: ReadingType.values[json['readingType']],
      supervisorId: json['supervisorId'],
      supervisorName: json['supervisorName'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
      previousReading: json['previousReading']?.toDouble(),
      isSynced: json['isSynced'] ?? false,
      fuelType: json['fuelType'] != null ? FuelType.values[json['fuelType']] : null,
      pumpStatus: json['pumpStatus'] != null ? PumpStatus.values[json['pumpStatus']] : null,
    );
  }
}