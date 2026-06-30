

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesChart extends StatelessWidget {
  final List<double> data;
  final double height;

  const SalesChart({
    super.key,
    required this.data,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const Text('No data available'),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 7 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${_calculateTrend()}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: height - 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(data.length, (index) {
                  final value = data[index];
                  final barHeight = range > 0 
                      ? ((value - minValue) / range) * (height - 80) * 0.8
                      : (height - 80) * 0.5;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade300,
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Day label
                          Text(
                            _getDayLabel(index),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('M-Pesa', Colors.green),
                const SizedBox(width: 20),
                _buildLegendItem('Cash', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Target', Colors.orange, isDashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isDashed ? null : color.withAlpha(77),
            border: isDashed 
                ? Border.all(color: color, width: 2, style: BorderStyle.solid)
                : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed 
              ? Container() 
              : Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getDayLabel(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    return DateFormat('E').format(date).substring(0, 3);
  }

  double _calculateTrend() {
    if (data.length < 2) return 0;
    final firstHalf = data.sublist(0, data.length ~/ 2);
    final secondHalf = data.sublist(data.length ~/ 2);
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    if (firstAvg == 0) return 0;
    return ((secondAvg - firstAvg) / firstAvg * 100).roundToDouble();
  }
}