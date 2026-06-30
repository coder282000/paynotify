// lib/features/manager/presentation/widgets/fuel_level_indicator.dart

import 'package:flutter/material.dart';

class FuelLevelIndicator extends StatelessWidget {
  final double level;
  final double capacity;
  final Color color;
  final double height;
  final bool showPercentage;

  const FuelLevelIndicator({
    super.key,
    required this.level,
    required this.capacity,
    required this.color,
    this.height = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (level / capacity * 100).clamp(0, 100);
    
    return Semantics(
      label: 'Fuel level: ${percentage.toStringAsFixed(1)}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '${level.toStringAsFixed(0)} / ${capacity.toStringAsFixed(0)} L',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          if (!showPercentage)
            const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: height,
            ),
          ),
        ],
      ),
    );
  }
}