// lib/core/services/pump_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PumpService {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION
  // ─────────────────────────────────────────────
  final ApiService _apiService;

  PumpService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ─────────────────────────────────────────────
  // GET ALL PUMPS (General - for attendants/supervisors)
  // ─────────────────────────────────────────────

  /// Calls GET /api/pumps?station_id=X
  /// If stationId is provided, only returns pumps for that station
  Future<List<Map<String, dynamic>>> getPumps({
    int? stationId,
  }) async {
    final query = stationId != null ? '?station_id=$stationId' : '';
    final response = await _apiService.get('/pumps$query');

    if (response['success'] == true) {
      final raw = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(raw);
    }

    debugPrint('getPumps error: ${response['message']}');
    return [];
  }

  // ─────────────────────────────────────────────
  // GET MANAGER PUMPS (with full stats)
  // ─────────────────────────────────────────────

  /// Calls GET /api/manager/pumps
  /// Returns pumps with today_sales, total_sales, fuel_percentage, etc.
  Future<List<Map<String, dynamic>>> getManagerPumps() async {
    final response = await _apiService.get('/manager/pumps');

    if (response['success'] == true) {
      final raw = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(raw);
    }

    debugPrint('getManagerPumps error: ${response['message']}');
    return [];
  }

  // ─────────────────────────────────────────────
  // GET SINGLE PUMP
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getPumpById(int pumpId) async {
    final response = await _apiService.get('/pumps/$pumpId');

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('getPumpById error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // GET MANAGER PUMP BY ID (with full details)
  // ─────────────────────────────────────────────

  /// Calls GET /api/manager/pumps/:id
  /// Returns pump with performance metrics and recent transactions
  Future<Map<String, dynamic>?> getManagerPumpById(int pumpId) async {
    final response = await _apiService.get('/manager/pumps/$pumpId');

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('getManagerPumpById error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // CREATE PUMP
  // ─────────────────────────────────────────────

  /// Calls POST /api/pumps (manager only)
  /// Required: pump_number, fuel_type, price_per_liter, station_id
  Future<Map<String, dynamic>?> createPump({
    required String pumpNumber,
    required String fuelType,
    required double pricePerLiter,
    required int stationId,
    double tankCapacity = 10000,
  }) async {
    final response = await _apiService.post('/pumps', {
      'pump_number': pumpNumber,
      'fuel_type': fuelType.toLowerCase(),
      'price_per_liter': pricePerLiter,
      'tank_capacity': tankCapacity,
      'station_id': stationId,
    });

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('createPump error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // CREATE MANAGER PUMP (using manager endpoint)
  // ─────────────────────────────────────────────

  /// Calls POST /api/manager/pumps (manager only)
  /// Uses the manager's station automatically
  Future<Map<String, dynamic>?> createManagerPump({
    required String pumpNumber,
    required String fuelType,
    required double pricePerLiter,
    double tankCapacity = 10000,
  }) async {
    final response = await _apiService.post('/manager/pumps', {
      'pump_number': pumpNumber,
      'fuel_type': fuelType.toLowerCase(),
      'price_per_liter': pricePerLiter,
      'tank_capacity': tankCapacity,
    });

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('createManagerPump error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // UPDATE PUMP STATUS
  // ─────────────────────────────────────────────

  /// Calls PUT /api/pumps/:id/status (manager & supervisor)
  /// Valid: active, maintenance, inactive, occupied, emergency
  Future<bool> updatePumpStatus(int pumpId, String status) async {
    final response = await _apiService.put(
      '/pumps/$pumpId/status',
      {'status': status.toLowerCase()},
    );

    if (response['success'] == true) return true;

    debugPrint('updatePumpStatus error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // UPDATE MANAGER PUMP STATUS
  // ─────────────────────────────────────────────

  /// Calls PUT /api/manager/pumps/:id/status
  /// Manager-only version with better validation
  Future<bool> updateManagerPumpStatus(int pumpId, String status) async {
    final response = await _apiService.put(
      '/manager/pumps/$pumpId/status',
      {'status': status.toLowerCase()},
    );

    if (response['success'] == true) return true;

    debugPrint('updateManagerPumpStatus error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // UPDATE FUEL PRICE
  // ─────────────────────────────────────────────

  /// Calls PUT /api/pumps/:id/price (manager only)
  Future<bool> updateFuelPrice(int pumpId, double pricePerLiter) async {
    final response = await _apiService.put(
      '/pumps/$pumpId/price',
      {'price_per_liter': pricePerLiter},
    );

    if (response['success'] == true) return true;

    debugPrint('updateFuelPrice error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // UPDATE MANAGER PUMP PRICE
  // ─────────────────────────────────────────────

  /// Calls PUT /api/manager/pumps/:id/price
  /// Manager-only version
  Future<bool> updateManagerFuelPrice(int pumpId, double pricePerLiter) async {
    final response = await _apiService.put(
      '/manager/pumps/$pumpId/price',
      {'price_per_liter': pricePerLiter},
    );

    if (response['success'] == true) return true;

    debugPrint('updateManagerFuelPrice error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // DELETE/DEACTIVATE PUMP
  // ─────────────────────────────────────────────

  /// Calls DELETE /api/manager/pumps/:id
  /// Soft deletes the pump (sets is_active = false)
  Future<bool> deleteManagerPump(int pumpId) async {
    final response = await _apiService.delete('/manager/pumps/$pumpId');

    if (response['success'] == true) return true;

    debugPrint('deleteManagerPump error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // GET PUMP PERFORMANCE
  // ─────────────────────────────────────────────

  /// Calls GET /api/manager/pumps/:id/performance?period=today|week|month
  Future<Map<String, dynamic>?> getPumpPerformance(
    int pumpId, {
    String period = 'today',
  }) async {
    final response = await _apiService.get(
      '/manager/pumps/$pumpId/performance?period=$period',
    );

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('getPumpPerformance error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  void dispose() {
    // Clean up resources if needed
  }
}