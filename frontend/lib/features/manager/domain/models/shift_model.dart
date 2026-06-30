// lib/features/manager/domain/models/shift_model.dart

import 'package:flutter/material.dart';

enum ShiftType {
  morning,
  evening,
  night;

  String get displayName {
    switch (this) {
      case ShiftType.morning:
        return 'Morning Shift';
      case ShiftType.evening:
        return 'Evening Shift';
      case ShiftType.night:
        return 'Night Shift';
    }
  }

  Color get color {
    switch (this) {
      case ShiftType.morning:
        return Colors.orange;
      case ShiftType.evening:
        return Colors.blue;
      case ShiftType.night:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case ShiftType.morning:
        return Icons.wb_sunny;
      case ShiftType.evening:
        return Icons.nightlight_round;
      case ShiftType.night:
        return Icons.bedtime;
    }
  }
}

enum DayType {
  working,
  off,
  leave,
  holiday;

  String get displayName {
    switch (this) {
      case DayType.working:
        return 'Working Day';
      case DayType.off:
        return 'Off Day';
      case DayType.leave:
        return 'Leave Day';
      case DayType.holiday:
        return 'Holiday';
    }
  }

  Color get color {
    switch (this) {
      case DayType.working:
        return Colors.green;
      case DayType.off:
        return Colors.orange;
      case DayType.leave:
        return Colors.blue;
      case DayType.holiday:
        return Colors.red;
    }
  }
}

class Shift {
  final String id;
  final ShiftType type;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double overtimeRate;
  bool isActive;  // Changed from final to non-final

  Shift({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.overtimeRate = 1.5,
    this.isActive = true,
  });

  String get formattedTime {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String get duration {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final diff = endMinutes - startMinutes;
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
    'overtimeRate': overtimeRate,
    'isActive': isActive,
  };

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      type: ShiftType.values.firstWhere((e) => e.name == json['type']),
      startTime: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
      endTime: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      overtimeRate: json['overtimeRate'],
      isActive: json['isActive'],
    );
  }
}