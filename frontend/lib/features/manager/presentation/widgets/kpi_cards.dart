// lib/features/manager/presentation/widgets/kpi_cards.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/station_summary.dart';

class KpiCards extends StatelessWidget {
  final StationSummary summary;
  final bool isDesktop;
  final bool isTablet;

  const KpiCards({
    super.key,
    required this.summary,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildKpiCard(
            title: 'Today\'s Sales',
            value: 'KES ${_formatNumber(summary.todaySales)}',
            change: summary.salesChange,
            icon: Icons.trending_up,
            color: Colors.green,
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildKpiCard(
            title: 'Transactions',
            value: summary.transactionCount.toString(),
            change: summary.transactionChange,
            icon: Icons.receipt,
            color: Colors.blue,
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildKpiCard(
            title: 'Active Pumps',
            value: '${summary.activePumps}/${summary.totalPumps}',
            subtitle: '${summary.totalPumps - summary.activePumps} inactive',
            icon: Icons.local_gas_station,
            color: Colors.orange,
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildKpiCard(
            title: 'Attendants',
            value: '${summary.activeAttendants}/${summary.totalAttendants}',
            subtitle: '${summary.totalAttendants - summary.activeAttendants} off',
            icon: Icons.people,
            color: Colors.purple,
          )),
        ],
      );
    } else if (isTablet) {
      // Tablet layout - 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard(
                title: 'Today\'s Sales',
                value: 'KES ${_formatNumber(summary.todaySales)}',
                change: summary.salesChange,
                icon: Icons.trending_up,
                color: Colors.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(
                title: 'Transactions',
                value: summary.transactionCount.toString(),
                change: summary.transactionChange,
                icon: Icons.receipt,
                color: Colors.blue,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKpiCard(
                title: 'Active Pumps',
                value: '${summary.activePumps}/${summary.totalPumps}',
                subtitle: '${summary.totalPumps - summary.activePumps} inactive',
                icon: Icons.local_gas_station,
                color: Colors.orange,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(
                title: 'Attendants',
                value: '${summary.activeAttendants}/${summary.totalAttendants}',
                subtitle: '${summary.totalAttendants - summary.activeAttendants} off',
                icon: Icons.people,
                color: Colors.purple,
              )),
            ],
          ),
        ],
      );
    } else {
      // Mobile layout - 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard(
                title: 'Today\'s Sales',
                value: 'KES ${_formatNumber(summary.todaySales)}',
                change: summary.salesChange,
                icon: Icons.trending_up,
                color: Colors.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(
                title: 'Transactions',
                value: summary.transactionCount.toString(),
                change: summary.transactionChange,
                icon: Icons.receipt,
                color: Colors.blue,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKpiCard(
                title: 'Active Pumps',
                value: '${summary.activePumps}/${summary.totalPumps}',
                subtitle: '${summary.totalPumps - summary.activePumps} inactive',
                icon: Icons.local_gas_station,
                color: Colors.orange,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(
                title: 'Attendants',
                value: '${summary.activeAttendants}/${summary.totalAttendants}',
                subtitle: '${summary.totalAttendants - summary.activeAttendants} off',
                icon: Icons.people,
                color: Colors.purple,
              )),
            ],
          ),
        ],
      );
    }
  }

  // Helper method to build individual KPI card
  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    double? change,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: change >= 0 
                          ? Colors.green.withAlpha(26)
                          : Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: change >= 0 ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${change.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: change >= 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to format numbers
  String _formatNumber(double number) {
    return NumberFormat('#,##0').format(number);
  }
}