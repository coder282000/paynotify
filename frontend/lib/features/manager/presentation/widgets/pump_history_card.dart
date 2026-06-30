// lib/features/manager/presentation/widgets/pump_history_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pump_config.dart';

class PumpHistoryCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final Color? valueColor;

  const PumpHistoryCard({
    super.key,
    required this.child,
    this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.valueColor,
  });

  factory PumpHistoryCard.price(PumpPriceHistory history) {
    return PumpHistoryCard(
      icon: Icons.trending_up,
      title: 'Price Change',
      subtitle: DateFormat('dd MMM yyyy, HH:mm').format(history.date),
      value: '${history.changePercentage.toStringAsFixed(1)}%',
      valueColor: history.change > 0 ? Colors.red : Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'KES ${history.oldPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                history.change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: history.change > 0 ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                'KES ${history.newPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Changed by: ${history.changedBy}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  factory PumpHistoryCard.maintenance(PumpMaintenanceRecord record) {
    return PumpHistoryCard(
      icon: Icons.build,
      title: 'Maintenance',
      subtitle: DateFormat('dd MMM yyyy').format(record.date),
      value: 'KES ${record.cost.toStringAsFixed(0)}',
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            record.description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                record.technician,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (record.nextDueDate != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Next: ${DateFormat('dd MMM').format(record.nextDueDate!)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color ?? Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3D2E).withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0B3D2E),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (value != null)
                        Text(
                          value!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}