// lib/features/manager/presentation/widgets/transaction_filter_dialog.dart

import 'package:flutter/material.dart';
import '../../domain/models/transaction_filter.dart';

class TransactionFilterDialog extends StatefulWidget {
  final TransactionFilter currentFilter;

  const TransactionFilterDialog({
    super.key,
    required this.currentFilter,
  });

  @override
  State<TransactionFilterDialog> createState() => _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  late TransactionFilter _filter;
  DateTimeRange? _selectedDateRange;
  TransactionType? _selectedType;
  TransactionStatus? _selectedStatus;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _selectedDateRange = _filter.dateRange;
    _selectedType = _filter.type;
    _selectedStatus = _filter.status;
    if (_filter.minAmount != null) {
      _minAmountController.text = _filter.minAmount!.toStringAsFixed(0);
    }
    if (_filter.maxAmount != null) {
      _maxAmountController.text = _filter.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B3D2E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B3D2E).withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF0B3D2E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Date Range
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDateRange == null
                              ? 'Select date range'
                              : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                          style: TextStyle(
                            color: _selectedDateRange == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (_selectedDateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transaction Type
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TransactionType.values.map((type) {
                  return FilterChip(
                    label: Text(type.displayName),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                    avatar: Icon(
                      type.icon,
                      size: 16,
                      color: _selectedType == type ? Colors.white : Colors.grey,
                    ),
                    selectedColor: const Color(0xFF0B3D2E),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Status
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
             Wrap(
  spacing: 8,
  children: TransactionStatus.values.map((status) {
    return FilterChip(
      label: Text(status.displayName),
      selected: _selectedStatus == status,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      avatar: Icon(
        status.icon,
        size: 16,
        color: _selectedStatus == status ? Colors.white : status.color,
      ),
      selectedColor: status.color, // FIXED: Removed null-aware operator
      labelStyle: TextStyle(
        color: _selectedStatus == status ? Colors.white : Colors.black,
      ),
    );
  }).toList(),
),
              
              const SizedBox(height: 16),
              
              // Amount Range
              const Text(
                'Amount Range (KES)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, TransactionFilter());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final filter = TransactionFilter(
                          dateRange: _selectedDateRange,
                          type: _selectedType,
                          status: _selectedStatus,
                          minAmount: _minAmountController.text.isEmpty
                              ? null
                              : double.tryParse(_minAmountController.text),
                          maxAmount: _maxAmountController.text.isEmpty
                              ? null
                              : double.tryParse(_maxAmountController.text),
                        );
                        Navigator.pop(context, filter);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}