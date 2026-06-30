// lib/features/owner/domain/models/employee_model.dart

class OwnerEmployee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String stationId;
  final String stationName;
  final DateTime joinDate;
  final DateTime? lastActive;
  final double performanceScore;

  OwnerEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.stationId,
    required this.stationName,
    required this.joinDate,
    this.lastActive,
    required this.performanceScore,
  });

  factory OwnerEmployee.fromJson(Map<String, dynamic> json) {
    // ✅ Handle nested structure from API
    // The API returns: { id, username, fullName, role, isActive, employeeProfile: { status, joinDate }, station: { id, name } }
    
    // Get values from flat structure or nested
    final id = json['id']?.toString() ?? '';
    final username = json['username']?.toString() ?? '';
    final fullName = json['fullName']?.toString() ?? json['full_name']?.toString() ?? '';
    final name = fullName.isNotEmpty ? fullName : username;
    final email = json['email']?.toString() ?? '';
    final phone = json['phone']?.toString() ?? '';
    final role = json['role']?.toString() ?? 'attendant';
    
    // ✅ Get status from employeeProfile or flat - SAFE NULL HANDLING
    final employeeProfile = json['employeeProfile'] as Map<String, dynamic>?;
    String status;
    if (employeeProfile != null && employeeProfile['status'] != null) {
      status = employeeProfile['status'].toString();
    } else {
      status = json['isActive'] == true ? 'active' : 'inactive';
    }
    
    // ✅ Get station info - SAFE NULL HANDLING
    final station = json['station'] as Map<String, dynamic>?;
    final stationId = station?['id']?.toString() ?? 
                     json['stationId']?.toString() ?? 
                     json['station_id']?.toString() ?? '';
    final stationName = station?['name']?.toString() ?? 
                       json['stationName']?.toString() ?? 
                       json['station_name']?.toString() ?? '';
    
    // ✅ Get joinDate from employeeProfile or flat - SAFE NULL HANDLING
    DateTime joinDate;
    if (employeeProfile != null && employeeProfile['joinDate'] != null) {
      joinDate = DateTime.parse(employeeProfile['joinDate'].toString());
    } else if (json['joinDate'] != null) {
      joinDate = DateTime.parse(json['joinDate'].toString());
    } else if (json['createdAt'] != null) {
      joinDate = DateTime.parse(json['createdAt'].toString());
    } else {
      joinDate = DateTime.now();
    }
    
    // ✅ Get lastActive - SAFE NULL HANDLING
    DateTime? lastActive;
    if (json['lastLogin'] != null) {
      lastActive = DateTime.parse(json['lastLogin'].toString());
    }
    
    // ✅ Get performance score - SAFE NULL HANDLING
    double performanceScore = 0;
    if (json['performanceScore'] != null) {
      performanceScore = (json['performanceScore'] as num).toDouble();
    } else if (employeeProfile != null && employeeProfile['performanceScore'] != null) {
      performanceScore = (employeeProfile['performanceScore'] as num).toDouble();
    }

    return OwnerEmployee(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      status: status,
      stationId: stationId,
      stationName: stationName,
      joinDate: joinDate,
      lastActive: lastActive,
      performanceScore: performanceScore,
    );
  }

  // Computed properties (no Flutter UI dependencies)
  bool get isActive => status == 'active';
  bool get isManager => role == 'manager';
  bool get isSupervisor => role == 'supervisor';
  bool get isAttendant => role == 'attendant';
  
  String get roleDisplay {
    switch (role) {
      case 'manager': return 'Manager';
      case 'supervisor': return 'Supervisor';
      case 'attendant': return 'Attendant';
      default: return role;
    }
  }
  
  String get roleColorValue {
    switch (role) {
      case 'manager': return 'purple';
      case 'supervisor': return 'orange';
      case 'attendant': return 'green';
      default: return 'grey';
    }
  }
  
  String get formattedPerformanceScore => '${performanceScore.toStringAsFixed(0)}%';
}