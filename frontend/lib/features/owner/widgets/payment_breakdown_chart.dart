// lib/features/owner/widgets/payment_breakdown_chart.dart
import 'package:flutter/material.dart';

class PaymentBreakdownChart extends StatelessWidget {
  final double cashTotal;
  final double cardTotal;
  final double mpesaTotal;

  const PaymentBreakdownChart({
    super.key,
    required this.cashTotal,
    required this.cardTotal,
    required this.mpesaTotal,
  });

  double get total => cashTotal + cardTotal + mpesaTotal;
  double get cashPercentage => total > 0 ? (cashTotal / total) * 100 : 0;
  double get cardPercentage => total > 0 ? (cardTotal / total) * 100 : 0;
  double get mpesaPercentage => total > 0 ? (mpesaTotal / total) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Donut Chart Visualization
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 8),
                    ),
                  ),
                  // Cash segment
                  if (cashPercentage > 0)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: cashPercentage / 100,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        strokeWidth: 8,
                      ),
                    ),
                  // Card segment (wraps around)
                  if (cardPercentage > 0)
                    Transform.rotate(
                      angle: (cashPercentage / 100) * 2 * 3.14159,
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: cardPercentage / 100,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 8,
                        ),
                      ),
                    ),
                  // Center text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        'KES ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Cash', cashPercentage),
                _buildLegendItem(Colors.blue, 'Card', cardPercentage),
                _buildLegendItem(Colors.orange, 'M-Pesa', mpesaPercentage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label (${percentage.toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}