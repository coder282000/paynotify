// lib/features/manager/domain/models/employee_leave.dart

import 'package:flutter/material.dart';

enum LeaveType {
  annual,
  sick,
  emergency,
  unpaid,
  maternity,
  paternity;

  String get displayName {
    switch (this) {
      case LeaveType.annual:
        return 'Annual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.emergency:
        return 'Emergency Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
    }
  }

  Color get color {
    switch (this) {
      case LeaveType.annual:
        return Colors.blue;
      case LeaveType.sick:
        return Colors.orange;
      case LeaveType.emergency:
        return Colors.red;
      case LeaveType.unpaid:
        return Colors.grey;
      case LeaveType.maternity:
        return Colors.pink;
      case LeaveType.paternity:
        return Colors.purple;
    }
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }
}

class EmployeeLeave {
  final String id;
  final String attendantId;
  final String attendantName;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  LeaveStatus status;  // Changed from final to non-final
  final String? reason;
  String? approvedBy;  // Changed from final to non-final
  DateTime? approvedAt;  // Changed from final to non-final
  final DateTime createdAt;

  EmployeeLeave({
    required this.id,
    required this.attendantId,
    required this.attendantName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && status == LeaveStatus.approved;
  }

  bool get isPending => status == LeaveStatus.pending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'attendantId': attendantId,
    'attendantName': attendantName,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status.name,
    'reason': reason,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory EmployeeLeave.fromJson(Map<String, dynamic> json) {
    return EmployeeLeave(
      id: json['id'],
      attendantId: json['attendantId'],
      attendantName: json['attendantName'],
      type: LeaveType.values.firstWhere((e) => e.name == json['type']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: LeaveStatus.values.firstWhere((e) => e.name == json['status']),
      reason: json['reason'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class EmployeeOffDays {
  final String attendantId;
  final String attendantName;
  List<int> weeklyOffDays;  // Changed from final to non-final
  final Map<DateTime, String> customOffDays;

  EmployeeOffDays({
    required this.attendantId,
    required this.attendantName,
    this.weeklyOffDays = const [],
    this.customOffDays = const {},
  });

  bool isOffDay(DateTime date) {
    final weekday = date.weekday;
    if (weeklyOffDays.contains(weekday)) return true;
    
    final dateKey = DateTime(date.year, date.month, date.day);
    return customOffDays.containsKey(dateKey);
  }

  String? getOffDayReason(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return customOffDays[dateKey];
  }

  Map<String, dynamic> toJson() => {
    'attendantId': attendantId,
    'attendantName': attendantName,
    'weeklyOffDays': weeklyOffDays,
    'customOffDays': customOffDays.map((k, v) => MapEntry(k.toIso8601String(), v)),
  };

  factory EmployeeOffDays.fromJson(Map<String, dynamic> json) {
    return EmployeeOffDays(
      attendantId: json['attendantId'],
      attendantName: json['attendantName'],
      weeklyOffDays: List<int>.from(json['weeklyOffDays']),
      customOffDays: (json['customOffDays'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(DateTime.parse(k), v as String),
      ),
    );
  }
}