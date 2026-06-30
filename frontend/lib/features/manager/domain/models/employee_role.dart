// lib/features/manager/domain/models/employee_role.dart

import 'package:flutter/material.dart';

enum EmployeeRole {
  attendant,
  seniorAttendant,
  supervisor,
  manager;

  String get displayName {
    switch (this) {
      case EmployeeRole.attendant:
        return 'Attendant';
      case EmployeeRole.seniorAttendant:
        return 'Senior Attendant';
      case EmployeeRole.supervisor:
        return 'Supervisor';
      case EmployeeRole.manager:
        return 'Manager';
    }
  }

  IconData get icon {
    switch (this) {
      case EmployeeRole.attendant:
        return Icons.person_outline;
      case EmployeeRole.seniorAttendant:
        return Icons.star_outline;
      case EmployeeRole.supervisor:
        return Icons.manage_accounts;
      case EmployeeRole.manager:
        return Icons.admin_panel_settings;
    }
  }

  Color get color {
    switch (this) {
      case EmployeeRole.attendant:
        return const Color(0xFF0B3D2E);
      case EmployeeRole.seniorAttendant:
        return const Color(0xFF2ECC71);
      case EmployeeRole.supervisor:
        return const Color(0xFFF39C12);
      case EmployeeRole.manager:
        return const Color(0xFFE74C3C);
    }
  }

  // ✅ ADD THIS - Convert to backend string format
  String get backendValue {
    switch (this) {
      case EmployeeRole.attendant:
        return 'attendant';
      case EmployeeRole.seniorAttendant:
        return 'senior_attendant';
      case EmployeeRole.supervisor:
        return 'supervisor';
      case EmployeeRole.manager:
        return 'manager';
    }
  }

  // ✅ ADD THIS - Create from backend string
  static EmployeeRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'attendant':
        return EmployeeRole.attendant;
      case 'senior_attendant':
        return EmployeeRole.seniorAttendant;
      case 'supervisor':
        return EmployeeRole.supervisor;
      case 'manager':
        return EmployeeRole.manager;
      default:
        return EmployeeRole.attendant;
    }
  }
}