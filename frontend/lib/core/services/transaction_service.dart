// lib/core/services/transaction_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class TransactionService {
  // ─────────────────────────────────────────────
  // GET TRANSACTIONS
  // ─────────────────────────────────────────────

  /// Calls GET /api/transactions
  /// Role-based: attendants see own, managers/supervisors see all
  /// Optional filters: status, pump_id, limit, offset
  ///
  /// Backend returns: { success, data: [...] }
  /// Each item: id, amount, phone, customerName, paymentType, status,
  ///   pumpId, pumpNumber, attendantId, attendantName,
  ///   litersDispensed, mpesaReference, note, createdAt
  static Future<List<Map<String, dynamic>>> getTransactions({
    String? status,
    int? pumpId,
    int limit = 50,
    int offset = 0,
  }) async {
    // Build query string
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (pumpId != null) params.add('pump_id=$pumpId');
    params.add('limit=$limit');
    params.add('offset=$offset');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/transactions$query');

    if (response['success'] == true) {
      final raw = response['data'] ?? [];
      return List<Map<String, dynamic>>.from(raw);
    }

    debugPrint('getTransactions error: ${response['message']}');
    return [];
  }

  // ─────────────────────────────────────────────
  // RECORD CASH SALE
  // ─────────────────────────────────────────────

  /// Calls POST /api/transactions/cash
  /// Required: pump_id, amount
  /// Optional: customer_name, liters_dispensed, note
  ///
  /// Backend returns: { success, data: { id, amount, paymentType,
  ///   status, pumpId, attendantId, createdAt } }
  static Future<Map<String, dynamic>?> recordCashSale({
    required int pumpId,
    required double amount,
    String? customerName,
    double? litersDispensed,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'pump_id': pumpId,
      'amount': amount,
    };

    if (customerName != null && customerName.isNotEmpty) {
      body['customer_name'] = customerName;
    }
    if (litersDispensed != null) {
      body['liters_dispensed'] = litersDispensed;
    }
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    debugPrint('Recording cash sale: $body');

    final response = await ApiService.post('/transactions/cash', body);

    if (response['success'] == true) {
      debugPrint('Cash sale recorded: ${response['data']}');
      return response['data'] as Map<String, dynamic>?;
    }

    // Surface validation errors
    if (response['errors'] != null) {
      final errors = response['errors'] as List;
      final messages = errors.map((e) => e['message']).join(', ');
      debugPrint('Cash sale validation error: $messages');
    } else {
      debugPrint('Cash sale error: ${response['message']}');
    }

    return null;
  }

  // ─────────────────────────────────────────────
  // RECORD CARD SALE
  // ─────────────────────────────────────────────

  /// Calls POST /api/transactions/card
  /// Required: pump_id, amount
  /// Optional: customer_name, liters_dispensed, note
  ///
  /// Backend returns: { success, data: { id, amount, paymentType,
  ///   status, pumpId, attendantId, createdAt } }
  static Future<Map<String, dynamic>?> recordCardSale({
    required int pumpId,
    required double amount,
    String? customerName,
    double? litersDispensed,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'pump_id': pumpId,
      'amount': amount,
    };

    if (customerName != null && customerName.isNotEmpty) {
      body['customer_name'] = customerName;
    }
    if (litersDispensed != null) {
      body['liters_dispensed'] = litersDispensed;
    }
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    debugPrint('Recording card sale: $body');

    final response = await ApiService.post('/transactions/card', body);

    if (response['success'] == true) {
      debugPrint('Card sale recorded: ${response['data']}');
      return response['data'] as Map<String, dynamic>?;
    }

    if (response['errors'] != null) {
      final errors = response['errors'] as List;
      final messages = errors.map((e) => e['message']).join(', ');
      debugPrint('Card sale validation error: $messages');
    } else {
      debugPrint('Card sale error: ${response['message']}');
    }

    return null;
  }

  // ─────────────────────────────────────────────
  // INITIATE M-PESA (placeholder)
  // ─────────────────────────────────────────────

  /// Calls POST /api/transactions/mpesa
  /// This is a placeholder until Phase 3 M-Pesa integration
  static Future<Map<String, dynamic>?> initiateMpesa({
    required int pumpId,
    required double amount,
    required String phoneNumber,
  }) async {
    final response = await ApiService.post('/transactions/mpesa', {
      'pump_id': pumpId,
      'amount': amount,
      'phone_number': phoneNumber,
    });

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('initiateMpesa error: ${response['message']}');
    return null;
  }

  // ─────────────────────────────────────────────
  // GET TRANSACTION SUMMARY
  // ─────────────────────────────────────────────

  /// Calls GET /api/transactions/summary (manager & supervisor only)
  /// Optional: start_date, end_date (YYYY-MM-DD)
  ///
  /// Backend returns: { success, data: { overview, byPaymentType,
  ///   byPump, byPaymentTypeDetailed } }
  static Future<Map<String, dynamic>?> getTransactionSummary({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/transactions/summary$query');

    if (response['success'] == true) {
      return response['data'] as Map<String, dynamic>?;
    }

    debugPrint('getTransactionSummary error: ${response['message']}');
    return null;
  }
}