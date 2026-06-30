// lib/features/manager/presentation/widgets/expense_category_chart.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense_category.dart';

class ExpenseCategoryChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categories;
  final double total;

  const ExpenseCategoryChart({
    super.key,
    required this.categories,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Column(
      children: categories.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(entry.key.icon, color: entry.key.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(entry.key.displayName),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'KES ${NumberFormat('#,###').format(entry.value)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: entry.key.color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(entry.key.color),
                minHeight: 6,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}