// lib/features/manager/presentation/widgets/reconciliation_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reconciliation_model.dart';

class ReconciliationCard extends StatefulWidget {
  final ReconciliationItem item;
  final VoidCallback onApprove;
  final Function(String) onReject;
  final VoidCallback onFlagForReview;

  const ReconciliationCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onFlagForReview,
  });

  @override
  State<ReconciliationCard> createState() => _ReconciliationCardState();
}

class _ReconciliationCardState extends State<ReconciliationCard> {
  bool _showRejectForm = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  void _handleReject() {
    if (_rejectReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onReject(_rejectReasonController.text);
    setState(() => _showRejectForm = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: item.hasVariance
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    item.varianceColor.withAlpha(26),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
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
                      color: item.status.color.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.status.icon,
                      color: item.status.color,
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
                              'Report ${item.reportId}',
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
                                color: item.status.color.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.status.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.attendantName,
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
                      item.pumpName,
                      Icons.local_gas_station_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'Date',
                      DateFormat('dd MMM yyyy').format(item.shiftDate),
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
                      '${DateFormat('HH:mm').format(item.shiftStart)} - ${DateFormat('HH:mm').format(item.shiftEnd)}',
                      Icons.access_time_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'Fuel',
                      '${item.fuelDispensed.toStringAsFixed(1)} L',
                      Icons.speed_outlined,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Financial Comparison
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
                          'KES ${NumberFormat('#,##0').format(item.expectedCash)}',
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
                          'KES ${NumberFormat('#,##0').format(item.actualCash)}',
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
                            color: item.varianceColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.variance > 0 
                                ? '+${NumberFormat('#,##0').format(item.variance)}'
                                : NumberFormat('#,##0').format(item.variance),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.varianceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (item.remarks != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.remarks!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (item.isPending) ...[
                const SizedBox(height: 16),
                
                if (_showRejectForm)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _rejectReasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter reason for rejection...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showRejectForm = false;
                                  _rejectReasonController.clear();
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _handleReject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Confirm Rejection'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      // Flag for Review
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onFlagForReview,
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: const Text('Flag'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Reject
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showRejectForm = true),
                          icon: const Icon(Icons.close_outlined, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Approve
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onApprove,
                          icon: const Icon(Icons.check_outlined, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
              ] else if (item.isApproved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Approved by ${item.approvedBy ?? 'Manager'} on ${DateFormat('dd MMM yyyy, HH:mm').format(item.approvedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (item.isRejected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rejected by ${item.approvedBy ?? 'Manager'} on ${DateFormat('dd MMM yyyy, HH:mm').format(item.approvedAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.rejectionReason != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            'Reason: ${item.rejectionReason}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
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