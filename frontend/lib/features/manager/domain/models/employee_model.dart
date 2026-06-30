// lib/features/manager/domain/models/employee_model.dart

import 'employee_role.dart';
import 'employee_status.dart';

class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final EmployeeRole role;
  EmployeeStatus status;
  final String? assignedPumpId;
  final String? assignedPumpName;
  final DateTime joinDate;
  DateTime? lastActive;
  final String? invitationToken;
  DateTime? invitationExpiry;
  Map<String, dynamic>? performance;
  List<String>? shiftHistory;
  final String? notes;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.assignedPumpId,
    this.assignedPumpName,
    required this.joinDate,
    this.lastActive,
    this.invitationToken,
    this.invitationExpiry,
    this.performance,
    this.shiftHistory,
    this.notes,
  });

  // Computed properties
  bool get isActive => status == EmployeeStatus.active;
  bool get isPending => status == EmployeeStatus.pending;
  bool get hasInvitationExpired => 
      invitationExpiry != null && invitationExpiry!.isBefore(DateTime.now());
  
  bool get isManager => role == EmployeeRole.manager;
  bool get isSupervisor => role == EmployeeRole.supervisor;
  bool get isAttendant => role == EmployeeRole.attendant;
  bool get isSeniorAttendant => role == EmployeeRole.seniorAttendant;

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'full_name': name,
    'email': email,
    'phone': phone,
    'role': role.backendValue,
    'assigned_pump_id': assignedPumpId,
  };
  
  // Create from backend JSON response
  factory Employee.fromBackendJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      name: json['full_name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: EmployeeRole.fromString(json['role']),
      status: json['is_active'] == true 
          ? EmployeeStatus.active 
          : EmployeeStatus.inactive,
      assignedPumpId: json['assigned_pump_id']?.toString(),
      assignedPumpName: json['assigned_pump_name'],
      joinDate: DateTime.parse(json['created_at']),
      lastActive: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      notes: json['notes'],
    );
  }
}