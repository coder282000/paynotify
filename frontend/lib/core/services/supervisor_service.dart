// lib/core/services/supervisor_service.dart
import 'package:flutter/foundation.dart';
import 'package:paynotify/core/services/api_service.dart';

class SupervisorService {
  // Get all pumps with status
  static Future<List<Map<String, dynamic>>> getAllPumps() async {
    try {
      final response = await ApiService.get('/supervisor/pumps');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get all pumps error: $e');
      return [];
    }
  }
  
  // Override sale on any pump
  static Future<Map<String, dynamic>?> overrideSale({
    required int pumpId,
    required double amount,
    required String reason,
    String? customerName,
  }) async {
    try {
      final response = await ApiService.post('/supervisor/sale', {
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
  
  // Record fuel refill
  static Future<Map<String, dynamic>?> recordFuelRefill({
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
      final response = await ApiService.post('/supervisor/refill', {
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
  
  // Record meter reading
  static Future<Map<String, dynamic>?> recordMeterReading({
    required int pumpId,
    required double readingValue,
    required String readingType, // opening, closing, interim, spot
    String? notes,
  }) async {
    try {
      final response = await ApiService.post('/supervisor/reading', {
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
  
  // Get pending shift reports
  static Future<List<Map<String, dynamic>>> getPendingShiftReports() async {
    try {
      final response = await ApiService.get('/supervisor/shifts/pending');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get pending shift reports error: $e');
      return [];
    }
  }
  
  // Approve shift report
  static Future<bool> approveShiftReport(int reportId, String remarks) async {
    try {
      final response = await ApiService.post('/supervisor/shifts/$reportId/approve', {
        'remarks': remarks,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('Approve shift report error: $e');
      return false;
    }
  }
  
  // Reject shift report
  static Future<bool> rejectShiftReport(int reportId, String reason) async {
    try {
      final response = await ApiService.post('/supervisor/shifts/$reportId/reject', {
        'reason': reason,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('Reject shift report error: $e');
      return false;
    }
  }
  
  // Emergency stop
  static Future<Map<String, dynamic>?> emergencyStop({
    required int pumpId,
    required String reason,
    required String emergencyType,
  }) async {
    try {
      final response = await ApiService.post('/supervisor/emergency-stop', {
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
  
  // Get intervention logs
  static Future<List<Map<String, dynamic>>> getInterventionLogs() async {
    try {
      final response = await ApiService.get('/supervisor/interventions');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Get intervention logs error: $e');
      return [];
    }
  }
  
  // Generate reports
  static Future<Map<String, dynamic>?> generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await ApiService.get(
        '/supervisor/reports?type=$reportType&start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}'
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
  
  // Get supervisor dashboard data
  static Future<Map<String, dynamic>?> getSupervisorDashboard() async {
    try {
      final response = await ApiService.get('/dashboard/supervisor');
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Get supervisor dashboard error: $e');
      return null;
    }
  }
}