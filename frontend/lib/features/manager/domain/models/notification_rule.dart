import 'package:flutter/material.dart';

enum NotificationType {
  lowFuel,
  highExpense,
  paymentFailure,
  employeeClockIn,
  employeeClockOut,
  shiftReminder,
  lowStock,
  systemUpdate;

  String get displayName {
    switch (this) {
      case NotificationType.lowFuel:
        return 'Low Fuel Alert';
      case NotificationType.highExpense:
        return 'High Expense Alert';
      case NotificationType.paymentFailure:
        return 'Payment Failure';
      case NotificationType.employeeClockIn:
        return 'Employee Clock In';
      case NotificationType.employeeClockOut:
        return 'Employee Clock Out';
      case NotificationType.shiftReminder:
        return 'Shift Reminder';
      case NotificationType.lowStock:
        return 'Low Stock Alert';
      case NotificationType.systemUpdate:
        return 'System Update';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.lowFuel:
        return Icons.local_gas_station;
      case NotificationType.highExpense:
        return Icons.money_off;
      case NotificationType.paymentFailure:
        return Icons.payment;
      case NotificationType.employeeClockIn:
        return Icons.login;
      case NotificationType.employeeClockOut:
        return Icons.logout;
      case NotificationType.shiftReminder:
        return Icons.access_time;
      case NotificationType.lowStock:
        return Icons.inventory;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.lowFuel:
        return Colors.orange;
      case NotificationType.highExpense:
        return Colors.red;
      case NotificationType.paymentFailure:
        return Colors.red;
      case NotificationType.employeeClockIn:
        return Colors.green;
      case NotificationType.employeeClockOut:
        return Colors.orange;
      case NotificationType.shiftReminder:
        return Colors.blue;
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.systemUpdate:
        return Colors.purple;
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }
}

enum NotificationChannel {
  inApp,
  sms,
  email;

  String get displayName {
    switch (this) {
      case NotificationChannel.inApp:
        return 'In-App';
      case NotificationChannel.sms:
        return 'SMS';
      case NotificationChannel.email:
        return 'Email';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationChannel.inApp:
        return Icons.notifications;
      case NotificationChannel.sms:
        return Icons.message;
      case NotificationChannel.email:
        return Icons.email;
    }
  }
}

class NotificationRule {
  final String id;
  final NotificationType type;
  bool isEnabled; // Changed from final to non-final
  final List<NotificationChannel> channels;
  final List<String> recipientRoles;
  final double? thresholdValue;
  final bool sendToAllAttendants;
  final NotificationPriority priority;

  NotificationRule({
    required this.id,
    required this.type,
    required this.isEnabled,
    required this.channels,
    required this.recipientRoles,
    this.thresholdValue,
    this.sendToAllAttendants = false,
    this.priority = NotificationPriority.normal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'isEnabled': isEnabled,
    'channels': channels.map((c) => c.name).toList(),
    'recipientRoles': recipientRoles,
    'thresholdValue': thresholdValue,
    'sendToAllAttendants': sendToAllAttendants,
    'priority': priority.name,
  };

  factory NotificationRule.fromJson(Map<String, dynamic> json) {
    return NotificationRule(
      id: json['id'],
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      isEnabled: json['isEnabled'],
      channels: (json['channels'] as List)
          .map((c) => NotificationChannel.values.firstWhere((e) => e.name == c))
          .toList(),
      recipientRoles: List<String>.from(json['recipientRoles']),
      thresholdValue: json['thresholdValue'],
      sendToAllAttendants: json['sendToAllAttendants'],
      priority: NotificationPriority.values.firstWhere((e) => e.name == json['priority']),
    );
  }
}