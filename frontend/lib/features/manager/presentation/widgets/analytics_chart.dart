// lib/features/manager/presentation/widgets/analytics_chart.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/analytics_model.dart';

class AnalyticsChart extends StatelessWidget {
  final List<SalesDataPoint> data;
  final double height;
  final String title;
  final String subtitle;

  const AnalyticsChart({
    super.key,
    required this.data,
    this.height = 250,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Semantics(
        label: 'No chart data available',
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: const Text('No data available for selected period'),
        ),
      );
    }

    final maxValue = data.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.total).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Chart
            Semantics(
              label: 'Sales trend chart showing $title',
              child: SizedBox(
                height: height - 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.length, (index) {
                    final point = data[index];
                    final totalHeight = range > 0
                        ? ((point.total - minValue) / range) * (height - 100) * 0.8
                        : (height - 100) * 0.5;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Stacked bars - Fixed: Removed Container with height
                            SizedBox(
                              height: totalHeight,
                              child: Row(
                                children: [
                                  // M-Pesa portion
                                  if (point.mpesaAmount > 0)
                                    Expanded(
                                      flex: (point.mpesaAmount / point.total * 100).toInt(),
                                      child: Container(
                                        color: Colors.green,
                                      ),
                                    ),
                                  // Cash portion
                                  if (point.cashAmount > 0)
                                    Expanded(
                                      flex: (point.cashAmount / point.total * 100).toInt(),
                                      child: Container(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  // Card portion
                                  if (point.cardAmount > 0)
                                    Expanded(
                                      flex: (point.cardAmount / point.total * 100).toInt(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(2),
                                            bottomRight: Radius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // X-axis label
                            Semantics(
                              label: 'Date: ${_getXAxisLabel(point.date)}',
                              child: Text(
                                _getXAxisLabel(point.date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Semantics(
              label: 'Chart legend showing payment methods',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('M-Pesa', Colors.green),
                  const SizedBox(width: 16),
                  _buildLegendItem('Cash', Colors.blue),
                  const SizedBox(width: 16),
                  _buildLegendItem('Card', Colors.purple),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getXAxisLabel(DateTime date) {
    // Adjust based on data density
    return DateFormat('dd/MM').format(date);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Semantics(
      label: label,
      child: Row(
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
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}