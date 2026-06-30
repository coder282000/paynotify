// lib/core/services/station_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class StationService {
  // ─────────────────────────────────────────────
  // GET ALL STATIONS
  // ─────────────────────────────────────────────

  /// Calls GET /api/stations
  /// Backend returns { success, data: [...] }
  static Future<Map<String, dynamic>> getStations() async {
    final response = await ApiService.get('/stations');

    if (response['success'] == true) {
      // Backend returns 'data' not 'stations'
      final raw = response['data'] ?? [];
      final stations = List<Map<String, dynamic>>.from(raw);
      return {'success': true, 'stations': stations};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to load stations.',
    };
  }

  // ─────────────────────────────────────────────
  // GET SINGLE STATION
  // ─────────────────────────────────────────────

  /// Calls GET /api/stations/:id
  /// Backend returns { success, data: {...} }
  static Future<Map<String, dynamic>> getStation(int stationId) async {
    final response = await ApiService.get('/stations/$stationId');

    if (response['success'] == true) {
      final station = response['data'];
      return {'success': true, 'station': station};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to load station details.',
    };
  }

  // ─────────────────────────────────────────────
  // CREATE STATION
  // ─────────────────────────────────────────────

  /// Calls POST /api/stations
  ///
  /// Backend expects (snake_case):
  ///   station_name  — required, 3-100 chars
  ///   station_code  — required, 2-20 chars, UPPERCASE ALPHANUMERIC ONLY
  ///   location      — required, 5-255 chars (maps from physicalAddress)
  ///   city          — optional
  ///   county        — optional
  ///   phone         — optional, valid mobile number
  ///   email         — optional, valid email
  ///   manager_id    — optional, integer
  ///   paybill_number— optional
  ///   till_number   — optional
  static Future<Map<String, dynamic>> createStation(
    Map<String, dynamic> formData,
  ) async {
    // Map Flutter field names → backend snake_case field names
    final payload = <String, dynamic>{
      'station_name': formData['stationName'] ?? formData['station_name'],
      'station_code': (formData['stationCode'] ?? formData['station_code'] ?? '')
          .toString()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), ''), // strip invalid chars
      'location': formData['physicalAddress'] ??
          formData['location'] ??
          formData['physical_address'],
    };

    // Optional fields — only include if provided and non-empty
    final optionalFields = {
      'city': formData['city'],
      'county': formData['county'],
      'phone': formData['phone'],
      'email': formData['email'],
      'manager_id': formData['managerId'] ?? formData['manager_id'],
      'paybill_number': formData['paybillNumber'] ?? formData['paybill_number'],
      'till_number': formData['tillNumber'] ?? formData['till_number'],
    };

    optionalFields.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        payload[key] = value;
      }
    });

    debugPrint('Creating station with payload: $payload');

    final response = await ApiService.post('/stations', payload);

    if (response['success'] == true) {
      final station = response['data'];
      return {'success': true, 'station': station};
    }

    // Surface validation errors clearly
    if (response['errors'] != null) {
      final errors = response['errors'] as List;
      final messages = errors.map((e) => e['message']).join(', ');
      return {'success': false, 'message': messages};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to create station.',
    };
  }

  // ─────────────────────────────────────────────
  // UPDATE STATION
  // ─────────────────────────────────────────────

  /// Calls PUT /api/stations/:id
  static Future<Map<String, dynamic>> updateStation(
    int stationId,
    Map<String, dynamic> formData,
  ) async {
    // Map Flutter field names → backend snake_case
    final payload = <String, dynamic>{};

    final fieldMap = {
      'station_name': formData['stationName'] ?? formData['station_name'],
      'location': formData['physicalAddress'] ?? formData['location'],
      'city': formData['city'],
      'county': formData['county'],
      'phone': formData['phone'],
      'email': formData['email'],
      'manager_id': formData['managerId'] ?? formData['manager_id'],
      'paybill_number': formData['paybillNumber'] ?? formData['paybill_number'],
      'till_number': formData['tillNumber'] ?? formData['till_number'],
      'status': formData['status'],
    };

    fieldMap.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        payload[key] = value;
      }
    });

    debugPrint('Updating station $stationId with payload: $payload');

    final response = await ApiService.put('/stations/$stationId', payload);

    if (response['success'] == true) {
      final station = response['data'];
      return {'success': true, 'station': station};
    }

    if (response['errors'] != null) {
      final errors = response['errors'] as List;
      final messages = errors.map((e) => e['message']).join(', ');
      return {'success': false, 'message': messages};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to update station.',
    };
  }

  // ─────────────────────────────────────────────
  // GET STATION SUMMARY
  // ─────────────────────────────────────────────

  /// Calls GET /api/stations/:id/summary
  /// Optional query params: start_date, end_date (YYYY-MM-DD)
  /// If not provided, backend defaults to today
  static Future<Map<String, dynamic>> getStationSummary(
    int stationId, {
    String period = 'today',
  }) async {
    // Convert period → date range the backend understands
    final now = DateTime.now();
    String startDate;
    String endDate = _formatDate(now);

    switch (period.toLowerCase()) {
      case 'week':
        startDate = _formatDate(now.subtract(const Duration(days: 7)));
        break;
      case 'month':
        startDate = _formatDate(DateTime(now.year, now.month, 1));
        break;
      case 'year':
        startDate = _formatDate(DateTime(now.year, 1, 1));
        break;
      case 'today':
      default:
        startDate = endDate; // same day
        break;
    }

    final endpoint =
        '/stations/$stationId/summary?start_date=$startDate&end_date=$endDate';

    final response = await ApiService.get(endpoint);

    if (response['success'] == true) {
      // Backend returns { success, data: { totalTransactions, totalSales, ... } }
      final summaryData = response['data'] as Map<String, dynamic>? ?? {};

      // Attach stationId so OwnerProvider can match it
      summaryData['stationId'] = stationId;

      return {'success': true, 'summary': summaryData};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to load station summary.',
    };
  }

  // ─────────────────────────────────────────────
  // GET STATION PERFORMANCE
  // ─────────────────────────────────────────────

  /// Calls GET /api/stations/:id/performance
  static Future<Map<String, dynamic>> getStationPerformance(
    int stationId,
  ) async {
    final response = await ApiService.get('/stations/$stationId/performance');

    if (response['success'] == true) {
      return {'success': true, 'performance': response['data']};
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Failed to load station performance.',
    };
  }

  // ─────────────────────────────────────────────
  // GET ALL STATIONS SUMMARIES
  // ─────────────────────────────────────────────

  /// Fetches summary for every station ID in the list
  static Future<Map<String, dynamic>> getAllStationsSummaries(
    List<int> stationIds, {
    String period = 'today',
  }) async {
    try {
      final summaries = <Map<String, dynamic>>[];

      for (final id in stationIds) {
        final result = await getStationSummary(id, period: period);
        if (result['success'] == true) {
          summaries.add(result['summary'] as Map<String, dynamic>);
        } else {
          debugPrint('Could not load summary for station $id: ${result['message']}');
        }
      }

      return {'success': true, 'summaries': summaries};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load station summaries: $e',
      };
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}