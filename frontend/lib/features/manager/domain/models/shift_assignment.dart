import 'shift_model.dart';
import 'package:flutter/material.dart'; 
enum ShiftAssignmentStatus {
  scheduled,
  active,
  completed,
  absent,
  cancelled;

  String get displayName {
    switch (this) {
      case ShiftAssignmentStatus.scheduled:
        return 'Scheduled';
      case ShiftAssignmentStatus.active:
        return 'Active';
      case ShiftAssignmentStatus.completed:
        return 'Completed';
      case ShiftAssignmentStatus.absent:
        return 'Absent';
      case ShiftAssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ShiftAssignmentStatus.scheduled:
        return Colors.blue;
      case ShiftAssignmentStatus.active:
        return Colors.green;
      case ShiftAssignmentStatus.completed:
        return Colors.grey;
      case ShiftAssignmentStatus.absent:
        return Colors.red;
      case ShiftAssignmentStatus.cancelled:
        return Colors.orange;
    }
  }
}

class ShiftAssignment {
  final String id;
  final String attendantId;
  final String attendantName;
  final String shiftId;
  final ShiftType shiftType;
  final DateTime date;
  final ShiftAssignmentStatus status;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? notes;

  ShiftAssignment({
    required this.id,
    required this.attendantId,
    required this.attendantName,
    required this.shiftId,
    required this.shiftType,
    required this.date,
    required this.status,
    this.clockInTime,
    this.clockOutTime,
    this.notes,
  });

  bool get isActive => status == ShiftAssignmentStatus.active;
  bool get isCompleted => status == ShiftAssignmentStatus.completed;
  bool get isScheduled => status == ShiftAssignmentStatus.scheduled;

  Map<String, dynamic> toJson() => {
    'id': id,
    'attendantId': attendantId,
    'attendantName': attendantName,
    'shiftId': shiftId,
    'shiftType': shiftType.name,
    'date': date.toIso8601String(),
    'status': status.name,
    'clockInTime': clockInTime?.toIso8601String(),
    'clockOutTime': clockOutTime?.toIso8601String(),
    'notes': notes,
  };

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    return ShiftAssignment(
      id: json['id'],
      attendantId: json['attendantId'],
      attendantName: json['attendantName'],
      shiftId: json['shiftId'],
      shiftType: ShiftType.values.firstWhere((e) => e.name == json['shiftType']),
      date: DateTime.parse(json['date']),
      status: ShiftAssignmentStatus.values.firstWhere((e) => e.name == json['status']),
      clockInTime: json['clockInTime'] != null ? DateTime.parse(json['clockInTime']) : null,
      clockOutTime: json['clockOutTime'] != null ? DateTime.parse(json['clockOutTime']) : null,
      notes: json['notes'],
    );
  }
}