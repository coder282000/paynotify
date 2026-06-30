// lib/features/owner/domain/repositories/station_repository.dart
import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../models/station_model.dart';
import '../models/station_summary_model.dart';
import '../models/station_activity_model.dart';
import '../models/business_overview_model.dart';

class StationRepository {
  // Singleton pattern
  static final StationRepository _instance = StationRepository._internal();
  static StationRepository get instance => _instance;
  factory StationRepository() => _instance;
  StationRepository._internal();

  // ============================================================
  // STATION APIs
  // ============================================================

  /// Get all stations for the owner
  Future<List<Station>> getStations() async {
    try {
      final response = await ApiService.get('/stations');
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((json) => Station.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get stations error: $e');
      return [];
    }
  }

  /// Get station by ID
  Future<Station?> getStationById(int stationId) async {
    try {
      final response = await ApiService.get('/stations/$stationId');
      if (response['success'] == true) {
        return Station.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get station by ID error: $e');
      return null;
    }
  }

  /// Create new station
  Future<Station?> createStation(Map<String, dynamic> stationData) async {
    try {
      final response = await ApiService.post('/stations', stationData);
      if (response['success'] == true) {
        return Station.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Create station error: $e');
      return null;
    }
  }

  /// Update station
  Future<bool> updateStation(int stationId, Map<String, dynamic> stationData) async {
    try {
      final response = await ApiService.put('/stations/$stationId', stationData);
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Update station error: $e');
      return false;
    }
  }

  /// Delete station (deactivate)
  Future<bool> deleteStation(int stationId) async {
    try {
      final response = await ApiService.delete('/stations/$stationId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Delete station error: $e');
      return false;
    }
  }

  // ============================================================
  // SUMMARY APIs
  // ============================================================

  /// Get summary for all stations
  Future<List<StationSummary>> getAllStationsSummary() async {
    try {
      final response = await ApiService.get('/stations/summary/all');
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((json) => StationSummary.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get all stations summary error: $e');
      return [];
    }
  }

  /// Get summary for a specific station
  Future<StationSummary?> getStationSummary(int stationId) async {
    try {
      final response = await ApiService.get('/stations/$stationId/summary');
      if (response['success'] == true) {
        return StationSummary.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get station summary error: $e');
      return null;
    }
  }

  /// Get business overview (all stations combined)
  Future<BusinessOverview?> getBusinessOverview() async {
    try {
      final response = await ApiService.get('/stations/business/overview');
      if (response['success'] == true) {
        return BusinessOverview.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get business overview error: $e');
      return null;
    }
  }

  // ============================================================
  // ACTIVITY APIs
  // ============================================================

  /// Get recent activities across all stations
  Future<List<StationActivity>> getRecentActivities({int limit = 20}) async {
    try {
      final response = await ApiService.get('/stations/activities?limit=$limit');
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((json) => StationActivity.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get recent activities error: $e');
      return [];
    }
  }

  /// Get activities for a specific station
  Future<List<StationActivity>> getStationActivities(int stationId, {int limit = 20}) async {
    try {
      final response = await ApiService.get('/stations/$stationId/activities?limit=$limit');
      if (response['success'] == true) {
        return (response['data'] as List)
            .map((json) => StationActivity.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get station activities error: $e');
      return [];
    }
  }

  // ============================================================
  // PERFORMANCE APIs
  // ============================================================

  /// Get performance data for chart
  Future<Map<String, dynamic>> getPerformanceData(int stationId, String timeRange) async {
    try {
      final response = await ApiService.get('/stations/$stationId/performance?range=$timeRange');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('❌ Get performance data error: $e');
      return {};
    }
  }

  /// Get station ranking across all stations
  Future<Map<String, dynamic>> getStationRanking() async {
    try {
      final response = await ApiService.get('/stations/ranking');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('❌ Get station ranking error: $e');
      return {};
    }
  }

  // ============================================================
  // USER-STATION ASSIGNMENT APIs
  // ============================================================

  /// Assign user to station
  Future<bool> assignUserToStation(int stationId, int userId, String role) async {
    try {
      final response = await ApiService.post('/stations/$stationId/users', {
        'user_id': userId,
        'role': role,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Assign user to station error: $e');
      return false;
    }
  }

  /// Remove user from station
  Future<bool> removeUserFromStation(int stationId, int userId) async {
    try {
      final response = await ApiService.delete('/stations/$stationId/users/$userId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('❌ Remove user from station error: $e');
      return false;
    }
  }

  /// Get users assigned to station
  Future<List<Map<String, dynamic>>> getStationUsers(int stationId) async {
    try {
      final response = await ApiService.get('/stations/$stationId/users');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get station users error: $e');
      return [];
    }
  }
}