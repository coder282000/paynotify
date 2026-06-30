// lib/features/owner/widgets/expense_card.dart
import 'package:flutter/material.dart';
import '../domain/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final OwnerExpense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = _getColorFromValue(expense.categoryColorValue);
    final IconData categoryIcon = _getIconFromName(expense.categoryIconName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.categoryDisplay,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.business, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          expense.stationName,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          expense.formattedDate,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    expense.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (expense.vendorName != null)
                    Text(
                      expense.vendorName!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods to convert string values to actual Flutter types
  Color _getColorFromValue(String colorValue) {
    switch (colorValue) {
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'teal': return Colors.teal;
      case 'brown': return Colors.brown;
      case 'pink': return Colors.pink;
      case 'indigo': return Colors.indigo;
      case 'green': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'local_gas_station': return Icons.local_gas_station;
      case 'people': return Icons.people;
      case 'build': return Icons.build;
      case 'electric_bolt': return Icons.electric_bolt;
      case 'home': return Icons.home;
      case 'inventory': return Icons.inventory;
      case 'campaign': return Icons.campaign;
      case 'security': return Icons.security;
      default: return Icons.receipt;
    }
  }
}