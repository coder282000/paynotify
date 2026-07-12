// lib/core/services/employee_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class EmployeeService {
  // ─────────────────────────────────────────────
  // GET EMPLOYEES
  // ─────────────────────────────────────────────

  /// GET /api/employees
  /// Role-based: Owner sees all, Manager sees their station only
  static Future<Map<String, dynamic>> getEmployees({
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
      final response = await ApiService.get('/employees$query');

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

  static Future<Map<String, dynamic>> getEmployeeById(int id) async {
    try {
      final response = await ApiService.get('/employees/$id');
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
  static Future<Map<String, dynamic>> inviteEmployee(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.post('/employees/invite', data);
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
  static Future<Map<String, dynamic>> approveEmployee(
    int userId,
    bool approved, {
    String? notes,
  }) async {
    try {
      final response = await ApiService.put(
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
  static Future<Map<String, dynamic>> resendInvitation(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.post('/employees/resend', data);
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
  static Future<Map<String, dynamic>> getPendingRegistrations() async {
    try {
      final response = await ApiService.get('/employees/pending');
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
  static Future<Map<String, dynamic>> getAllPending() async {
    try {
      final response = await ApiService.get('/employees/all-pending');
      return response;
    } catch (e) {
      debugPrint('getAllPending error: $e');
      return {'success': false, 'message': e.toString(), 'data': []};
    }
  }

  // ─────────────────────────────────────────────
  // CREATE EMPLOYEE (direct add - no invitation)
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.post('/employees', data);
      return response;
    } catch (e) {
      debugPrint('createEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE EMPLOYEE
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/employees/$id', data);
      return response;
    } catch (e) {
      debugPrint('updateEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // DEACTIVATE EMPLOYEE
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await ApiService.delete('/employees/$id');
      return response;
    } catch (e) {
      debugPrint('deleteEmployee error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // GET EMPLOYEE STATS
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final response = await ApiService.get('/employees/stats');
      return response;
    } catch (e) {
      debugPrint('getEmployeeStats error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}