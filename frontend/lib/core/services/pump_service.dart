// lib/core/services/pump_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PumpService {
  // ─────────────────────────────────────────────
  // GET ALL PUMPS
  // ─────────────────────────────────────────────

  /// Calls GET /api/pumps?station_id=X
  /// If stationId is provided, only returns pumps for that station
  static Future<List<Map<String, dynamic>>> getPumps({
    int? stationId,
  }) async {
    final query = stationId != null ? '?station_id=$stationId' : '';
    final response = await ApiService.get('/pumps$query');

    if (response['success'] == true) {
      final raw = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(raw);
    }

    debugPrint('getPumps error: ${response['message']}');
    return [];
  }

  // ─────────────────────────────────────────────
  // GET SINGLE PUMP
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getPumpById(int pumpId) async {
    final response = await ApiService.get('/pumps/$pumpId');

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('getPumpById error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // CREATE PUMP
  // ─────────────────────────────────────────────

  /// Calls POST /api/pumps (manager only)
  /// Required: pump_number, fuel_type, price_per_liter, station_id
  static Future<Map<String, dynamic>?> createPump({
    required String pumpNumber,
    required String fuelType,
    required double pricePerLiter,
    required int stationId,
    double tankCapacity = 10000,
  }) async {
    final response = await ApiService.post('/pumps', {
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
  // UPDATE PUMP STATUS
  // ─────────────────────────────────────────────

  /// Calls PUT /api/pumps/:id/status (manager & supervisor)
  /// Valid: active, maintenance, inactive, occupied, emergency
  static Future<bool> updatePumpStatus(int pumpId, String status) async {
    final response = await ApiService.put(
      '/pumps/$pumpId/status',
      {'status': status.toLowerCase()},
    );

    if (response['success'] == true) return true;

    debugPrint('updatePumpStatus error: ${response['message']}');
    return false;
  }

  // ─────────────────────────────────────────────
  // UPDATE FUEL PRICE
  // ─────────────────────────────────────────────

  /// Calls PUT /api/pumps/:id/price (manager only)
  static Future<bool> updateFuelPrice(int pumpId, double pricePerLiter) async {
    final response = await ApiService.put(
      '/pumps/$pumpId/price',
      {'price_per_liter': pricePerLiter},
    );

    if (response['success'] == true) return true;

    debugPrint('updateFuelPrice error: ${response['message']}');
    return false;
  }
}