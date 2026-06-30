// lib/features/manager/domain/models/employee_status.dart

import 'package:flutter/material.dart';

enum EmployeeStatus {
  active,
  inactive,
  suspended,
  pending;

  String get displayName {
    switch (this) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.pending:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case EmployeeStatus.active:
        return Colors.green;
      case EmployeeStatus.inactive:
        return Colors.orange;
      case EmployeeStatus.suspended:
        return Colors.red;
      case EmployeeStatus.pending:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case EmployeeStatus.active:
        return Icons.check_circle;
      case EmployeeStatus.inactive:
        return Icons.pause_circle;
      case EmployeeStatus.suspended:
        return Icons.block;
      case EmployeeStatus.pending:
        return Icons.hourglass_empty;
    }
  }

  // ✅ ADD THIS - Convert to backend string format
  String get backendValue {
    switch (this) {
      case EmployeeStatus.active:
        return 'active';
      case EmployeeStatus.inactive:
        return 'inactive';
      case EmployeeStatus.suspended:
        return 'suspended';
      case EmployeeStatus.pending:
        return 'pending';
    }
  }

  // ✅ ADD THIS - Create from backend string
  static EmployeeStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return EmployeeStatus.active;
      case 'inactive':
        return EmployeeStatus.inactive;
      case 'suspended':
        return EmployeeStatus.suspended;
      case 'pending':
        return EmployeeStatus.pending;
      default:
        return EmployeeStatus.pending;
    }
  }
}