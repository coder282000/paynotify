// lib/features/owner/presentation/screens/expense_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/expense_model.dart';
import '../providers/owner_provider.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  String _selectedStation = 'all';
  String _selectedCategory = 'all';
  String _sortBy = 'expense_date';
  bool _sortAscending = false;

  // Categories list
  final List<String> _categories = [
    'all',
    'fuelPurchase',
    'salary',
    'maintenance',
    'utilities',
    'rent',
    'supplies',
    'marketing',
    'insurance',
    'other',
  ];
  
  List<String> _stations = ['all'];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // ✅ FIXED: Bug 3 - Date corruption fixed by removing unnecessary round-trip
  Future<void> _loadExpenses() async {
    final provider = Provider.of<OwnerProvider>(context, listen: false);
    await provider.loadExpenses();
    
    // ✅ provider.expenses is already List<Expense>
    // Just update stations from the loaded data
    setState(() {
      _stations = ['all', ...provider.expenses.map((e) => e.stationName).toSet()];
    });
  }

  Future<void> _deleteExpense(String id) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);
      final success = await provider.deleteExpense(id);
      
      if (success) {
        _showSuccessDialog('Expense deleted successfully');
        await _loadExpenses();
      } else {
        throw Exception(provider.errorMessage ?? 'Failed to delete expense');
      }
    } catch (e) {
      _showErrorDialog('Delete failed', e.toString());
    }
  }

  Future<void> _showCreateExpenseDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateExpenseDialog(),
    );

    if (result != null) {
      await _loadExpenses();
    }
  }

  void _showEditExpenseDialog(Expense expense) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditExpenseDialog(expense: expense),
    );

    if (result != null) {
      await _loadExpenses();
    }
  }

  void _showErrorDialog(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Expense> get _filteredExpenses {
    final provider = Provider.of<OwnerProvider>(context);
    return provider.expenses.where((e) {
      if (_selectedStation != 'all' && e.stationId != _selectedStation) return false;
      if (_selectedCategory != 'all' && e.category != _selectedCategory) return false;
      return true;
    }).toList();
  }

  double get _totalExpenses {
    final filtered = _filteredExpenses;
    return filtered.fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OwnerProvider>(context);
    final filtered = _filteredExpenses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracking'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateExpenseDialog,
            tooltip: 'Add Expense',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading expenses',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExpenses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B3D2E), Color(0xFF1A5D4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'KES ${NumberFormat('#,##0.00').format(_totalExpenses)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${filtered.length} transactions • ${provider.expenses.isNotEmpty ? provider.expenses.first.stationName : 'No stations'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    // Filters
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
                    const SizedBox(height: 8),
                    // Sort controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Sort by: ', style: TextStyle(fontSize: 12)),
                          DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: 'expense_date', child: Text('Date')),
                              DropdownMenuItem(value: 'amount', child: Text('Amount')),
                              DropdownMenuItem(value: 'category', child: Text('Category')),
                              DropdownMenuItem(value: 'station_name', child: Text('Station')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                                _loadExpenses();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                                _loadExpenses();
                              });
                            },
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Expense list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No expenses found',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _showCreateExpenseDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B3D2E),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Add First Expense'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final expense = filtered[index];
                                return _buildExpenseCard(expense);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditExpenseDialog(expense),
        onLongPress: () => _deleteExpense(expense.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: expense.categoryColor.withValues(alpha: 0.1),
                child: Icon(
                  expense.categoryIcon,
                  color: expense.categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: expense.categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expense.categoryDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: expense.categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expense.stationName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expense.formattedDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                    if (expense.vendorName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Vendor: ${expense.vendorName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.formattedAmount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (expense.notes != null)
                    Text(
                      expense.notes!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item == 'all' ? 'All $label' : item,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CREATE EXPENSE DIALOG
// ──────────────────────────────────────────────────────────────
class CreateExpenseDialog extends StatefulWidget {
  const CreateExpenseDialog({super.key});

  @override
  State<CreateExpenseDialog> createState() => _CreateExpenseDialogState();
}

class _CreateExpenseDialogState extends State<CreateExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String? _category;
  double _amount = 0;
  String? _description;
  String? _vendorName;
  String? _paymentMethod;
  String? _notes;
  DateTime _expenseDate = DateTime.now();

  final List<String> _categories = [
    'fuelPurchase',
    'salary',
    'maintenance',
    'utilities',
    'rent',
    'supplies',
    'marketing',
    'insurance',
    'other',
  ];

  final List<String> _paymentMethods = ['cash', 'card', 'mpesa', 'bank_transfer'];

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Expense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    value: _category,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _category = value!),
                    validator: (value) => value == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Amount
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: 'KES ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _amount = double.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Amount is required';
                      if (double.tryParse(value) == null) return 'Invalid amount';
                      if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _description = value,
                    validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Date
                  ListTile(
                    title: const Text('Expense Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_expenseDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _expenseDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Vendor Name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _vendorName = value,
                  ),
                  const SizedBox(height: 12),
                  // Payment Method
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    value: _paymentMethod,
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _paymentMethod = value),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _notes = value,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3D2E),
                            foregroundColor: Colors.white,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Add Expense'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Bug 2 - Use toBackendJson() for owner's Expense model
  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);
      
      // ✅ Use toBackendJson() - sends snake_case keys to match backend
      final expenseData = {
        'category': _category!,
        'amount': _amount,
        'description': _description!,
        'expense_date': DateFormat('yyyy-MM-dd').format(_expenseDate),
        if (_vendorName != null && _vendorName!.isNotEmpty) 'vendor_name': _vendorName,
        if (_paymentMethod != null && _paymentMethod!.isNotEmpty) 'payment_method': _paymentMethod,
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      final success = await provider.createExpense(expenseData);

      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(provider.errorMessage ?? 'Failed to create expense');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────
// EDIT EXPENSE DIALOG
// ──────────────────────────────────────────────────────────────
class EditExpenseDialog extends StatefulWidget {
  final Expense expense;
  const EditExpenseDialog({super.key, required this.expense});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late String _category;
  late double _amount;
  late String _description;
  String? _vendorName;
  String? _paymentMethod;
  String? _notes;
  late DateTime _expenseDate;

  bool _isSubmitting = false;

  final List<String> _categories = [
    'fuelPurchase',
    'salary',
    'maintenance',
    'utilities',
    'rent',
    'supplies',
    'marketing',
    'insurance',
    'other',
  ];

  final List<String> _paymentMethods = ['cash', 'card', 'mpesa', 'bank_transfer'];

  @override
  void initState() {
    super.initState();
    _category = widget.expense.category;
    _amount = widget.expense.amount;
    _description = widget.expense.description;
    _vendorName = widget.expense.vendorName;
    _paymentMethod = widget.expense.paymentMethod;
    _notes = widget.expense.notes;
    _expenseDate = widget.expense.date;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Expense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    value: _category,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _category = value!),
                    validator: (value) => value == null ? 'Category is required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Amount
                  TextFormField(
                    initialValue: _amount.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: 'KES ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _amount = double.tryParse(value) ?? 0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Amount is required';
                      if (double.tryParse(value) == null) return 'Invalid amount';
                      if (double.parse(value) <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _description = value,
                    validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Date
                  ListTile(
                    title: const Text('Expense Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_expenseDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _expenseDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Vendor Name
                  TextFormField(
                    initialValue: _vendorName,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _vendorName = value,
                  ),
                  const SizedBox(height: 12),
                  // Payment Method
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    value: _paymentMethod,
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _paymentMethod = value),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextFormField(
                    initialValue: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) => _notes = value,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _updateExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3D2E),
                            foregroundColor: Colors.white,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Update Expense'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Bug 2 - Use toBackendJson() for owner's Expense model
  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<OwnerProvider>(context, listen: false);
      
      // ✅ Use toBackendJson() - sends snake_case keys to match backend
      final expenseData = {
        'category': _category,
        'amount': _amount,
        'description': _description,
        'expense_date': DateFormat('yyyy-MM-dd').format(_expenseDate),
        if (_vendorName != null && _vendorName!.isNotEmpty) 'vendor_name': _vendorName,
        if (_paymentMethod != null && _paymentMethod!.isNotEmpty) 'payment_method': _paymentMethod,
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      final success = await provider.updateExpense(widget.expense.id, expenseData);

      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(provider.errorMessage ?? 'Failed to update expense');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}