// lib/features/manager/presentation/screens/expense_tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/models/expense_category.dart';
import '../widgets/expense_card.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/expense_filter_bar.dart';
import '../widgets/expense_category_chart.dart';

// MARK: - Constants
class _ExpenseConstants {
  static const Color primaryDark = Color(0xFF0B3D2E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color profitGreen = Color(0xFF27AE60);
  static const Color lossRed = Color(0xFFE74C3C);
  
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
}

// MARK: - Revenue Model
class RevenueRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String source;
  final String? description;
  final String recordedBy;

  RevenueRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.source,
    this.description,
    required this.recordedBy,
  });
}

// MARK: - Financial Summary Model
class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final bool isProfitable;
  final Map<ExpenseCategory, double> categoryExpenses;
  final Map<ExpenseCategory, double> categoryChanges;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.isProfitable,
    required this.categoryExpenses,
    required this.categoryChanges,
  });
}

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isFilterExpanded = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Expense data
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  
  // Revenue data
  List<RevenueRecord> _revenues = [];
  List<RevenueRecord> _filteredRevenues = [];
  
  // Filter properties
  DateTimeRange? _selectedDateRange;
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExpenses();
    _loadRevenues();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // MARK: - Data Loading
  Future<void> _loadExpenses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(_ExpenseConstants.animationDuration);
      
      if (!mounted) return;
      
      _expenses = _generateMockExpenses();
      _applyFilters();
      
      setState(() => _isLoading = false);
      
      HapticFeedback.lightImpact();
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      debugPrint('Load expenses error: $e\n$stackTrace');
      
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      
      _showErrorSnackBar();
    }
  }

  Future<void> _loadRevenues() async {
    _revenues = _generateMockRevenues();
    _applyRevenueFilters();
  }

  List<RevenueRecord> _generateMockRevenues() {
    final now = DateTime.now();
    return [
      RevenueRecord(
        id: 'rev1',
        amount: 450000,
        date: now.subtract(const Duration(days: 1)),
        source: 'Fuel Sales',
        description: 'Daily fuel sales',
        recordedBy: 'Manager',
      ),
      RevenueRecord(
        id: 'rev2',
        amount: 380000,
        date: now.subtract(const Duration(days: 2)),
        source: 'Fuel Sales',
        description: 'Daily fuel sales',
        recordedBy: 'Manager',
      ),
      RevenueRecord(
        id: 'rev3',
        amount: 520000,
        date: now.subtract(const Duration(days: 3)),
        source: 'Fuel Sales',
        description: 'Daily fuel sales',
        recordedBy: 'Manager',
      ),
      RevenueRecord(
        id: 'rev4',
        amount: 15000,
        date: now.subtract(const Duration(days: 5)),
        source: 'Convenience Store',
        description: 'Shop sales',
        recordedBy: 'Manager',
      ),
      RevenueRecord(
        id: 'rev5',
        amount: 5000,
        date: now.subtract(const Duration(days: 7)),
        source: 'Car Wash',
        description: 'Car wash services',
        recordedBy: 'Manager',
      ),
    ];
  }

  List<Expense> _generateMockExpenses() {
    final now = DateTime.now();
    return [
      Expense(
        id: '1',
        category: ExpenseCategory.fuelPurchase,
        amount: 50000,
        description: 'Fuel stock purchase',
        date: now.subtract(const Duration(days: 2)),
        vendorName: 'Total Energies',
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'INV-2024001',
        createdBy: 'Manager',
        createdAt: now,
      ),
      Expense(
        id: '2',
        category: ExpenseCategory.salary,
        amount: 150000,
        description: 'Staff monthly salaries',
        date: now.subtract(const Duration(days: 5)),
        vendorName: 'Staff',
        paymentMethod: 'Bank Transfer',
        createdBy: 'Manager',
        createdAt: now,
      ),
      Expense(
        id: '3',
        category: ExpenseCategory.maintenance,
        amount: 15000,
        description: 'Pump 3 calibration',
        date: now.subtract(const Duration(days: 12)),
        vendorName: 'PumpTech Services',
        paymentMethod: 'M-Pesa',
        referenceNumber: 'MPESA-ABC123',
        createdBy: 'Manager',
        createdAt: now,
      ),
      Expense(
        id: '4',
        category: ExpenseCategory.utilities,
        amount: 25000,
        description: 'Electricity bill',
        date: now.subtract(const Duration(days: 8)),
        vendorName: 'KPLC',
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'ELEC-2024-001',
        createdBy: 'Manager',
        createdAt: now,
      ),
      Expense(
        id: '5',
        category: ExpenseCategory.rent,
        amount: 100000,
        description: 'Monthly station rent',
        date: now.subtract(const Duration(days: 2)),
        vendorName: 'Landlord',
        paymentMethod: 'Bank Transfer',
        createdBy: 'Manager',
        createdAt: now,
      ),
      Expense(
        id: '6',
        category: ExpenseCategory.supplies,
        amount: 8000,
        description: 'Office supplies',
        date: now.subtract(const Duration(days: 3)),
        vendorName: 'Stationery World',
        paymentMethod: 'Cash',
        createdBy: 'Manager',
        createdAt: now,
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        if (_selectedDateRange != null) {
          if (expense.date.isBefore(_selectedDateRange!.start) ||
              expense.date.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }
        
        if (_selectedCategory != null && expense.category != _selectedCategory) {
          return false;
        }
        
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return expense.description.toLowerCase().contains(query) ||
              (expense.vendorName?.toLowerCase().contains(query) ?? false) ||
              expense.category.displayName.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }

  void _applyRevenueFilters() {
    setState(() {
      _filteredRevenues = _revenues.where((revenue) {
        if (_selectedDateRange != null) {
          if (revenue.date.isBefore(_selectedDateRange!.start) ||
              revenue.date.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  // MARK: - Financial Calculations
  double get _totalRevenue {
    return _filteredRevenues.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get _totalExpenses {
    return _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _netProfit {
    return _totalRevenue - _totalExpenses;
  }

  double get _profitMargin {
    if (_totalRevenue == 0) return 0.0;
    return (_netProfit / _totalRevenue) * 100;
  }

  bool get _isProfitable => _netProfit > 0;

  FinancialSummary get _financialSummary {
    return FinancialSummary(
      totalRevenue: _totalRevenue,
      totalExpenses: _totalExpenses,
      netProfit: _netProfit,
      profitMargin: _profitMargin,
      isProfitable: _isProfitable,
      categoryExpenses: _expensesByCategory,
      categoryChanges: _calculateCategoryChanges(),
    );
  }

  Map<ExpenseCategory, double> get _expensesByCategory {
    final map = <ExpenseCategory, double>{};
    for (final expense in _filteredExpenses) {
      map[expense.category] = (map[expense.category] ?? 0.0) + expense.amount;
    }
    return map;
  }

  // Calculate month-over-month expense changes
  Map<ExpenseCategory, double> _calculateCategoryChanges() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    final currentMonthExpenses = _expenses.where((e) => 
      e.date.isAfter(currentMonthStart) || e.date.isAtSameMomentAs(currentMonthStart)
    ).toList();

    final lastMonthExpenses = _expenses.where((e) => 
      e.date.isAfter(lastMonthStart) && e.date.isBefore(lastMonthEnd)
    ).toList();

    final changes = <ExpenseCategory, double>{};
    
    for (final category in ExpenseCategory.values) {
      final currentTotal = currentMonthExpenses
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);
      
      final lastTotal = lastMonthExpenses
          .where((e) => e.category == category)
          .fold(0.0, (sum, e) => sum + e.amount);
      
      final change = lastTotal > 0 
          ? (((currentTotal - lastTotal) / lastTotal) * 100).toDouble()
          : (currentTotal > 0 ? 100.0 : 0.0);
      
      changes[category] = change;
    }
    
    return changes;
  }

  // Get alert for significant expense increases
  List<String> get _expenseIncreaseAlerts {
    final alerts = <String>[];
    final changes = _calculateCategoryChanges();
    
    for (final entry in changes.entries) {
      if (entry.value > 20) {
        alerts.add(
          '⚠️ ${entry.key.displayName} increased by ${entry.value.toStringAsFixed(1)}% compared to last month'
        );
      }
    }
    
    return alerts;
  }

  String? get _warningMessage {
    if (_totalExpenses > 200000) {
      return '⚠️ Total expenses exceed KES 200,000. Please review budget.';
    }
    if (_netProfit < 0 && _totalRevenue > 0) {
      return '⚠️ You are operating at a loss. Please review expenses and revenue.';
    }
    if (_profitMargin < 10 && _totalRevenue > 0) {
      return '⚠️ Profit margin is below 10%. Consider cost reduction strategies.';
    }
    return null;
  }

  double get _averageDailyExpense {
    if (_filteredExpenses.isEmpty) return 0.0;
    final days = _selectedDateRange != null 
        ? _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1
        : 30;
    return days > 0 ? _totalExpenses / days : _totalExpenses;
  }

  double get _averageDailyRevenue {
    if (_filteredRevenues.isEmpty) return 0.0;
    final days = _selectedDateRange != null 
        ? _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1
        : 30;
    return days > 0 ? _totalRevenue / days : _totalRevenue;
  }

  List<Map<String, dynamic>> get _expensesByDay {
    final map = <String, double>{};
    for (final expense in _filteredExpenses) {
      final dayKey = DateFormat('yyyy-MM-dd').format(expense.date);
      map[dayKey] = (map[dayKey] ?? 0.0) + expense.amount;
    }
    return map.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList();
  }

  List<Map<String, dynamic>> get _revenueByDay {
    final map = <String, double>{};
    for (final revenue in _filteredRevenues) {
      final dayKey = DateFormat('yyyy-MM-dd').format(revenue.date);
      map[dayKey] = (map[dayKey] ?? 0.0) + revenue.amount;
    }
    return map.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList();
  }

  // MARK: - Revenue Actions
  void _showAddRevenueDialog() {
    final amountController = TextEditingController();
    final sourceController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Revenue'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (KES)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sourceController,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      hintText: 'e.g., Fuel Sales, Shop Sales',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty || sourceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              
              final revenue = RevenueRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                amount: amount,
                date: selectedDate,
                source: sourceController.text,
                description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                recordedBy: 'Manager',
              );
              
              setState(() {
                _revenues.insert(0, revenue);
                _applyRevenueFilters();
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Revenue added successfully'),
                  backgroundColor: _ExpenseConstants.accentGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ExpenseConstants.accentGreen,
            ),
            child: const Text('Add Revenue'),
          ),
        ],
      ),
    );
  }

  // MARK: - Expense Actions
  Future<void> _addExpense(Expense expense) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      setState(() {
        _expenses.insert(0, expense);
        _applyFilters();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: _ExpenseConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: _ExpenseConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    try {
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        if (!mounted) return;
        
        setState(() {
          _expenses[index] = expense;
          _applyFilters();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              backgroundColor: _ExpenseConstants.accentGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expense: ${e.toString()}'),
            backgroundColor: _ExpenseConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      if (!mounted) return;
      
      setState(() {
        _expenses.removeWhere((e) => e.id == expenseId);
        _applyFilters();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: _ExpenseConstants.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: ${e.toString()}'),
            backgroundColor: _ExpenseConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkIsUnreachable')) {
      return 'No internet connection. Please check your network.';
    }
    if (error.toString().contains('Unauthorized') || 
        error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'Failed to load data. Please try again.';
  }
  
  void _showErrorSnackBar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? 'An error occurred')),
          ],
        ),
        backgroundColor: _ExpenseConstants.errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadExpenses,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        onSave: (expense) async {
          await _addExpense(expense);
        },
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        expense: expense,
        onSave: (updatedExpense) async {
          await _updateExpense(updatedExpense);
        },
      ),
    );
  }

  void _confirmDelete(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await _deleteExpense(expense.id);
    }
  }

  // MARK: - Expense Details Modal
  void _showExpenseDetails(Expense expense) {
    final isHighValue = expense.amount >= 50000;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHighValue
                          ? [
                              _ExpenseConstants.warningOrange,
                              _ExpenseConstants.warningOrange.withValues(alpha: 0.8),
                            ]
                          : [
                              expense.category.color,
                              expense.category.color.withValues(alpha: 0.8),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              expense.category.icon,
                              color: isHighValue ? _ExpenseConstants.warningOrange : expense.category.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.description,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expense.category.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isHighValue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: _ExpenseConstants.warningOrange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'High Value',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _ExpenseConstants.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'KES ${NumberFormat('#,###').format(expense.amount)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(expense.date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (isHighValue)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ExpenseConstants.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _ExpenseConstants.warningOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _ExpenseConstants.warningOrange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a high-value expense (≥ KES 50,000). Please ensure proper documentation.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _ExpenseConstants.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoSection('Transaction Details', [
                        _buildInfoRow(
                          'Description',
                          expense.description,
                          Icons.description_outlined,
                        ),
                        _buildInfoRow(
                          'Category',
                          expense.category.displayName,
                          expense.category.icon,
                          valueColor: expense.category.color,
                        ),
                        _buildInfoRow(
                          'Amount',
                          'KES ${NumberFormat('#,###').format(expense.amount)}',
                          Icons.money_outlined,
                          valueColor: isHighValue ? _ExpenseConstants.warningOrange : _ExpenseConstants.primaryDark,
                        ),
                        _buildInfoRow(
                          'Date',
                          DateFormat('dd MMM yyyy').format(expense.date),
                          Icons.calendar_today_outlined,
                        ),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      if (expense.vendorName != null ||
                          expense.paymentMethod != null ||
                          expense.referenceNumber != null)
                        _buildInfoSection('Payment Information', [
                          if (expense.vendorName != null)
                            _buildInfoRow(
                              'Vendor',
                              expense.vendorName!,
                              Icons.business_outlined,
                            ),
                          if (expense.paymentMethod != null)
                            _buildInfoRow(
                              'Payment Method',
                              expense.paymentMethod!,
                              Icons.payment_outlined,
                            ),
                          if (expense.referenceNumber != null)
                            _buildInfoRow(
                              'Reference',
                              expense.referenceNumber!,
                              Icons.numbers_outlined,
                            ),
                        ]),
                      
                      if (expense.isRecurring) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection('Recurring', [
                          _buildInfoRow(
                            'Interval',
                            _getRecurringText(expense.recurringIntervalDays),
                            Icons.repeat_outlined,
                          ),
                        ]),
                      ],
                      
                      if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoSection('Notes', [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              expense.notes!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditExpenseDialog(expense);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _ExpenseConstants.primaryDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(expense);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ExpenseConstants.errorRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getRecurringText(int? days) {
    switch (days) {
      case 7:
        return 'Weekly';
      case 30:
        return 'Monthly';
      case 90:
        return 'Quarterly';
      case 365:
        return 'Yearly';
      default:
        return 'Every $days days';
    }
  }

  // MARK: - Helper Widgets
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Build Methods
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > _ExpenseConstants.tabletBreakpoint;
    final isTablet = screenWidth > _ExpenseConstants.mobileBreakpoint && 
                     screenWidth <= _ExpenseConstants.tabletBreakpoint;
    
    if (isDesktop) {
      debugPrint('Desktop layout active');
    } else if (isTablet) {
      debugPrint('Tablet layout active');
    } else {
      debugPrint('Mobile layout active');
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Financial Management'),
        backgroundColor: _ExpenseConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt), text: 'Expenses'),
            Tab(icon: Icon(Icons.attach_money), text: 'Revenue'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isFilterExpanded)
            ExpenseFilterBar(
              selectedDateRange: _selectedDateRange,
              selectedCategory: _selectedCategory,
              onDateRangeSelected: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                );
                if (range != null && mounted) {
                  setState(() {
                    _selectedDateRange = range;
                    _applyFilters();
                    _applyRevenueFilters();
                  });
                }
              },
              onCategorySelected: (ExpenseCategory? category) {
                setState(() {
                  _selectedCategory = category;
                  _applyFilters();
                });
              },
              onClearFilters: () {
                setState(() {
                  _selectedDateRange = null;
                  _selectedCategory = null;
                  _searchQuery = '';
                  _applyFilters();
                  _applyRevenueFilters();
                });
              },
            ),
          
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          if (_warningMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ExpenseConstants.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _ExpenseConstants.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _ExpenseConstants.warningOrange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _warningMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ExpenseConstants.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseList(),
                _buildRevenueList(),
                _buildAnalyticsView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddExpenseDialog();
          } else if (_tabController.index == 1) {
            _showAddRevenueDialog();
          }
        },
        icon: Icon(_tabController.index == 0 ? Icons.add : Icons.attach_money),
        label: Text(_tabController.index == 0 ? 'Add Expense' : 'Add Revenue'),
        backgroundColor: _ExpenseConstants.primaryDark,
      ),
    );
  }

  Widget _buildRevenueList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredRevenues.isEmpty && !_isLoading && _errorMessage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attach_money_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No revenue records',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first revenue record',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddRevenueDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Revenue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ExpenseConstants.accentGreen,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadRevenues();
      },
      color: _ExpenseConstants.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRevenues.length,
        itemBuilder: (context, index) {
          final revenue = _filteredRevenues[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showRevenueDetails(revenue),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _ExpenseConstants.accentGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: _ExpenseConstants.accentGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                revenue.source,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(revenue.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (revenue.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  revenue.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KES ${NumberFormat('#,###').format(revenue.amount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _ExpenseConstants.accentGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recorded by: ${revenue.recordedBy}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRevenueDetails(RevenueRecord revenue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_ExpenseConstants.accentGreen, _ExpenseConstants.primaryDark],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: _ExpenseConstants.accentGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              revenue.source,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(revenue.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(revenue.amount)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Source',
                    revenue.source,
                    Icons.business,
                  ),
                  _buildInfoRow(
                    'Date',
                    DateFormat('dd MMM yyyy, HH:mm').format(revenue.date),
                    Icons.calendar_today,
                  ),
                  if (revenue.description != null)
                    _buildInfoRow(
                      'Description',
                      revenue.description!,
                      Icons.description,
                    ),
                  _buildInfoRow(
                    'Recorded By',
                    revenue.recordedBy,
                    Icons.person,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredExpenses.isEmpty && !_isLoading && _errorMessage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first expense',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ExpenseConstants.primaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      color: _ExpenseConstants.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredExpenses.length,
        itemBuilder: (context, index) {
          final expense = _filteredExpenses[index];
          return ExpenseCard(
            expense: expense,
            onTap: () => _showExpenseDetails(expense),
            onEdit: () => _showEditExpenseDialog(expense),
            onDelete: () => _confirmDelete(expense),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredExpenses.isEmpty && _filteredRevenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No data to analyze',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses and revenue to see analytics',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final summary = _financialSummary;
    final alerts = _expenseIncreaseAlerts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit/Loss Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: summary.isProfitable
                      ? [_ExpenseConstants.profitGreen, _ExpenseConstants.profitGreen.withValues(alpha: 0.8)]
                      : [_ExpenseConstants.lossRed, _ExpenseConstants.lossRed.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Revenue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(summary.totalRevenue)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(summary.totalExpenses)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          summary.isProfitable ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          summary.isProfitable ? 'PROFIT' : 'LOSS',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KES ${NumberFormat('#,###').format(summary.netProfit.abs())}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profit Margin: ${summary.profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Daily Averages Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Averages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Avg Daily Expense',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(_averageDailyExpense)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _ExpenseConstants.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Avg Daily Revenue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KES ${NumberFormat('#,###').format(_averageDailyRevenue)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _ExpenseConstants.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expense Increase Alerts
          if (alerts.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _ExpenseConstants.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _ExpenseConstants.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: _ExpenseConstants.warningOrange),
                      SizedBox(width: 8),
                      Text(
                        'Expense Alerts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _ExpenseConstants.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      alert,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ExpenseConstants.warningOrange,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          
          // Revenue vs Expense Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue vs Expenses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRevenueVsExpenseChart(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expenses by Category
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expenses by Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ExpenseCategoryChart(
                    categories: summary.categoryExpenses,
                    total: summary.totalExpenses,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category Changes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Month-over-Month Changes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...summary.categoryChanges.entries.map((entry) {
                    final change = entry.value;
                    final isIncrease = change > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            entry.key.icon,
                            color: entry.key.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${isIncrease ? '+' : ''}${change.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncrease ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: isIncrease ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueVsExpenseChart() {
    final dailyExpenses = _expensesByDay;
    final dailyRevenue = _revenueByDay;
    
    // Collect all unique dates
    final Set<String> allDateSet = {};
    for (final expense in dailyExpenses) {
      allDateSet.add(expense['date'] as String);
    }
    for (final revenue in dailyRevenue) {
      allDateSet.add(revenue['date'] as String);
    }
    
    final List<String> allDates = allDateSet.toList()..sort();
    
    if (allDates.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    // Find max amount for scaling
    double maxAmount = 0.0;
    for (final expense in dailyExpenses) {
      final amount = expense['amount'] as double;
      if (amount > maxAmount) maxAmount = amount;
    }
    for (final revenue in dailyRevenue) {
      final amount = revenue['amount'] as double;
      if (amount > maxAmount) maxAmount = amount;
    }
    
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allDates.length,
        itemBuilder: (context, index) {
          final date = allDates[index];
          
          // Find expense amount for this date
          double expenseAmount = 0.0;
          for (final expense in dailyExpenses) {
            if (expense['date'] == date) {
              expenseAmount = expense['amount'] as double;
              break;
            }
          }
          
          // Find revenue amount for this date
          double revenueAmount = 0.0;
          for (final revenue in dailyRevenue) {
            if (revenue['date'] == date) {
              revenueAmount = revenue['amount'] as double;
              break;
            }
          }
          
          final expenseBarHeight = maxAmount > 0 ? (expenseAmount / maxAmount * 180).toDouble() : 0.0;
          final revenueBarHeight = maxAmount > 0 ? (revenueAmount / maxAmount * 180).toDouble() : 0.0;
          
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Revenue Bar
                if (revenueAmount > 0)
                  Container(
                    height: revenueBarHeight,
                    width: 30,
                    decoration: BoxDecoration(
                      color: _ExpenseConstants.accentGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${(revenueAmount / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 8, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                // Expense Bar
                if (expenseAmount > 0)
                  Container(
                    height: expenseBarHeight,
                    width: 30,
                    decoration: BoxDecoration(
                      color: _ExpenseConstants.errorRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${(expenseAmount / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 8, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMM').format(DateTime.parse(date)),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: _ExpenseConstants.accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      color: _ExpenseConstants.errorRed,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}