// lib/core/services/supervisor_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SupervisorService {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION
  // ─────────────────────────────────────────────
  final ApiService _apiService;

  SupervisorService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ─────────────────────────────────────────────
  // GET ALL PUMPS
  // ─────────────────────────────────────────────

  /// GET /supervisor/pumps
  /// Returns all pumps with status for supervisor view
  Future<List<Map<String, dynamic>>> getAllPumps() async {
    try {
      final response = await _apiService.get('/supervisor/pumps');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get all pumps error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // OVERRIDE SALE
  // ─────────────────────────────────────────────

  /// POST /supervisor/sale
  /// Allows supervisor to override a sale on any pump
  Future<Map<String, dynamic>?> overrideSale({
    required int pumpId,
    required double amount,
    required String reason,
    String? customerName,
  }) async {
    try {
      final response = await _apiService.post('/supervisor/sale', {
        'pump_id': pumpId,
        'amount': amount,
        'reason': reason,
        'customer_name': customerName ?? 'Override Sale',
      });
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Override sale error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // RECORD FUEL REFILL
  // ─────────────────────────────────────────────

  /// POST /supervisor/refill
  /// Records a fuel tank refill (delivery)
  Future<Map<String, dynamic>?> recordFuelRefill({
    required String tankId,
    required double litersAdded,
    required double costPerLiter,
    required String supplierName,
    required double meterBefore,
    required double meterAfter,
    String? invoiceNumber,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/supervisor/refill', {
        'tank_id': tankId,
        'liters_added': litersAdded,
        'cost_per_liter': costPerLiter,
        'total_cost': litersAdded * costPerLiter,
        'supplier_name': supplierName,
        'meter_before': meterBefore,
        'meter_after': meterAfter,
        'invoice_number': invoiceNumber,
        'notes': notes,
      });
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Record fuel refill error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // RECORD METER READING
  // ─────────────────────────────────────────────

  /// POST /supervisor/reading
  /// Records a meter reading for a pump
  /// readingType: opening, closing, interim, spot
  Future<Map<String, dynamic>?> recordMeterReading({
    required int pumpId,
    required double readingValue,
    required String readingType, // opening, closing, interim, spot
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/supervisor/reading', {
        'pump_id': pumpId,
        'reading_value': readingValue,
        'reading_type': readingType,
        'notes': notes,
      });
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Record meter reading error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET PENDING SHIFT REPORTS
  // ─────────────────────────────────────────────

  /// GET /supervisor/shifts/pending
  /// Returns all pending shift reports for approval
  Future<List<Map<String, dynamic>>> getPendingShiftReports() async {
    try {
      final response = await _apiService.get('/supervisor/shifts/pending');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get pending shift reports error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // APPROVE SHIFT REPORT
  // ─────────────────────────────────────────────

  /// POST /supervisor/shifts/:id/approve
  /// Approves a pending shift report
  Future<bool> approveShiftReport(int reportId, String remarks) async {
    try {
      final response = await _apiService.post(
        '/supervisor/shifts/$reportId/approve',
        {'remarks': remarks},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Approve shift report error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // REJECT SHIFT REPORT
  // ─────────────────────────────────────────────

  /// POST /supervisor/shifts/:id/reject
  /// Rejects a pending shift report with reason
  Future<bool> rejectShiftReport(int reportId, String reason) async {
    try {
      final response = await _apiService.post(
        '/supervisor/shifts/$reportId/reject',
        {'reason': reason},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Reject shift report error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // EMERGENCY STOP
  // ─────────────────────────────────────────────

  /// POST /supervisor/emergency-stop
  /// Triggers an emergency stop on a pump
  Future<Map<String, dynamic>?> emergencyStop({
    required int pumpId,
    required String reason,
    required String emergencyType,
  }) async {
    try {
      final response = await _apiService.post('/supervisor/emergency-stop', {
        'pump_id': pumpId,
        'reason': reason,
        'type': emergencyType,
      });
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Emergency stop error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET INTERVENTION LOGS
  // ─────────────────────────────────────────────

  /// GET /supervisor/interventions
  /// Returns all supervisor intervention logs
  Future<List<Map<String, dynamic>>> getInterventionLogs() async {
    try {
      final response = await _apiService.get('/supervisor/interventions');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get intervention logs error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // GENERATE REPORTS
  // ─────────────────────────────────────────────

  /// GET /supervisor/reports
  /// Generates a report for the given date range
  Future<Map<String, dynamic>?> generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get(
        '/supervisor/reports?type=$reportType&start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
      );
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Generate report error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET SUPERVISOR DASHBOARD
  // ─────────────────────────────────────────────

  /// GET /dashboard/supervisor
  /// Returns supervisor dashboard data
  Future<Map<String, dynamic>?> getSupervisorDashboard() async {
    try {
      final response = await _apiService.get('/dashboard/supervisor');
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get supervisor dashboard error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  void dispose() {
    // Clean up resources if needed
  }
}