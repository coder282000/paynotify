// lib/features/manager/presentation/widgets/peak_hours_chart.dart

import 'package:flutter/material.dart';
import '../../domain/models/analytics_model.dart';

class PeakHoursChart extends StatelessWidget {
  final List<PeakHourData> data;
  final double height;

  const PeakHoursChart({
    super.key,
    required this.data,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Semantics(
        label: 'No peak hour data available',
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: const Text('No peak hour data available'),
        ),
      );
    }

    final maxValue = data.map((e) => e.averageSales).reduce((a, b) => a > b ? a : b);

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
              child: const Text(
                'Peak Hours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Average sales by hour of day',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Semantics(
              label: 'Peak hours chart showing busiest times',
              child: SizedBox(
                height: height - 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final hour = data[index];
                    final barHeight = (hour.averageSales / maxValue) * (height - 80) * 0.7;
                    
                    return Semantics(
                      label: '${hour.hourDisplay}: KES ${hour.averageSales.toStringAsFixed(0)} average, ${hour.transactionCount} transactions',
                      child: Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade300,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hour.hourDisplay,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${hour.transactionCount}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}