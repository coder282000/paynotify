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
  
  // Create from backend JSON response.
  //
  // Matches the shape actually returned by GET /api/employees
  // (employeeController.js -> getEmployees), which is camelCase and
  // nests the employee-record fields under `employeeProfile`:
  //
  // {
  //   "id": 6, "username": "...", "fullName": "Test Attendant",
  //   "email": "...", "phone": "...", "role": "attendant",
  //   "isActive": false, "createdAt": "...", "lastLogin": null,
  //   "employeeProfile": {
  //     "id": 3, "employeeRole": "attendant", "status": "pending",
  //     "joinDate": "...", "notes": null, "createdAt": "..."
  //   } | null,
  //   "assignedPump": { "id": 1, "number": "Pump 1" } | null,
  //   "station": { "id": 2, "name": "test station 2", "code": "..." } | null
  // }
  factory Employee.fromBackendJson(Map<String, dynamic> json) {
    final employeeProfile = json['employeeProfile'] as Map<String, dynamic>?;
    final assignedPump = json['assignedPump'] as Map<String, dynamic>?;

    // The employee-record status (active/inactive/pending/suspended) is
    // the source of truth for the Pending tab. It lives inside
    // employeeProfile.status, NOT the top-level isActive flag —
    // isActive only tells you whether the *user account* can log in,
    // which is false for both 'inactive' and 'pending' employees.
    // Fall back to isActive only if there's genuinely no employee
    // profile at all (shouldn't normally happen for
    // manager/supervisor/attendant rows).
    final EmployeeStatus resolvedStatus;
    final rawStatus = employeeProfile?['status'];
    if (rawStatus != null && rawStatus.toString().isNotEmpty) {
      resolvedStatus = EmployeeStatus.fromString(rawStatus.toString());
    } else {
      resolvedStatus = json['isActive'] == true
          ? EmployeeStatus.active
          : EmployeeStatus.inactive;
    }

    final joinDateRaw = employeeProfile?['joinDate'] ?? json['createdAt'];
    final parsedJoinDate = joinDateRaw != null
        ? (DateTime.tryParse(joinDateRaw.toString()) ?? DateTime.now())
        : DateTime.now();

    final lastLoginRaw = json['lastLogin'];
    final parsedLastActive = lastLoginRaw != null
        ? DateTime.tryParse(lastLoginRaw.toString())
        : null;

    return Employee(
      id: json['id'].toString(),
      name: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: EmployeeRole.fromString((json['role'] ?? '').toString()),
      status: resolvedStatus,
      assignedPumpId: assignedPump?['id']?.toString(),
      assignedPumpName: assignedPump?['number']?.toString(),
      joinDate: parsedJoinDate,
      lastActive: parsedLastActive,
      notes: employeeProfile?['notes']?.toString(),
    );
  }
}