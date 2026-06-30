// lib/features/owner/widgets/performance_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PerformanceChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final String title;
  final Color? lineColor;
  final Color? fillColor;

  const PerformanceChart({
    super.key,
    required this.data,
    required this.labels,
    required this.title,
    this.lineColor,
    this.fillColor,
  });

  double get maxValue => data.isEmpty ? 100 : data.reduce((a, b) => a > b ? a : b);
  double get minValue => data.isEmpty ? 0 : data.reduce((a, b) => a < b ? a : b);

  @override
  Widget build(BuildContext context) {
    final chartColor = lineColor ?? const Color(0xFF0B3D2E);
    final areaColor = fillColor ?? chartColor.withOpacity(0.1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: LineChartPainter(
                  data: data,
                  labels: labels,
                  maxValue: maxValue,
                  minValue: minValue,
                  lineColor: chartColor,
                  fillColor: areaColor,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 8),
            // X-axis labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: labels.map((label) {
                return Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Y-axis hints
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KES ${NumberFormat('#,##0').format(minValue)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  'KES ${NumberFormat('#,##0').format(maxValue)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    final xStep = size.width / (data.length - 1);
    final yRange = maxValue - minValue;
    final yScale = yRange > 0 ? size.height / yRange : size.height;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - minValue) * yScale);
      points.add(Offset(x, y));
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw area fill
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}