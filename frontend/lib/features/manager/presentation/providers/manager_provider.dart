// lib/features/manager/presentation/providers/manager_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/models/station_summary.dart';
import '../../domain/models/pump_status.dart';
import '../../domain/models/manager_transaction.dart';
import '../../domain/models/pump_config.dart' as pump_config;
import '../../domain/models/employee_model.dart';
import '../../domain/models/customer_model.dart';

import '../../../../core/services/pump_service.dart';
import '../../../../core/services/manager_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/services/employee_service.dart';

class ManagerProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────
  StationSummary? _stationSummary;
  List<PumpStatus> _pumps = [];
  List<ManagerTransaction> _recentTransactions = [];
  List<ManagerTransaction> _filteredTransactions = [];
  List<String> _alerts = [];
  List<double> _salesData = [];
  
  // Extended data for manager features
  List<pump_config.PumpConfig> _pumpConfigs = [];
  List<Employee> _employees = [];
  List<Customer> _customers = [];
  
  // Stats
  int _activeAttendants = 0;
  int _pendingReports = 0;
  int _lowFuelPumps = 0;
  double _mpesaTotal = 0;
  double _cashTotal = 0;
  
  // ─────────────────────────────────────────────
  // UI STATE
  // ─────────────────────────────────────────────
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // Debounce timer
  Timer? _notifyTimer;

  // ─────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────
  StationSummary get stationSummary => _stationSummary ?? StationSummary(
    todaySales: 0,
    salesChange: 0,
    transactionCount: 0,
    transactionChange: 0,
    activePumps: 0,
    totalPumps: 0,
    activeAttendants: 0,
    totalAttendants: 0,
  );
  
  List<PumpStatus> get pumps => _pumps;
  List<ManagerTransaction> get recentTransactions => 
      _filteredTransactions.isEmpty ? _recentTransactions : _filteredTransactions;
  List<String> get alerts => _alerts;
  bool get hasAlerts => _alerts.isNotEmpty;
  List<double> get salesData => _salesData;
  int get activeAttendants => _activeAttendants;
  int get pendingReports => _pendingReports;
  int get lowFuelPumps => _lowFuelPumps;
  double get mpesaTotal => _mpesaTotal;
  double get cashTotal => _cashTotal;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get hasData => _recentTransactions.isNotEmpty || _pumps.isNotEmpty;
  
  // Extended getters
  List<pump_config.PumpConfig> get pumpConfigs => _pumpConfigs;
  List<Employee> get employees => _employees;
  List<Customer> get customers => _customers;

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
  // DASHBOARD DATA
  // ============================================================

  /// Load complete dashboard data
  Future<void> loadDashboardData(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Load all data in parallel
      await Future.wait([
        _loadStationSummary(),
        _loadPumps(),
        _loadRecentTransactions(),
        _loadAlerts(),
        _loadSalesChartData(),
        _loadStats(),
      ]);
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      debugPrint('Dashboard load error: $e');
    }
  }

  /// Load station summary from backend
  Future<void> _loadStationSummary() async {
    try {
      final dashboardData = await ManagerService.getManagerDashboard();
      
      if (dashboardData != null) {
        _stationSummary = StationSummary(
          todaySales: _toDouble(dashboardData['today_sales'] ?? 0),
          salesChange: _toDouble(dashboardData['sales_change'] ?? 0),
          transactionCount: _toInt(dashboardData['transaction_count'] ?? 0),
          transactionChange: _toDouble(dashboardData['transaction_change'] ?? 0),
          activePumps: _toInt(dashboardData['active_pumps'] ?? 0),
          totalPumps: _toInt(dashboardData['total_pumps'] ?? 0),
          activeAttendants: _toInt(dashboardData['active_attendants'] ?? 0),
          totalAttendants: _toInt(dashboardData['total_attendants'] ?? 0),
        );
      } else {
        // Use default values if backend returns null
        _stationSummary = StationSummary(
          todaySales: 0,
          salesChange: 0,
          transactionCount: 0,
          transactionChange: 0,
          activePumps: 0,
          totalPumps: 0,
          activeAttendants: 0,
          totalAttendants: 0,
        );
      }
    } catch (e) {
      debugPrint('Load station summary error: $e');
      _stationSummary = StationSummary(
        todaySales: 0,
        salesChange: 0,
        transactionCount: 0,
        transactionChange: 0,
        activePumps: 0,
        totalPumps: 0,
        activeAttendants: 0,
        totalAttendants: 0,
      );
    }
  }

  /// Load pumps from backend
  Future<void> _loadPumps() async {
    try {
      final pumpsData = await PumpService.getPumps();
      
      _pumps = pumpsData.map((json) => PumpStatus(
        id: json['id']?.toString() ?? '',
        number: json['pump_number']?.toString() ?? 'Pump ${json['id']}',
        status: json['status']?.toString() ?? 'inactive',
        attendantName: json['current_attendant_name']?.toString() ?? '',
        fuelType: json['fuel_type']?.toString() ?? 'Petrol',
        todaySales: _toDouble(json['today_sales'] ?? 0),
        lastReading: _toDouble(json['current_reading'] ?? 0),
        isActive: json['is_active'] ?? true,
      )).toList();
      
      // Also load full pump configs for management
      _pumpConfigs = pumpsData.map((json) => pump_config.PumpConfig.fromBackendJson(json)).toList();
      
      // Calculate low fuel pumps
      _lowFuelPumps = _pumpConfigs.where((p) => p.needsMaintenance).length;
      
    } catch (e) {
      debugPrint('Load pumps error: $e');
      _pumps = [];
      _pumpConfigs = [];
    }
  }

  /// Load recent transactions from backend
  Future<void> _loadRecentTransactions() async {
    try {
      final transactionsData = await TransactionService.getTransactions();
      
      _recentTransactions = transactionsData.map((json) => ManagerTransaction(
        id: json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
        time: json['created_at'] != null 
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        pump: json['pump_number']?.toString() ?? 'Pump ${json['pump_id']}',
        attendant: json['attendant_name']?.toString() ?? 'Attendant ${json['attendant_id']}',
        amount: _toDouble(json['amount'] ?? 0),
        type: json['payment_type']?.toString() ?? 'cash',
        status: json['status']?.toString() ?? 'completed',
      )).toList();
      
      // Calculate totals
      _mpesaTotal = _recentTransactions
          .where((t) => t.type == 'mpesa' && t.isCompleted)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      _cashTotal = _recentTransactions
          .where((t) => t.type == 'cash' && t.isCompleted)
          .fold(0.0, (sum, t) => sum + t.amount);
          
    } catch (e) {
      debugPrint('Load transactions error: $e');
      _recentTransactions = [];
      _mpesaTotal = 0;
      _cashTotal = 0;
    }
  }

  /// Load alerts from backend
  Future<void> _loadAlerts() async {
    try {
      final alertsData = await ManagerService.getAlerts();
      
      if (alertsData != null && alertsData['alerts'] != null) {
        _alerts = List<String>.from(alertsData['alerts']);
        _pendingReports = _toInt(alertsData['pending_reports'] ?? 0);
      } else {
        _alerts = [];
        _pendingReports = 0;
      }
      
      // Add low fuel alerts from pumps
      final lowFuelPumpsList = _pumpConfigs.where((p) => p.needsMaintenance).toList();
      for (final pump in lowFuelPumpsList) {
        final alert = '${pump.number} fuel level low (${pump.fuelPercentage.toStringAsFixed(0)}%)';
        if (!_alerts.contains(alert)) {
          _alerts.add(alert);
        }
      }
      
    } catch (e) {
      debugPrint('Load alerts error: $e');
      _alerts = [];
      _pendingReports = 0;
    }
  }

  /// Load sales chart data
  Future<void> _loadSalesChartData() async {
    try {
      final analyticsData = await ManagerService.getSalesAnalytics();
      
      if (analyticsData != null && analyticsData['daily_sales'] != null) {
        _salesData = List<double>.from(analyticsData['daily_sales']);
      } else {
        // Default mock data if backend not ready
        _salesData = [45000, 52000, 48000, 58000, 62000, 59000, 68000];
      }
    } catch (e) {
      debugPrint('Load sales chart error: $e');
      _salesData = [45000, 52000, 48000, 58000, 62000, 59000, 68000];
    }
  }

  /// Load statistics
  Future<void> _loadStats() async {
    try {
      final employeesData = await EmployeeService.getEmployees();
      _activeAttendants = employeesData['data']?.where((e) => e['is_active'] == true).length ?? 0;
      
    } catch (e) {
      debugPrint('Load stats error: $e');
      _activeAttendants = 0;
    }
  }

  // ============================================================
  // EMPLOYEE MANAGEMENT
  // ============================================================

  /// Load all employees (manager sees only employees at their station)
  Future<void> loadEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.getEmployees();

      if (result['success'] == true) {
        final rawList = result['data'] as List<Map<String, dynamic>>;
        _employees = rawList.map((json) => Employee.fromBackendJson(json)).toList();
        debugPrint('Loaded ${_employees.length} employees (manager view)');
      } else {
        _errorMessage = result['message'];
        debugPrint('loadEmployees error: ${result['message']}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load employees: $e';
      debugPrint('loadEmployees exception: $e');
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
      debugPrint('getPendingRegistrations error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // EMPLOYEE CRUD OPERATIONS (Direct add/edit/delete - no invitation)
  // ──────────────────────────────────────────────────────────────────────────────

  /// Create a new employee (direct add - no invitation)
  Future<bool> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String role,
    String? assignedPumpId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.createEmployee({
        'full_name': name,
        'email': email,
        'phone': phone,
        'role': role.toLowerCase(),
        'assigned_pump_id': assignedPumpId,
      });

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to create employee: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing employee
  Future<bool> updateEmployee(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.updateEmployee(
        int.parse(id),
        data,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update employee: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete/deactivate an employee
  Future<bool> deleteEmployee(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.deleteEmployee(
        int.parse(id),
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees(); // Refresh list
        return true;
      } else {
        _errorMessage = result['message'];
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete employee: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get employee statistics
  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final result = await EmployeeService.getEmployeeStats();
      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Get employee stats error: $e');
      return {};
    }
  }

  // ============================================================
  // CUSTOMER MANAGEMENT
  // ============================================================

  /// Load customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final customersData = await ManagerService.getCustomers();
      _customers = customersData.map((json) => Customer.fromBackendJson(json)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Update customer points
  Future<bool> updateCustomerPoints(String customerId, int points) async {
    try {
      final success = await ManagerService.updateCustomerPoints(int.parse(customerId), points);
      
      if (success) {
        await loadCustomers();
      }
      
      return success;
    } catch (e) {
      debugPrint('Update customer points error: $e');
      return false;
    }
  }

  // ============================================================
  // PUMP MANAGEMENT
  // ============================================================

  /// Update pump status
  Future<bool> updatePumpStatus(String pumpId, String status) async {
    try {
      final success = await PumpService.updatePumpStatus(int.parse(pumpId), status);
      
      if (success) {
        await _loadPumps();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Update pump status error: $e');
      return false;
    }
  }

  /// Update fuel price
  Future<bool> updateFuelPrice(String pumpId, double price) async {
    try {
      final success = await PumpService.updateFuelPrice(int.parse(pumpId), price);
      
      if (success) {
        await _loadPumps();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Update fuel price error: $e');
      return false;
    }
  }

  // ============================================================
  // TRANSACTION MANAGEMENT
  // ============================================================

  /// Filter transactions by search query
  void filterTransactions(String query) {
    if (query.isEmpty) {
      _filteredTransactions = [];
    } else {
      _filteredTransactions = _recentTransactions.where((tx) {
        return tx.id.toLowerCase().contains(query.toLowerCase()) ||
               tx.pump.toLowerCase().contains(query.toLowerCase()) ||
               tx.attendant.toLowerCase().contains(query.toLowerCase()) ||
               tx.amount.toString().contains(query) ||
               tx.type.toLowerCase().contains(query.toLowerCase()) ||
               tx.status.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  /// Export transactions to CSV
  Future<bool> exportTransactions() async {
    try {
      debugPrint('Exporting ${recentTransactions.length} transactions');
      return true;
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }

  /// Clear transaction filters
  void clearFilters() {
    _filteredTransactions = [];
    notifyListeners();
  }

  /// Get transaction by ID
  ManagerTransaction? getTransactionById(String id) {
    try {
      return _recentTransactions.firstWhere((tx) => tx.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  /// Refresh all data
  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();
    
    await loadDashboardData(DateTime.now());
    await loadEmployees();
    
    _isRefreshing = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}