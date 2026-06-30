// lib/features/owner/widgets/fuel_gauge_widget.dart
import 'package:flutter/material.dart';

class FuelGaugeWidget extends StatelessWidget {
  final double percentage;
  final String fuelType;
  final double currentLevel;
  final double capacity;

  const FuelGaugeWidget({
    super.key,
    required this.percentage,
    required this.fuelType,
    required this.currentLevel,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final Color gaugeColor = _getGaugeColor(percentage);
    
    return Column(
      children: [
        // Gauge Circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fuelType,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${currentLevel.toStringAsFixed(0)}L / ${capacity.toStringAsFixed(0)}L',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getGaugeColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 30) return Colors.orange;
    return Colors.red;
  }
}