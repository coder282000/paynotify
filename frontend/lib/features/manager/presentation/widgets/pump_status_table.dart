// lib/features/manager/presentation/widgets/pump_status_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/pump_status.dart';

class PumpStatusTable extends StatelessWidget {
  final List<PumpStatus> pumps;
  final bool isMobile;
  final bool isTablet;

  const PumpStatusTable({
    super.key,
    required this.pumps,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: pumps.map((pump) => _buildMobilePumpCard(pump)).toList(),
      );
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Pump')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Attendant')),
            DataColumn(label: Text('Fuel Type')),
            DataColumn(label: Text('Today\'s Sales')),
            DataColumn(label: Text('Last Reading')),
            DataColumn(label: Text('Actions')),
          ],
          rows: pumps.map((pump) {
            return DataRow(
              cells: [
                DataCell(Text(pump.number)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pump.status).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pump.status,
                      style: TextStyle(
                        color: _getStatusColor(pump.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(pump.attendantName ?? '—')),
                DataCell(Text(pump.fuelType)),
                DataCell(Text('KES ${_formatNumber(pump.todaySales)}')),
                DataCell(Text('${pump.lastReading.toStringAsFixed(1)}L')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          pump.isActive ? Icons.pause : Icons.play_arrow,
                          size: 18,
                          color: pump.isActive ? Colors.orange : Colors.green,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobilePumpCard(PumpStatus pump) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pump.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(pump.status).withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pump.status,
                    style: TextStyle(
                      color: _getStatusColor(pump.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Attendant:',
                    pump.attendantName ?? '—',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Fuel:',
                    pump.fuelType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Sales:',
                    'KES ${_formatNumber(pump.todaySales)}',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Last Reading:',
                    '${pump.lastReading.toStringAsFixed(1)}L',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    pump.isActive ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(pump.isActive ? 'Pause' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(color: Colors.grey),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double number) {
    return NumberFormat('#,##0').format(number);
  }
}