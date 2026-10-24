// lib/core/services/manager_service.dart
//
// Manager service with all endpoints connected to existing backend routes.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ManagerService {
  // ─────────────────────────────────────────────
  // DEPENDENCY INJECTION
  // ─────────────────────────────────────────────
  final ApiService _apiService;

  ManagerService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ─────────────────────────────────────────────
  // MANAGER DASHBOARD
  // ─────────────────────────────────────────────

  /// GET /api/manager/dashboard
  /// Returns: today_sales, sales_change, transaction_count,
  ///   transaction_change, active_pumps, total_pumps,
  ///   active_attendants, total_attendants
  Future<Map<String, dynamic>?> getManagerDashboard() async {
    try {
      final response = await _apiService.get('/manager/dashboard');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getManagerDashboard error: ${response['message']}');
    } catch (e) {
      debugPrint('getManagerDashboard exception: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // ALERTS
  // ─────────────────────────────────────────────

  /// GET /api/manager/alerts
  /// Returns: { alerts: [...], pending_reports: N }
  Future<Map<String, dynamic>?> getAlerts() async {
    try {
      final response = await _apiService.get('/manager/alerts');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getAlerts error: ${response['message']}');
    } catch (e) {
      debugPrint('getAlerts exception: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // SALES ANALYTICS
  // ─────────────────────────────────────────────

  /// GET /api/manager/analytics/sales
  /// Returns: { daily_sales: [double, ...] } — 7 days
  Future<Map<String, dynamic>?> getSalesAnalytics() async {
    try {
      final response = await _apiService.get('/manager/analytics/sales');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getSalesAnalytics error: ${response['message']}');
    } catch (e) {
      debugPrint('getSalesAnalytics exception: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // QUICK STATS
  // ─────────────────────────────────────────────

  /// GET /api/manager/quick-stats
  /// Returns: { activeAttendants, pendingReports, lowFuelPumps, totalSales }
  Future<Map<String, dynamic>?> getQuickStats() async {
    try {
      final response = await _apiService.get('/manager/quick-stats');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getQuickStats error: ${response['message']}');
    } catch (e) {
      debugPrint('getQuickStats exception: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // EMPLOYEES
  // ─────────────────────────────────────────────

  /// GET /api/employees
  /// Returns list of employee objects
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await _apiService.get('/employees');

      if (response['success'] == true) {
        // Backend returns { success, data: [...] }
        final raw = response['data'] ?? [];
        return List<Map<String, dynamic>>.from(raw);
      }
      debugPrint('getEmployees error: ${response['message']}');
    } catch (e) {
      debugPrint('getEmployees exception: $e');
    }
    return [];
  }

  /// GET /api/employees/:id
  /// Returns single employee
  Future<Map<String, dynamic>?> getEmployeeById(int employeeId) async {
    try {
      final response = await _apiService.get('/employees/$employeeId');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getEmployeeById error: ${response['message']}');
    } catch (e) {
      debugPrint('getEmployeeById exception: $e');
    }
    return null;
  }

  /// POST /api/employees (direct add - no invitation)
  Future<Map<String, dynamic>?> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final response = await _apiService.post('/employees', employeeData);

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('createEmployee error: ${response['message']}');
    } catch (e) {
      debugPrint('createEmployee exception: $e');
    }
    return null;
  }

  /// PUT /api/employees/:id
  Future<bool> updateEmployee(
    int employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/employees/$employeeId', data);
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateEmployee exception: $e');
      return false;
    }
  }

  /// DELETE /api/employees/:id
  Future<bool> deleteEmployee(int employeeId) async {
    try {
      final response = await _apiService.delete('/employees/$employeeId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('deleteEmployee exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // CUSTOMERS
  // ─────────────────────────────────────────────

  /// GET /api/customers
  /// Returns list of customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await _apiService.get('/customers');

      if (response['success'] == true) {
        // Backend returns { success, data: [...] }
        final raw = response['data'] ?? [];
        return List<Map<String, dynamic>>.from(raw);
      }
      debugPrint('getCustomers error: ${response['message']}');
    } catch (e) {
      debugPrint('getCustomers exception: $e');
    }
    return [];
  }

  /// GET /api/customers/:id
  /// Returns single customer
  Future<Map<String, dynamic>?> getCustomerById(int customerId) async {
    try {
      final response = await _apiService.get('/customers/$customerId');

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('getCustomerById error: ${response['message']}');
    } catch (e) {
      debugPrint('getCustomerById exception: $e');
    }
    return null;
  }

  /// POST /api/customers
  Future<Map<String, dynamic>?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await _apiService.post('/customers', customerData);

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('createCustomer error: ${response['message']}');
    } catch (e) {
      debugPrint('createCustomer exception: $e');
    }
    return null;
  }

  /// PUT /api/customers/:id
  Future<bool> updateCustomer(
    int customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/customers/$customerId', data);
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateCustomer exception: $e');
      return false;
    }
  }

  /// PUT /api/customers/:id/points
  Future<bool> updateCustomerPoints(
    int customerId,
    int points,
  ) async {
    try {
      final response = await _apiService.put(
        '/customers/$customerId/points',
        {'points': points},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateCustomerPoints exception: $e');
      return false;
    }
  }

  /// POST /api/customers/:id/redeem
  Future<bool> redeemCustomerPoints(
    int customerId,
    int points,
  ) async {
    try {
      final response = await _apiService.post(
        '/customers/$customerId/redeem',
        {'points': points},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('redeemCustomerPoints exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // EXPENSES (Manager endpoints)
  // ─────────────────────────────────────────────

  /// GET /api/manager/expenses
  ///
  /// ⚠️ IMPORTANT: expenseController.js's getExpenses returns
  /// { success, data: [...], total: N } — `data` IS the array of
  /// expenses directly, and `total` is a sibling key.
  ///
  /// ⚠️ The response from POST/PUT returns `RETURNING *` from the
  /// database, which means `amount` comes as a STRING because it's
  /// a DECIMAL column that wasn't parseFloat'd. Use Expense.fromBackendJson()
  /// which handles both response shapes.
  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final response = await _apiService.get('/manager/expenses');

      if (response['success'] == true) {
        final raw = response['data'] as List? ?? [];
        return List<Map<String, dynamic>>.from(raw);
      }
      debugPrint('getExpenses error: ${response['message']}');
    } catch (e) {
      debugPrint('getExpenses exception: $e');
    }
    return [];
  }

  /// Total count of expenses matching the last query, from the
  /// response's top-level `total` field (sibling of `data`, not
  /// nested inside it). Optional convenience if the expense screen
  /// wants pagination info; safe to ignore if not needed.
  Future<int> getExpensesTotal({
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String>[];
      if (category != null) params.add('category=$category');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await _apiService.get('/manager/expenses$query');

      if (response['success'] == true) {
        return (response['total'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('getExpensesTotal exception: $e');
    }
    return 0;
  }

  /// POST /api/manager/expenses
  ///
  /// ⚠️ The response from this endpoint is the raw `RETURNING *` from
  /// PostgreSQL. This means:
  /// - `amount` comes as a STRING (DECIMAL column)
  /// - Keys are `snake_case` (expense_date, vendor_name, etc.)
  ///
  /// ✅ Use Expense.fromBackendJson() to parse the response safely.
  Future<Map<String, dynamic>?> createExpense(
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final response = await _apiService.post('/manager/expenses', expenseData);

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
      debugPrint('createExpense error: ${response['message']}');
    } catch (e) {
      debugPrint('createExpense exception: $e');
    }
    return null;
  }

  /// PUT /api/manager/expenses/:id
  ///
  /// ⚠️ Similar to POST, the response is raw `RETURNING *` from
  /// PostgreSQL with `snake_case` keys and `amount` as String.
  ///
  /// ✅ Use Expense.fromBackendJson() to parse the response safely.
  Future<bool> updateExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        '/manager/expenses/$expenseId',
        data,
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('updateExpense exception: $e');
      return false;
    }
  }

  /// DELETE /api/manager/expenses/:id
  Future<bool> deleteExpense(String expenseId) async {
    try {
      final response = await _apiService.delete(
        '/manager/expenses/$expenseId',
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('deleteExpense exception: $e');
      return false;
    }
  }

  /// GET /api/manager/expenses/categories
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      final response = await _apiService.get('/manager/expenses/categories');

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      debugPrint('getExpenseCategories error: ${response['message']}');
    } catch (e) {
      debugPrint('getExpenseCategories exception: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  /// Clean up resources if needed
  void dispose() {
    // If ApiService has resources to clean up, call them here
    // _apiService.dispose();
  }
}