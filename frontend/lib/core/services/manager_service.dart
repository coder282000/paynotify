// lib/core/services/manager_service.dart
//
// NOTE: The manager-specific endpoints (dashboard, alerts, analytics,
// employees, customers) do not yet exist in the backend.
// This service provides the correct structure so ManagerProvider
// works now (returning safe empty data) and is ready to plug in
// real endpoints as you build them in Phase 3+.
//
// Each method is clearly marked with the endpoint it will call.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ManagerService {
  // ─────────────────────────────────────────────
  // MANAGER DASHBOARD
  // ─────────────────────────────────────────────

  /// TODO: GET /api/manager/dashboard
  /// Will return: today_sales, sales_change, transaction_count,
  ///   transaction_change, active_pumps, total_pumps,
  ///   active_attendants, total_attendants
  static Future<Map<String, dynamic>?> getManagerDashboard() async {
    try {
      // Use the transactions summary endpoint which already exists
      final response = await ApiService.get('/transactions/summary');

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final overview = data['overview'] as Map<String, dynamic>? ?? {};
        final byType = data['byPaymentType'] as Map<String, dynamic>? ?? {};

        return {
          'today_sales': (byType['cash'] ?? 0) +
              (byType['card'] ?? 0) +
              (byType['mpesa'] ?? 0),
          'sales_change': 0.0,
          'transaction_count': overview['totalTransactions'] ?? 0,
          'transaction_change': 0.0,
          'active_pumps': 0,
          'total_pumps': 0,
          'active_attendants': 0,
          'total_attendants': 0,
        };
      }
    } catch (e) {
      debugPrint('getManagerDashboard error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // ALERTS
  // ─────────────────────────────────────────────

  /// TODO: GET /api/manager/alerts
  /// Will return: { alerts: [...], pending_reports: N }
  static Future<Map<String, dynamic>?> getAlerts() async {
    // Endpoint not yet built — return safe empty data
    debugPrint('getAlerts: endpoint not yet available');
    return {
      'alerts': <String>[],
      'pending_reports': 0,
    };
  }

  // ─────────────────────────────────────────────
  // SALES ANALYTICS
  // ─────────────────────────────────────────────

  /// TODO: GET /api/manager/analytics/sales
  /// Will return: { daily_sales: [double, ...] } — 7 days
  static Future<Map<String, dynamic>?> getSalesAnalytics() async {
    try {
      // Use existing summary endpoint as a proxy
      final response = await ApiService.get('/transactions/summary');

      if (response['success'] == true) {
        // Return placeholder chart data until dedicated endpoint exists
        return {
          'daily_sales': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        };
      }
    } catch (e) {
      debugPrint('getSalesAnalytics error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // EMPLOYEES
  // ─────────────────────────────────────────────

  /// TODO: GET /api/manager/employees
  /// Will return list of employee objects
  static Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await ApiService.get('/employees');

      if (response['success'] == true) {
        final raw = response['data'] ?? response['employees'] ?? [];
        return List<Map<String, dynamic>>.from(raw);
      }
    } catch (e) {
      debugPrint('getEmployees: endpoint not yet available ($e)');
    }
    return [];
  }

  /// TODO: POST /api/manager/employees
  static Future<Map<String, dynamic>?> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final response = await ApiService.post('/employees', employeeData);

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('createEmployee error: ${response['message']}');
    } catch (e) {
      debugPrint('createEmployee exception: $e');
    }
    return null;
  }

  /// TODO: PUT /api/manager/employees/:id
  static Future<bool> updateEmployee(
    int employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/employees/$employeeId', data);
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateEmployee exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // CUSTOMERS
  // ─────────────────────────────────────────────

  /// TODO: GET /api/manager/customers
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await ApiService.get('/customers');

      if (response['success'] == true) {
        final raw = response['data'] ?? response['customers'] ?? [];
        return List<Map<String, dynamic>>.from(raw);
      }
    } catch (e) {
      debugPrint('getCustomers: endpoint not yet available ($e)');
    }
    return [];
  }

  /// TODO: PUT /api/manager/customers/:id/points
  static Future<bool> updateCustomerPoints(
    int customerId,
    int points,
  ) async {
    try {
      final response = await ApiService.put(
        '/customers/$customerId/points',
        {'points': points},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateCustomerPoints exception: $e');
      return false;
    }
  }
}