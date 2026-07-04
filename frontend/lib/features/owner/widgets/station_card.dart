// lib/features/owner/widgets/station_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models/station_model.dart';
import '../domain/models/station_summary_model.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final StationSummary summary;
  final VoidCallback onTap;

  const StationCard({
    super.key,
    required this.station,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B3D2E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFF0B3D2E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.stationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          station.stationCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Indicators
                  if (!station.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'INACTIVE',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  if (summary.hasLowFuel)
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                  if (summary.hasPendingReports)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.pending, color: Colors.orange, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Today\'s Sales',
                      'KES ${NumberFormat('#,##0').format(summary.todaySales)}',
                      Icons.trending_up,
                      summary.salesGrowth,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Transactions',
                      summary.todayTransactions.toString(),
                      Icons.receipt,
                      null,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Active Pumps',
                      '${summary.activePumps}/${summary.totalPumps}',
                      Icons.local_gas_station,
                      null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Progress Indicators
              _buildProgressBar(
                label: 'Pump Utilization',
                value: summary.pumpUtilization,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _buildProgressBar(
                label: 'Staff Utilization',
                value: summary.attendantUtilization,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Updated: ${DateFormat('HH:mm').format(summary.lastUpdated)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, double? growth) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (growth != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: growth >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 9,
                  color: growth >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text('${value.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}