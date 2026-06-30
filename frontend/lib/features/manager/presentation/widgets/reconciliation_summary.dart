// lib/features/manager/presentation/widgets/reconciliation_summary.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reconciliation_model.dart'; // This import is correct

class ReconciliationSummary extends StatelessWidget {
  final ReconciliationSummaryData summaryData;

  const ReconciliationSummary({
    super.key,
    required this.summaryData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Row with Semantics
          Semantics(
            label: 'Reconciliation statistics summary',
            child: Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Pending',
                    summaryData.pendingItems.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    'Approved',
                    summaryData.approvedItems.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBox(
                    'Rejected',
                    summaryData.rejectedItems.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Variance Stats Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Reconciliation Rate
                  Semantics(
                    label: 'Reconciliation rate ${summaryData.reconciliationRate.toStringAsFixed(1)} percent',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reconciliation Rate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (summaryData.reconciliationRate >= 90 
                                ? Colors.green 
                                : Colors.orange).withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${summaryData.reconciliationRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: summaryData.reconciliationRate >= 90 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Accuracy Rate
                  Semantics(
                    label: 'Accuracy rate ${summaryData.accuracyRate.toStringAsFixed(1)} percent',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Accuracy Rate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (summaryData.accuracyRate >= 98 
                                ? Colors.green 
                                : Colors.orange).withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${summaryData.accuracyRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: summaryData.accuracyRate >= 98 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 24),
                  
                  // Financial Summary
                  Semantics(
                    label: 'Financial summary',
                    child: Column(
                      children: [
                        _buildFinancialRow(
                          'Expected Total',
                          'KES ${NumberFormat('#,##0').format(summaryData.totalExpected)}',
                          Icons.calculate_outlined,
                        ),
                        const SizedBox(height: 8),
                        _buildFinancialRow(
                          'Actual Total',
                          'KES ${NumberFormat('#,##0').format(summaryData.totalActual)}',
                          Icons.attach_money,
                        ),
                        const SizedBox(height: 8),
                        _buildFinancialRow(
                          'Total Variance',
                          'KES ${NumberFormat('#,##0').format(summaryData.totalVariance.abs())}',
                          Icons.trending_up,
                          valueColor: summaryData.totalVariance > 0 
                              ? Colors.orange 
                              : summaryData.totalVariance < 0 
                                  ? Colors.red 
                                  : Colors.green,
                          showSign: true,
                          isPositive: summaryData.totalVariance > 0,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Items with Variance Alert
                  if (summaryData.itemsWithVariance > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Variance Alert',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${summaryData.itemsWithVariance} ${summaryData.itemsWithVariance == 1 ? 'item has' : 'items have'} variance requiring attention',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Semantics(
      label: '$label: $value',
      button: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool showSign = false,
    bool isPositive = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (showSign)
              Text(
                isPositive ? '+' : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}