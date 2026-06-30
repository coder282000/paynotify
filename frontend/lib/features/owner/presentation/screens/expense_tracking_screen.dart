// lib/features/owner/presentation/screens/expense_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_model.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  List<OwnerExpense> _expenses = [];
  bool _isLoading = true;
  String _selectedStation = 'all';
  String _selectedCategory = 'all';

  final List<String> _categories = ['all', 'fuelPurchase', 'salary', 'maintenance', 'utilities', 'rent'];
  List<String> _stations = ['all'];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    
    _expenses = [
      OwnerExpense(
        id: '1', stationId: '1', stationName: 'Westlands', category: 'salary',
        amount: 50000, description: 'Staff salaries - March', date: DateTime.now(),
        vendorName: 'Payroll',
      ),
      OwnerExpense(
        id: '2', stationId: '2', stationName: 'Mombasa', category: 'fuelPurchase',
        amount: 25000, description: 'Fuel delivery', date: DateTime.now().subtract(const Duration(days: 2)),
        vendorName: 'Total Energies',
      ),
      OwnerExpense(
        id: '3', stationId: '3', stationName: 'Kisumu', category: 'maintenance',
        amount: 8000, description: 'Pump repair', date: DateTime.now().subtract(const Duration(days: 5)),
        vendorName: 'Technician',
      ),
    ];
    
    _stations = ['all', ..._expenses.map((e) => e.stationName).toSet()];
    _isLoading = false;
  }

  List<OwnerExpense> get _filteredExpenses {
    return _expenses.where((e) {
      if (_selectedStation != 'all' && e.stationName != _selectedStation) return false;
      if (_selectedCategory != 'all' && e.category != _selectedCategory) return false;
      return true;
    }).toList();
  }

  double get _totalExpenses => _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  // Helper methods to convert string values to actual Flutter types
  Color _getCategoryColor(String colorValue) {
    switch (colorValue) {
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'teal': return Colors.teal;
      case 'brown': return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'local_gas_station': return Icons.local_gas_station;
      case 'people': return Icons.people;
      case 'build': return Icons.build;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'home': return Icons.home;
      default: return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracking'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0B3D2E), Color(0xFF1A5D4A)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Expenses', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${NumberFormat('#,##0').format(_totalExpenses)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text('${filtered.length} transactions', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _selectedStation,
                          items: _stations,
                          onChanged: (v) => setState(() => _selectedStation = v!),
                          label: 'Station',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                          label: 'Category',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No expenses found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final expense = filtered[index];
                            final categoryColor = _getCategoryColor(expense.categoryColorValue);
                            final categoryIcon = _getCategoryIcon(expense.categoryIconName);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: categoryColor.withValues(alpha: 0.1),
                                  child: Icon(categoryIcon, color: categoryColor),
                                ),
                                title: Text(expense.description),
                                subtitle: Text('${expense.stationName} • ${expense.formattedDate}'),
                                trailing: Text(
                                  expense.formattedAmount,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item == 'all' ? 'All $label' : item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}