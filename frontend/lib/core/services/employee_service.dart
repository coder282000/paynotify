// lib/core/services/employee_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EmployeeService {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION
  // ─────────────────────────────────────────────
  final ApiService _apiService;

  /// Constructor with optional ApiService for dependency injection
  EmployeeService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ─────────────────────────────────────────────
  // GET EMPLOYEES
  // ─────────────────────────────────────────────

  /// GET /api/employees
  /// Role-based: Owner sees all, Manager sees their station only
  Future<Map<String, dynamic>> getEmployees({
    String? role,
    String? status,
    int? stationId,
    String? search,
  }) async {
    try {
      final params = <String>[];
      if (role != null) params.add('role=$role');
      if (status != null) params.add('status=$status');
      if (stationId != null) params.add('station_id=$stationId');
      if (search != null) params.add('search=$search');

      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get('/employees$query');

      return response;
    } catch (e) {
      debugPrint('getEmployees error: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // ─────────────────────────────────────────────
  // GET EMPLOYEE BY ID
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getEmployeeById(int id) async {
    try {
      final response = await _apiService.get('/employees/$id');
      return response;
    } catch (e) {
      debugPrint('getEmployeeById error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // INVITE EMPLOYEE
  // ─────────────────────────────────────────────

  /// POST /api/employees/invite
  Future<Map<String, dynamic>> inviteEmployee(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post('/employees/invite', data);
      return response;
    } catch (e) {
      debugPrint('inviteEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // APPROVE EMPLOYEE
  // ─────────────────────────────────────────────

  /// PUT /api/employees/approve/:id
  Future<Map<String, dynamic>> approveEmployee(
    int userId,
    bool approved, {
    String? notes,
  }) async {
    try {
      final response = await _apiService.put(
        '/employees/approve/$userId',
        {
          'approved': approved,
          'notes': ?notes,
        },
      );
      return response;
    } catch (e) {
      debugPrint('approveEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // RESEND INVITATION
  // ─────────────────────────────────────────────

  /// POST /api/employees/resend
  Future<Map<String, dynamic>> resendInvitation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post('/employees/resend', data);
      return response;
    } catch (e) {
      debugPrint('resendInvitation error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // GET PENDING REGISTRATIONS (legacy — registered users only)
  // ─────────────────────────────────────────────

  /// GET /api/employees/pending
  /// Only returns users who have already completed registration and are
  /// awaiting approval. Does NOT include invitations that haven't been
  /// registered against yet. Prefer [getAllPending] for the manager
  /// "Pending" tab.
  Future<Map<String, dynamic>> getPendingRegistrations() async {
    try {
      final response = await _apiService.get('/employees/pending');
      return response;
    } catch (e) {
      debugPrint('getPendingRegistrations error: $e');
      return {'success': false, 'message': e.toString(), 'data': []};
    }
  }

  // ─────────────────────────────────────────────
  // GET ALL PENDING (invitations + registrations combined)
  // ─────────────────────────────────────────────

  /// GET /api/employees/all-pending
  /// Returns a single combined list of:
  ///   - pending invitations (sent, not yet registered), type == 'invitation'
  ///   - pending registrations (registered, awaiting approval), type == 'registration'
  /// Each item includes a `type` field so the UI can distinguish them and
  /// show the right action (resend vs approve/reject).
  Future<Map<String, dynamic>> getAllPending() async {
    try {
      final response = await _apiService.get('/employees/all-pending');
      return response;
    } catch (e) {
      debugPrint('getAllPending error: $e');
      return {'success': false, 'message': e.toString(), 'data': []};
    }
  }

  // ─────────────────────────────────────────────
  // CREATE EMPLOYEE (direct add - no invitation)
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post('/employees', data);
      return response;
    } catch (e) {
      debugPrint('createEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE EMPLOYEE
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/employees/$id', data);
      return response;
    } catch (e) {
      debugPrint('updateEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // DEACTIVATE EMPLOYEE
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await _apiService.delete('/employees/$id');
      return response;
    } catch (e) {
      debugPrint('deleteEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // GET EMPLOYEE STATS
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final response = await _apiService.get('/employees/stats');
      return response;
    } catch (e) {
      debugPrint('getEmployeeStats error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  /// Clean up resources if needed
  void dispose() {
    // If ApiService has resources to clean up, call them here
    // _apiService.dispose();
  }
}