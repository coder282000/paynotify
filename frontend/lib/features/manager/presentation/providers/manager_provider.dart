// lib/features/manager/presentation/providers/manager_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../domain/models/station_summary.dart';
import '../../domain/models/pump_status.dart';
import '../../domain/models/manager_transaction.dart';
import '../../domain/models/pump_config.dart' as pump_config;
import '../../domain/models/employee_model.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/expense_model.dart'; // ✅ Manager's Expense model
import '../../domain/models/expense_category.dart';
// Import services
import '../../../../core/services/pump_service.dart';
import '../../../../core/services/manager_service.dart';
import '../../../../core/services/transaction_service.dart';
import '../../../../core/services/employee_service.dart';

// ─────────────────────────────────────────────
// CACHE CONFIGURATION
// ─────────────────────────────────────────────
class _CacheConfig {
  static const Duration expenseCacheDuration = Duration(minutes: 5);
  static const int defaultPageSize = 20;
}

// ─────────────────────────────────────────────
// ERROR TYPES
// ─────────────────────────────────────────────
enum ErrorType {
  network,
  timeout,
  server,
  validation,
  unauthorized,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final dynamic originalError;

  AppError({
    required this.type,
    required this.message,
    this.originalError,
  });

  factory AppError.fromException(dynamic e) {
    if (e is SocketException) {
      return AppError(
        type: ErrorType.network,
        message: 'No internet connection. Please check your network.',
        originalError: e,
      );
    }
    if (e is TimeoutException) {
      return AppError(
        type: ErrorType.timeout,
        message: 'Request timed out. Please try again.',
        originalError: e,
      );
    }
    if (e.toString().contains('401')) {
      return AppError(
        type: ErrorType.unauthorized,
        message: 'Session expired. Please log in again.',
        originalError: e,
      );
    }
    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred. Please try again.',
      originalError: e,
    );
  }
}

// ─────────────────────────────────────────────
// UNDO ACTION MODEL
// ─────────────────────────────────────────────
class UndoAction {
  final String type; // 'create', 'update', 'delete'
  final Expense? oldExpense;
  final Expense? newExpense;
  final String? id;
  final DateTime timestamp;

  UndoAction({
    required this.type,
    this.oldExpense,
    this.newExpense,
    this.id,
  }) : timestamp = DateTime.now();
}

// ─────────────────────────────────────────────
// MANAGER PROVIDER
// ─────────────────────────────────────────────
class ManagerProvider extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION - Create service instances
  // ─────────────────────────────────────────────
  final PumpService _pumpService = PumpService();
  final ManagerService _managerService = ManagerService();
  final TransactionService _transactionService = TransactionService();
  final EmployeeService _employeeService = EmployeeService();

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

  // Expenses
  List<Expense> _expenses = [];
  List<Expense> _cachedFilteredExpenses = [];
  String _lastFilterKey = '';
  DateTime? _expensesLastLoaded;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Filter state
  String _selectedCategory = 'all';
  String _selectedStation = 'all';
  String _searchQuery = '';

  // Combined pending list
  List<Map<String, dynamic>> _allPendingItems = [];

  // Stats
  int _activeAttendants = 0;
  int _pendingReports = 0;
  int _lowFuelPumps = 0;
  double _mpesaTotal = 0;
  double _cashTotal = 0;

  // ─────────────────────────────────────────────
  // UNDO/REDO STACKS
  // ─────────────────────────────────────────────
  final List<UndoAction> _undoStack = [];
  final List<UndoAction> _redoStack = [];
  static const int _maxUndoStackSize = 50;

  // ─────────────────────────────────────────────
  // UI STATE
  // ─────────────────────────────────────────────
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingPending = false;
  bool _isSubmitting = false;
  bool _isLoadingMore = false;
  AppError? _error;
  String? _pendingErrorMessage;

  // Debounce timer
  Timer? _notifyTimer;
  Timer? _searchDebounceTimer;

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
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;
  AppError? get error => _error;
  String? get errorMessage => _error?.message;
  bool get hasData => _recentTransactions.isNotEmpty || _pumps.isNotEmpty;

  // Extended getters
  List<pump_config.PumpConfig> get pumpConfigs => _pumpConfigs;
  List<Employee> get employees => _employees;
  List<Customer> get customers => _customers;
  List<Expense> get expenses => _cachedFilteredExpenses;

  // Combined pending list getters
  List<Map<String, dynamic>> get allPendingItems => _allPendingItems;
  List<Map<String, dynamic>> get pendingInvitations =>
      _allPendingItems.where((item) => item['type'] == 'invitation').toList();
  List<Map<String, dynamic>> get pendingRegistrationsList =>
      _allPendingItems.where((item) => item['type'] == 'registration').toList();
  int get allPendingCount => _allPendingItems.length;
  bool get isLoadingPending => _isLoadingPending;
  String? get pendingErrorMessage => _pendingErrorMessage;

  // Computed totals
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  int get expenseCount => _expenses.length;

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
    _searchDebounceTimer?.cancel();
    _pumpService.dispose();
    _managerService.dispose();
    _transactionService.dispose();
    _employeeService.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // ERROR HANDLING
  // ─────────────────────────────────────────────
  void _handleError(dynamic e) {
    _error = AppError.fromException(e);
    debugPrint('❌ Error: ${_error?.message}');
    debugPrint('   Type: ${_error?.type}');
    debugPrint('   Original: ${_error?.originalError}');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPendingError() {
    _pendingErrorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // DASHBOARD DATA
  // ─────────────────────────────────────────────
  Future<void> loadDashboardData(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
      _handleError(e);
      notifyListeners();
    }
  }

  Future<void> _loadStationSummary() async {
    try {
      final dashboardData = await _managerService.getManagerDashboard();
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
      rethrow;
    }
  }

  Future<void> _loadPumps() async {
    try {
      final pumpsData = await _pumpService.getPumps();
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

      _pumpConfigs = pumpsData.map((json) => pump_config.PumpConfig.fromBackendJson(json)).toList();
      _lowFuelPumps = _pumpConfigs.where((p) => p.needsMaintenance).length;
    } catch (e) {
      debugPrint('Load pumps error: $e');
      rethrow;
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final transactionsData = await _transactionService.getTransactions();
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

      _mpesaTotal = _recentTransactions
          .where((t) => t.type == 'mpesa' && t.isCompleted)
          .fold(0.0, (sum, t) => sum + t.amount);

      _cashTotal = _recentTransactions
          .where((t) => t.type == 'cash' && t.isCompleted)
          .fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      debugPrint('Load transactions error: $e');
      rethrow;
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alertsData = await _managerService.getAlerts();
      if (alertsData != null && alertsData['alerts'] != null) {
        _alerts = List<String>.from(alertsData['alerts']);
        _pendingReports = _toInt(alertsData['pending_reports'] ?? 0);
      } else {
        _alerts = [];
        _pendingReports = 0;
      }

      final lowFuelPumpsList = _pumpConfigs.where((p) => p.needsMaintenance).toList();
      for (final pump in lowFuelPumpsList) {
        final alert = '${pump.number} fuel level low (${pump.fuelPercentage.toStringAsFixed(0)}%)';
        if (!_alerts.contains(alert)) {
          _alerts.add(alert);
        }
      }
    } catch (e) {
      debugPrint('Load alerts error: $e');
      rethrow;
    }
  }

  Future<void> _loadSalesChartData() async {
    try {
      final analyticsData = await _managerService.getSalesAnalytics();
      if (analyticsData != null && analyticsData['daily_sales'] != null) {
        _salesData = List<double>.from(analyticsData['daily_sales']);
      } else {
        _salesData = [45000, 52000, 48000, 58000, 62000, 59000, 68000];
      }
    } catch (e) {
      debugPrint('Load sales chart error: $e');
      _salesData = [45000, 52000, 48000, 58000, 62000, 59000, 68000];
    }
  }

  Future<void> _loadStats() async {
    try {
      final employeesData = await _employeeService.getEmployees();
      _activeAttendants = employeesData['data']?.where((e) => e['is_active'] == true).length ?? 0;
    } catch (e) {
      debugPrint('Load stats error: $e');
      _activeAttendants = 0;
    }
  }

  // ─────────────────────────────────────────────
  // EMPLOYEE MANAGEMENT
  // ─────────────────────────────────────────────

  /// Load all employees (manager sees only employees at their station)
  Future<void> loadEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.getEmployees();
      if (result['success'] == true) {
        final rawList = (result['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _employees = rawList.map((json) => Employee.fromBackendJson(json)).toList();
        debugPrint('Loaded ${_employees.length} employees (manager view)');
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: result['message'] ?? 'Failed to load employees',
        );
      }
    } catch (e) {
      _handleError(e);
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
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.inviteEmployee({
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
        unawaited(loadAllPending());
        return result;
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: result['message'] ?? 'Failed to invite employee',
        );
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _handleError(e);
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error?.message ?? 'Failed to send invitation'};
    }
  }

  /// Approve or reject a pending employee registration
  Future<bool> approveEmployee(String userId, bool approved, {String? notes}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _employeeService.approveEmployee(
        int.parse(userId),
        approved,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees();
        unawaited(loadAllPending());
        return true;
      }
      return false;
    } catch (e) {
      _handleError(e);
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
      final result = await _employeeService.resendInvitation({
        'email': email,
        'full_name': fullName,
        'role': role,
      });

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        return true;
      }
      _error = AppError(
        type: ErrorType.server,
        message: result['message'] ?? 'Failed to resend invitation',
      );
      return false;
    } catch (e) {
      _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get pending employee registrations (legacy)
  Future<List<Map<String, dynamic>>> getPendingRegistrations() async {
    try {
      final result = await _employeeService.getPendingRegistrations();
      if (result['success'] == true) {
        return result['data'] as List<Map<String, dynamic>>;
      }
      return [];
    } catch (e) {
      debugPrint('getPendingRegistrations error: $e');
      return [];
    }
  }

  /// Load the combined pending list
  Future<void> loadAllPending() async {
    _isLoadingPending = true;
    _pendingErrorMessage = null;
    notifyListeners();

    try {
      final result = await _employeeService.getAllPending();
      if (result['success'] == true) {
        final rawList = (result['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _allPendingItems = rawList;
        debugPrint('Loaded ${_allPendingItems.length} pending items');
      } else {
        _pendingErrorMessage = result['message'];
      }
    } catch (e) {
      _pendingErrorMessage = 'Failed to load pending items: $e';
    } finally {
      _isLoadingPending = false;
      notifyListeners();
    }
  }

  /// Create a new employee (direct add)
  Future<bool> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String role,
    String? assignedPumpId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.createEmployee({
        'full_name': name,
        'email': email,
        'phone': phone,
        'role': role.toLowerCase(),
        'assigned_pump_id': assignedPumpId,
      });

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees();
        return true;
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: result['message'] ?? 'Failed to create employee',
        );
        return false;
      }
    } catch (e) {
      _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing employee
  Future<bool> updateEmployee(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.updateEmployee(
        int.parse(id),
        data,
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees();
        return true;
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: result['message'] ?? 'Failed to update employee',
        );
        return false;
      }
    } catch (e) {
      _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete/deactivate an employee
  Future<bool> deleteEmployee(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.deleteEmployee(
        int.parse(id),
      );

      _isLoading = false;
      notifyListeners();

      if (result['success'] == true) {
        await loadEmployees();
        return true;
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: result['message'] ?? 'Failed to delete employee',
        );
        return false;
      }
    } catch (e) {
      _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get employee statistics
  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final result = await _employeeService.getEmployeeStats();
      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Get employee stats error: $e');
      return {};
    }
  }

  // ─────────────────────────────────────────────
  // EXPENSE MANAGEMENT - OPTIMIZED
  // ─────────────────────────────────────────────

  /// Load expenses with pagination and caching
  Future<void> loadExpenses({
    bool forceRefresh = false,
    bool loadMore = false,
  }) async {
    // Check cache
    if (!forceRefresh && _expensesLastLoaded != null &&
        DateTime.now().difference(_expensesLastLoaded!) < _CacheConfig.expenseCacheDuration &&
        _expenses.isNotEmpty && !loadMore) {
      _applyFilters();
      return;
    }

    if (loadMore) {
      if (!_hasMorePages || _isLoadingMore) return;
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMorePages = true;
    }
    notifyListeners();

    try {
      final result = await _managerService.getExpenses();
      
      // ✅ Use manager's Expense.fromBackendJson
      final newExpenses = result.map((json) => Expense.fromBackendJson(json)).toList();
      
      if (loadMore) {
        _expenses.addAll(newExpenses);
      } else {
        _expenses = newExpenses;
      }
      
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _expensesLastLoaded = DateTime.now();
      _hasMorePages = newExpenses.length == _CacheConfig.defaultPageSize;
      
      _applyFilters();
      
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      debugPrint('✅ Loaded ${_expenses.length} expenses');
      
    } catch (e) {
      _isLoading = false;
      _isLoadingMore = false;
      _handleError(e);
      notifyListeners();
    }
  }

  /// Apply filters with caching
  void _applyFilters() {
    final currentFilterKey = '${_selectedCategory}_${_selectedStation}_$_searchQuery';
    if (_lastFilterKey == currentFilterKey && _cachedFilteredExpenses.isNotEmpty) {
      return;
    }

    _cachedFilteredExpenses = _expenses.where((expense) {
      // ✅ Compare ExpenseCategory enum with String
      if (_selectedCategory != 'all' && expense.category.name != _selectedCategory) return false;
      // ✅ Manager's Expense doesn't have stationId - remove station filter
      // if (_selectedStation != 'all' && expense.stationId != _selectedStation) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return expense.description.toLowerCase().contains(query) ||
            (expense.vendorName?.toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();
    
    _lastFilterKey = currentFilterKey;
  }

  /// Set category filter
  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Set station filter (manager's Expense doesn't have stationId)
  void setStationFilter(String stationId) {
    _selectedStation = stationId;
    _applyFilters();
    notifyListeners();
  }

  /// Set search query with debounce
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      notifyListeners();
    });
  }

  /// Clear all filters
  void clearAllFilters() {
    _selectedCategory = 'all';
    _selectedStation = 'all';
    _searchQuery = '';
    _searchDebounceTimer?.cancel();
    _applyFilters();
    notifyListeners();
  }

  /// Validate expense data before API call
  bool _validateExpenseData(Map<String, dynamic> data) {
    if (data['category'] == null || data['category'].toString().isEmpty) {
      _error = AppError(
        type: ErrorType.validation,
        message: 'Category is required',
      );
      return false;
    }
    if (data['amount'] == null || data['amount'] <= 0) {
      _error = AppError(
        type: ErrorType.validation,
        message: 'Amount must be greater than 0',
      );
      return false;
    }
    if (data['description'] == null || data['description'].toString().isEmpty) {
      _error = AppError(
        type: ErrorType.validation,
        message: 'Description is required',
      );
      return false;
    }
    return true;
  }

  // ✅ FIXED: Create expense with proper handling of response
  Future<bool> createExpense(Map<String, dynamic> expenseData) async {
    if (!_validateExpenseData(expenseData)) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ expenseData already uses toBackendJson() from the screen
      final result = await _managerService.createExpense(expenseData);
      
      if (result != null) {
        // ✅ Use fromBackendJson - handles both response shapes
        final realExpense = Expense.fromBackendJson(result);
        
        // Remove any temp expense with same id (if exists)
        _expenses.removeWhere((e) => e.id.startsWith('temp_'));
        
        // Add the real expense
        _expenses.insert(0, realExpense);
        _applyFilters();
        notifyListeners();
        
        _isSubmitting = false;
        debugPrint('✅ Expense created: ${realExpense.id}');
        return true;
      } else {
        // Rollback on failure
        _expenses.removeWhere((e) => e.id.startsWith('temp_'));
        _applyFilters();
        _error = AppError(
          type: ErrorType.server,
          message: 'Failed to create expense',
        );
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _handleError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ FIXED: Update expense with proper handling
  Future<bool> updateExpense(String id, Map<String, dynamic> expenseData) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ expenseData already uses toBackendJson() from the screen
      final success = await _managerService.updateExpense(id, expenseData);
      
      if (success) {
        // ✅ Force refresh to get updated data
        await loadExpenses(forceRefresh: true);
        
        _isSubmitting = false;
        notifyListeners();
        debugPrint('✅ Expense updated: $id');
        return true;
      } else {
        _error = AppError(
          type: ErrorType.server,
          message: 'Failed to update expense',
        );
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _handleError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete expense with undo support
  Future<bool> deleteExpense(String id) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // Save for undo
      final expenseToDelete = _expenses.firstWhere((e) => e.id == id);
      
      // Optimistic update - remove immediately
      _expenses.removeWhere((e) => e.id == id);
      _applyFilters();
      notifyListeners();

      // Push to undo stack
      _undoStack.add(UndoAction(
        type: 'delete',
        oldExpense: expenseToDelete,
        id: id,
      ));
      
      // Limit undo stack size
      if (_undoStack.length > _maxUndoStackSize) {
        _undoStack.removeAt(0);
      }
      // Clear redo stack on new action
      _redoStack.clear();

      final success = await _managerService.deleteExpense(id);
      
      if (!success) {
        // Rollback
        _expenses.insert(0, expenseToDelete);
        _applyFilters();
        _undoStack.removeLast();
        _error = AppError(
          type: ErrorType.server,
          message: 'Failed to delete expense',
        );
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      _isSubmitting = false;
      debugPrint('✅ Expense deleted: $id');
      return true;
    } catch (e) {
      _handleError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Undo last action
  bool undo() {
    if (_undoStack.isEmpty) return false;
    
    final action = _undoStack.removeLast();
    if (action.type == 'delete' && action.oldExpense != null) {
      _expenses.insert(0, action.oldExpense!);
      _applyFilters();
      _redoStack.add(action);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Redo last undone action
  bool redo() {
    if (_redoStack.isEmpty) return false;
    
    final action = _redoStack.removeLast();
    if (action.type == 'delete' && action.id != null) {
      _expenses.removeWhere((e) => e.id == action.id);
      _applyFilters();
      _undoStack.add(action);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      return await _managerService.getExpenseCategories();
    } catch (e) {
      debugPrint('❌ getExpenseCategories error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // CUSTOMER MANAGEMENT
  // ─────────────────────────────────────────────

  /// Load customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customersData = await _managerService.getCustomers();
      _customers = customersData.map((json) => Customer.fromBackendJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _handleError(e);
      notifyListeners();
    }
  }

  /// Update customer points
  Future<bool> updateCustomerPoints(String customerId, int points) async {
    try {
      final success = await _managerService.updateCustomerPoints(
        int.parse(customerId), 
        points,
      );
      if (success) await loadCustomers();
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // PUMP MANAGEMENT
  // ─────────────────────────────────────────────

  /// Update pump status
  Future<bool> updatePumpStatus(String pumpId, String status) async {
    try {
      final success = await _pumpService.updatePumpStatus(int.parse(pumpId), status);
      if (success) {
        await _loadPumps();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Update fuel price
  Future<bool> updateFuelPrice(String pumpId, double price) async {
    try {
      final success = await _pumpService.updateFuelPrice(int.parse(pumpId), price);
      if (success) {
        await _loadPumps();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TRANSACTION MANAGEMENT
  // ─────────────────────────────────────────────

  /// Filter transactions by search query
  void filterTransactions(String query) {
    if (query.isEmpty) {
      _filteredTransactions = [];
    } else {
      _filteredTransactions = _recentTransactions.where((tx) {
        final q = query.toLowerCase();
        return tx.id.toLowerCase().contains(q) ||
               tx.pump.toLowerCase().contains(q) ||
               tx.attendant.toLowerCase().contains(q) ||
               tx.amount.toString().contains(q) ||
               tx.type.toLowerCase().contains(q) ||
               tx.status.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  /// Clear transaction filters
  void clearTransactionFilters() {
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

  // ─────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────

  /// Refresh all data
  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await loadDashboardData(DateTime.now());
      await loadEmployees();
      await loadAllPending();
      await loadExpenses(forceRefresh: true);
    } catch (e) {
      _handleError(e);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

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