// lib/features/manager/presentation/widgets/performance_chart.dart

import 'package:flutter/material.dart';
import '../../domain/models/performance_model.dart';

class PerformanceChart extends StatelessWidget {
  final List<AttendantPerformance> performances;
  final double height;

  const PerformanceChart({
    super.key,
    required this.performances,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const Text('No performance data available'),
      );
    }

    // Sort by accuracy rate for better visualization
    final sortedPerformances = List<AttendantPerformance>.from(performances)
      ..sort((a, b) => b.accuracyRate.compareTo(a.accuracyRate));
    
    final maxAccuracy = 100.0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Accuracy rates by attendant',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Chart - Fixed height constraints
            SizedBox(
              height: height - 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(sortedPerformances.length, (index) {
                  final performance = sortedPerformances[index];
                  final barHeight = (performance.accuracyRate / maxAccuracy) * (height - 60) * 0.7;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          Container(
                            height: barHeight.clamp(4.0, (height - 60) * 0.7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  performance.gradeColor,
                                  performance.gradeColor.withAlpha(179),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Attendant initial
                          Tooltip(
                            message: '${performance.attendantName}: ${performance.accuracyRate.toStringAsFixed(1)}%',
                            child: Text(
                              performance.attendantName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Legend - Wrapped to prevent overflow
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendItem('Excellent (A+)', Colors.green),
                _buildLegendItem('Good (A-B)', Colors.blue),
                _buildLegendItem('Average (C)', Colors.orange),
                _buildLegendItem('Needs Improvement (D-F)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9),
        ),
      ],
    );
  }
}