// lib/features/owner/presentation/providers/owner_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/station_model.dart';
import '../../domain/models/station_summary_model.dart';
import '../../domain/models/business_overview_model.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/models/fuel_inventory.dart';
import 'package:paynotify/core/services/station_service.dart';
import 'package:paynotify/core/services/employee_service.dart';

class OwnerProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────
  List<Station> _stations = [];
  List<StationSummary> _stationSummaries = [];
  StationSummary? _selectedStationSummary;
  Station? _selectedStation;
  BusinessOverview? _businessOverview;
  List<OwnerEmployee> _employees = [];
  List<OwnerExpense> _expenses = [];
  List<Subscription> _subscriptions = [];
  List<FuelInventory> _fuelInventory = [];

  // ─────────────────────────────────────────────
  // UI STATE
  // ─────────────────────────────────────────────
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingFuelInventory = false;
  String? _errorMessage;
  String _selectedTimeRange = 'Today';

  // Debounce timer to prevent rapid successive notifyListeners calls
  Timer? _notifyTimer;

  // ─────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────
  List<Station> get stations => _stations;
  List<StationSummary> get stationSummaries => _stationSummaries;
  StationSummary? get selectedStationSummary => _selectedStationSummary;
  Station? get selectedStation => _selectedStation;
  BusinessOverview? get businessOverview => _businessOverview;
  List<OwnerEmployee> get employees => _employees;
  List<OwnerExpense> get expenses => _expenses;
  List<Subscription> get subscriptions => _subscriptions;
  List<FuelInventory> get fuelInventory => _fuelInventory;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingFuelInventory => _isLoadingFuelInventory;
  String? get errorMessage => _errorMessage;
  String get selectedTimeRange => _selectedTimeRange;

  // Computed totals from real station summaries
  double get totalTodaySales =>
      _stationSummaries.fold(0.0, (sum, s) => sum + s.todaySales);
  double get totalMonthlySales =>
      _stationSummaries.fold(0.0, (sum, s) => sum + s.monthlySales);
  int get totalActivePumps =>
      _stationSummaries.fold(0, (sum, s) => sum + s.activePumps);
  int get totalAttendants =>
      _stationSummaries.fold(0, (sum, s) => sum + s.totalAttendants);
  int get todayTransactions =>
      _stationSummaries.fold(0, (sum, s) => sum + s.todayTransactions);

  // ─────────────────────────────────────────────
  // SAFE NOTIFY (debounced)
  // ─────────────────────────────────────────────
  @override
  void notifyListeners() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 10), () {
      if (hasListeners) super.notifyListeners();
    });
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // STATION MANAGEMENT
  // ============================================================

  /// Loads all stations from GET /api/stations
  Future<void> loadStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await StationService.getStations();

      if (result['success'] == true) {
        final rawList = result['stations'] as List<Map<String, dynamic>>;
        _stations = rawList.map((json) => Station.fromJson(json)).toList();
        debugPrint('✅ Loaded ${_stations.length} stations from API');
      } else {
        _errorMessage = result['message'];
        debugPrint('❌ loadStations error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load stations: $e';
      debugPrint('❌ loadStations exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new station via POST /api/stations
  Future<bool> createStation(Map<String, dynamic> stationData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await StationService.createStation(stationData);

      if (result['success'] == true) {
        await loadStations();
        await loadAllStationsSummary();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create station: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ createStation exception: $e');
      return false;
    }
  }

  /// Updates a station via PUT /api/stations/:id
  Future<bool> updateStation(
    int stationId,
    Map<String, dynamic> stationData,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await StationService.updateStation(stationId, stationData);

      if (result['success'] == true) {
        await loadStations();
        await loadAllStationsSummary();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update station: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ updateStation exception: $e');
      return false;
    }
  }

  // ============================================================
  // SUMMARY MANAGEMENT
  // ============================================================

  /// Loads summaries for all stations and builds the BusinessOverview
  Future<void> loadAllStationsSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_stations.isEmpty) {
        _stationSummaries = [];
        _businessOverview = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final stationIds = _stations.map((s) => s.id).toList();
      final result = await StationService.getAllStationsSummaries(
        stationIds,
        period: _selectedTimeRange.toLowerCase(),
      );

      if (result['success'] == true) {
        final rawList = result['summaries'] as List<Map<String, dynamic>>;
        _stationSummaries = rawList
            .map((json) => _parseSummaryFromApi(json))
            .toList();

        _businessOverview = _buildBusinessOverview();
        debugPrint('✅ Loaded ${_stationSummaries.length} station summaries');
      } else {
        _errorMessage = result['message'];
        debugPrint('❌ loadAllStationsSummary error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load summaries: $e';
      debugPrint('❌ loadAllStationsSummary exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads summary for a single station (used on StationDetailsScreen)
  Future<void> loadStationSummary(int stationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await StationService.getStationSummary(stationId);

      if (result['success'] == true) {
        _selectedStationSummary =
            _parseSummaryFromApi(result['summary'] as Map<String, dynamic>);
        _selectedStation =
            _stations.firstWhere((s) => s.id == stationId, orElse: () => _stations.first);
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Failed to load station summary: $e';
      debugPrint('❌ loadStationSummary exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // EMPLOYEE MANAGEMENT
  // ============================================================

  /// Load all employees (owner sees all employees across all stations)
  Future<void> loadEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.getEmployees();

      if (result['success'] == true) {
        final rawList = result['data'] as List?;
        
        if (rawList == null || rawList.isEmpty) {
          _employees = [];
          debugPrint('📊 No employees found');
        } else {
          try {
            _employees = rawList.map((json) {
              if (json is Map<String, dynamic>) {
                try {
                  return OwnerEmployee.fromJson(json);
                } catch (e) {
                  debugPrint('⚠️ Error parsing employee: $e');
                  return null;
                }
              }
              return null;
            }).where((e) => e != null).cast<OwnerEmployee>().toList();
          } catch (e) {
            debugPrint('❌ Error parsing employees list: $e');
            _employees = [];
          }
        }
        
        debugPrint('✅ Loaded ${_employees.length} employees (owner view)');
        for (var emp in _employees) {
          debugPrint('   - ${emp.name} (${emp.role}) - ${emp.status}');
        }
      } else {
        _errorMessage = result['message'];
        debugPrint('❌ loadEmployees error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load employees: $e';
      debugPrint('❌ loadEmployees exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Invite a new employee via email
  Future<Map<String, dynamic>> inviteEmployee({
    required String email,
    required String fullName,
    required String role,
    String? phone,
    int? stationId,
    int? assignedPumpId,
    String? employeeRole,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.inviteEmployee({
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone': phone,
        'station_id': stationId,
        'assigned_pump_id': assignedPumpId,
        'employee_role': employeeRole ?? role,
      });

      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _errorMessage = 'Failed to send invitation: $e';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Approve or reject a pending employee registration
  Future<bool> approveEmployee(String userId, bool approved, {String? notes}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await EmployeeService.approveEmployee(
        int.parse(userId),
        approved,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        // Refresh employee list after approval/rejection
        await loadEmployees();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to process approval: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend invitation to a pending employee
  Future<bool> resendInvitation(String email, String fullName, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await EmployeeService.resendInvitation({
        'email': email,
        'full_name': fullName,
        'role': role,
      });

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        return true;
      }
      _errorMessage = result['message'];
      return false;
    } catch (e) {
      _errorMessage = 'Failed to resend invitation: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get pending employee registrations
  Future<List<Map<String, dynamic>>> getPendingRegistrations() async {
    try {
      final result = await EmployeeService.getPendingRegistrations();
      if (result['success'] == true) {
        return result['data'] as List<Map<String, dynamic>>;
      }
      return [];
    } catch (e) {
      debugPrint('❌ getPendingRegistrations error: $e');
      return [];
    }
  }

  // ============================================================
  // EXPENSE MANAGEMENT  (stubs — connect when endpoint is ready)
  // ============================================================

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createExpense(Map<String, dynamic> expenseData) async {
    return false;
  }

  // ============================================================
  // FUEL INVENTORY  (stubs — connect when endpoint is ready)
  // ============================================================

  Future<void> loadFuelInventory() async {
    _isLoadingFuelInventory = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _fuelInventory = [];
    _isLoadingFuelInventory = false;
    notifyListeners();
  }

  Future<bool> recordFuelDelivery({
    required String tankId,
    required double amount,
    required String supplier,
    required double costPerLiter,
  }) async {
    return false;
  }

  // ============================================================
  // SUBSCRIPTION MANAGEMENT  (stubs)
  // ============================================================

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _subscriptions = [];
    _isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  void setTimeRange(String range) {
    if (_selectedTimeRange == range) return;
    _selectedTimeRange = range;
    notifyListeners();
    loadAllStationsSummary();
  }

  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();

    await loadStations();
    await loadAllStationsSummary();
    await loadEmployees();

    _isRefreshing = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  /// Maps raw API summary JSON → StationSummary model.
  StationSummary _parseSummaryFromApi(Map<String, dynamic> json) {
    return StationSummary(
      stationId: _toInt(json['stationId'] ?? json['station_id'] ?? 0),
      stationName: json['stationName']?.toString() ??
          json['station_name']?.toString() ??
          'Unknown',
      stationCode: json['stationCode']?.toString() ??
          json['station_code']?.toString() ??
          '',
      
      // SALES FIELDS - DOUBLE
      todaySales: _toDouble(json['totalSales'] ?? json['todaySales'] ?? json['today_sales'] ?? 0),
      weeklySales: _toDouble(json['weeklySales'] ?? json['weekly_sales'] ?? 0),
      monthlySales: _toDouble(json['monthlySales'] ?? json['monthly_sales'] ?? 0),
      yearlySales: _toDouble(json['yearlySales'] ?? json['yearly_sales'] ?? 0),
      lastMonthSales: _toDouble(json['lastMonthSales'] ?? json['last_month_sales'] ?? 0),
      salesGrowth: _toDouble(json['salesGrowth'] ?? json['sales_growth'] ?? 0),
      
      // TRANSACTION FIELDS - INT
      todayTransactions: _toInt(json['transactionCount'] ?? json['todayTransactions'] ?? json['today_transactions'] ?? 0),
      totalTransactions: _toInt(json['totalTransactions'] ?? json['total_transactions'] ?? 0),
      
      // AVERAGE - DOUBLE
      averageTransactionValue: _toDouble(json['averageTransaction'] ?? json['averageTransactionValue'] ?? json['average_transaction_value'] ?? 0),
      
      // PAYMENT TOTALS - DOUBLE
      cashTotal: _toDouble(json['cashTotal'] ?? json['cash_total'] ?? 0),
      cardTotal: _toDouble(json['cardTotal'] ?? json['card_total'] ?? 0),
      mpesaTotal: _toDouble(json['mpesaTotal'] ?? json['mpesa_total'] ?? 0),
      
      // PUMP FIELDS - INT
      totalPumps: _toInt(json['totalPumps'] ?? json['total_pumps'] ?? 0),
      activePumps: _toInt(json['activePumps'] ?? json['active_pumps'] ?? 0),
      pumpsUnderMaintenance: _toInt(json['pumpsUnderMaintenance'] ?? json['pumps_under_maintenance'] ?? 0),
      
      // ATTENDANT FIELDS - INT
      totalAttendants: _toInt((json['staffMetrics'] as Map?)?['totalStaff'] ?? json['totalAttendants'] ?? json['total_attendants'] ?? 0),
      activeAttendants: _toInt((json['staffMetrics'] as Map?)?['activeStaff'] ?? json['activeAttendants'] ?? json['active_attendants'] ?? 0),
      pendingShiftReports: _toInt(json['pendingShiftReports'] ?? json['pending_shift_reports'] ?? 0),
      
      // INVENTORY - DOUBLE
      totalFuelInventory: _toDouble(json['totalFuelInventory'] ?? json['total_fuel_inventory'] ?? 0),
      
      // LOW FUEL ALERTS - DOUBLE (matches model)
      lowFuelAlerts: _toDouble(json['lowFuelAlerts'] ?? json['low_fuel_alerts'] ?? 0),
      
      // PERFORMANCE SCORES - DOUBLE
      attendantPerformanceScore: _toDouble(json['attendantPerformanceScore'] ?? json['attendant_performance_score'] ?? 0),
      
      // CUSTOMER SATISFACTION - INT (matches model)
      customerSatisfaction: _toInt(json['customerSatisfaction'] ?? json['customer_satisfaction'] ?? 0),
      
      lastUpdated: DateTime.now(),
    );
  }

  BusinessOverview _buildBusinessOverview() {
    return BusinessOverview(
      totalTodaySales: totalTodaySales,
      totalWeeklySales: _stationSummaries.fold(0.0, (s, e) => s + e.weeklySales),
      totalMonthlySales: totalMonthlySales,
      totalYearlySales: _stationSummaries.fold(0.0, (s, e) => s + e.yearlySales),
      totalStations: _stations.length,
      activeStations: _stations.where((s) => s.isActive).length,
      totalPumps: _stationSummaries.fold(0, (s, e) => s + e.totalPumps),
      totalAttendants: totalAttendants,
      totalTransactionsToday: todayTransactions,
      overallSalesGrowth: _stationSummaries.isEmpty
          ? 0
          : _stationSummaries.fold(0.0, (s, e) => s + e.salesGrowth) /
              _stationSummaries.length,
      stationSummaries: _stationSummaries,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert any value to int safely
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Convert any value to double safely
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}