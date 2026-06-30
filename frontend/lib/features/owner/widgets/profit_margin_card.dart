// lib/features/owner/widgets/profit_margin_card.dart
import 'package:flutter/material.dart';

class ProfitMarginCard extends StatelessWidget {
  final String title;
  final double revenue;
  final double expenses;
  final double profit;
  final double margin;
  final VoidCallback? onTap;

  const ProfitMarginCard({
    super.key,
    required this.title,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProfitable = profit > 0;
    final Color profitColor = isProfitable ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: profitColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProfitable ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: profitColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${margin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: profitColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem('Revenue', revenue, Colors.green),
                  ),
                  Expanded(
                    child: _buildMetricItem('Expenses', expenses, Colors.red),
                  ),
                  Expanded(
                    child: _buildMetricItem('Profit', profit, profitColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          'KES ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}