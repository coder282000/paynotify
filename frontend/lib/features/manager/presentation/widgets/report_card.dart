// lib/features/manager/presentation/widgets/report_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/shift_report_model.dart';

class ReportCard extends StatelessWidget {
  final ShiftReport report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Report ${report.id} from ${report.attendantName}, ${report.status.displayName}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: report.status.color.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        report.status.icon,
                        color: report.status.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Report Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                report.id,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: report.status.color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  report.status.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: report.status.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.attendantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Details Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailColumn(
                        'Pump',
                        report.pumpName,
                        Icons.local_gas_station_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailColumn(
                        'Date',
                        DateFormat('dd MMM yyyy').format(report.shiftDate),
                        Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailColumn(
                        'Shift',
                        '${DateFormat('HH:mm').format(report.shiftStart)} - ${DateFormat('HH:mm').format(report.shiftEnd)}',
                        Icons.access_time_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailColumn(
                        'Fuel',
                        '${report.fuelDispensed.toStringAsFixed(1)} L',
                        Icons.speed_outlined,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Financial Summary
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expected',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KES ${NumberFormat('#,##0').format(report.expectedCash)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actual',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KES ${NumberFormat('#,##0').format(report.actualCash)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Variance',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: report.varianceColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              report.variance > 0 
                                  ? '+${NumberFormat('#,##0').format(report.variance)}'
                                  : NumberFormat('#,##0').format(report.variance),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: report.varianceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (report.remarks != null || report.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: report.status == ReportStatus.rejected
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.status == ReportStatus.rejected
                              ? Icons.error_outline
                              : Icons.info_outline,
                          size: 16,
                          color: report.status == ReportStatus.rejected
                              ? Colors.red
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.rejectionReason ?? report.remarks!,
                            style: TextStyle(
                              fontSize: 12,
                              color: report.status == ReportStatus.rejected
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}