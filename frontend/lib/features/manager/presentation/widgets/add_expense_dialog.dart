// lib/features/manager/presentation/widgets/add_expense_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_model.dart';
import '../../domain/models/expense_category.dart';

class AddExpenseDialog extends StatefulWidget {
  final Expense? expense;
  final Function(Expense) onSave;

  const AddExpenseDialog({
    super.key,
    this.expense,
    required this.onSave,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _vendorController;
  late TextEditingController _referenceController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _notesController;

  ExpenseCategory? _selectedCategory;
  DateTime? _selectedDate;
  bool _isRecurring = false;
  int? _recurringInterval;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description,
    );
    _vendorController = TextEditingController(
      text: widget.expense?.vendorName ?? '',
    );
    _referenceController = TextEditingController(
      text: widget.expense?.referenceNumber ?? '',
    );
    _paymentMethodController = TextEditingController(
      text: widget.expense?.paymentMethod ?? '',
    );
    _notesController = TextEditingController(
      text: widget.expense?.notes ?? '',
    );
    _selectedCategory = widget.expense?.category;
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _isRecurring = widget.expense?.isRecurring ?? false;
    _recurringInterval = widget.expense?.recurringIntervalDays;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _referenceController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      _showError('Please enter a description');
      return;
    }
    
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final expense = Expense(
      id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory!,
      amount: amount,
      description: _descriptionController.text,
      date: _selectedDate!,
      vendorName: _vendorController.text.isNotEmpty ? _vendorController.text : null,
      paymentMethod: _paymentMethodController.text.isNotEmpty ? _paymentMethodController.text : null,
      referenceNumber: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      createdBy: 'Manager',
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      isRecurring: _isRecurring,
      recurringIntervalDays: _isRecurring ? _recurringInterval : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    await widget.onSave(expense);
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_outlined,
                        color: const Color(0xFF0B3D2E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.expense == null ? 'Add Expense' : 'Edit Expense',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., Fuel stock purchase',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (KES) *',
                    prefixIcon: const Icon(Icons.money_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., 50000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category
                const Text(
                  'Category *',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ExpenseCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(category.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      avatar: Icon(
                        category.icon,
                        color: isSelected ? Colors.white : category.color,
                        size: 16,
                      ),
                      selectedColor: category.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null && mounted) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_selectedDate!)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Vendor
                TextFormField(
                  controller: _vendorController,
                  decoration: InputDecoration(
                    labelText: 'Vendor/Supplier (Optional)',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., Total Energies',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment Method
                TextFormField(
                  controller: _paymentMethodController,
                  decoration: InputDecoration(
                    labelText: 'Payment Method (Optional)',
                    prefixIcon: const Icon(Icons.payment_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., M-Pesa, Bank Transfer, Cash',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reference Number
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'Reference Number (Optional)',
                    prefixIcon: const Icon(Icons.numbers_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., INV-2024001',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Any additional information...',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recurring Expense
                SwitchListTile(
                  title: const Text('Recurring Expense'),
                  subtitle: const Text('This expense repeats regularly'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() => _isRecurring = value);
                  },
                  activeTrackColor: const Color(0xFF0B3D2E).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF0B3D2E),
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _recurringInterval ?? 30,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('Weekly (7 days)')),
                          DropdownMenuItem(value: 30, child: Text('Monthly (30 days)')),
                          DropdownMenuItem(value: 90, child: Text('Quarterly (90 days)')),
                          DropdownMenuItem(value: 365, child: Text('Yearly (365 days)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _recurringInterval = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF0B3D2E)),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'SAVE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}