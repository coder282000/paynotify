// lib/features/manager/presentation/widgets/expense_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_category.dart';

class ExpenseFilterBar extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final ExpenseCategory? selectedCategory;
  final VoidCallback onDateRangeSelected;
  final Function(ExpenseCategory?) onCategorySelected;
  final VoidCallback onClearFilters;

  const ExpenseFilterBar({
    super.key,
    required this.selectedDateRange,
    required this.selectedCategory,
    required this.onDateRangeSelected,
    required this.onCategorySelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: selectedDateRange,
                    );
                    if (range != null) {
                      onDateRangeSelected();
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    selectedDateRange == null
                        ? 'All Time'
                        : '${DateFormat('dd MMM').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClearFilters,
                tooltip: 'Clear filters',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.displayName),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        onCategorySelected(selected ? category : null);
                      },
                      avatar: Icon(category.icon, size: 16),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}