// lib/features/owner/domain/models/station_activity_model.dart

class StationActivity {
  final String id;
  final int stationId;
  final String stationName;
  final String activityType; // sale, shift_start, shift_end, low_fuel, maintenance
  final String description;
  final double? amount;
  final String? attendantName;
  final String? paymentType;
  final DateTime timestamp;
  final bool isRead;

  StationActivity({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.activityType,
    required this.description,
    this.amount,
    this.attendantName,
    this.paymentType,
    required this.timestamp,
    this.isRead = false,
  });

  factory StationActivity.fromJson(Map<String, dynamic> json) {
    return StationActivity(
      id: json['id'].toString(),
      stationId: json['station_id'],
      stationName: json['station_name'],
      activityType: json['activity_type'],
      description: json['description'],
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      attendantName: json['attendant_name'],
      paymentType: json['payment_type'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'station_name': stationName,
      'activity_type': activityType,
      'description': description,
      'amount': amount,
      'attendant_name': attendantName,
      'payment_type': paymentType,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  // Helper properties
  String get activityIconName {
    switch (activityType) {
      case 'sale':
        return 'money';
      case 'shift_start':
        return 'play_arrow';
      case 'shift_end':
        return 'stop';
      case 'low_fuel':
        return 'warning';
      case 'maintenance':
        return 'build';
      default:
        return 'notifications';
    }
  }

  String get activityColorName {
    switch (activityType) {
      case 'sale':
        return 'green';
      case 'shift_start':
        return 'blue';
      case 'shift_end':
        return 'orange';
      case 'low_fuel':
        return 'red';
      case 'maintenance':
        return 'purple';
      default:
        return 'grey';
    }
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedAmount {
    if (amount == null) return '';
    return 'KES ${amount!.toStringAsFixed(2)}';
  }
}