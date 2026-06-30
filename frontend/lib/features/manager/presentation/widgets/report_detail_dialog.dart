// lib/features/manager/presentation/widgets/report_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/shift_report_model.dart';

class ReportDetailDialog extends StatefulWidget {
  final ShiftReport report;
  final Function(ShiftReport, {String? remarks}) onApprove;
  final Function(ShiftReport, String reason) onReject;

  const ReportDetailDialog({
    super.key,
    required this.report,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends State<ReportDetailDialog> {
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _rejectionReasonController = TextEditingController();
  bool _isProcessing = false;
  bool _showRejectForm = false;

  @override
  void dispose() {
    _remarksController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  void _handleApprove() {
    setState(() => _isProcessing = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onApprove(widget.report, remarks: _remarksController.text);
    });
  }

  void _handleReject() {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onReject(widget.report, _rejectionReasonController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _showRejectForm ? 0.8 : 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Report status',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.report.status.color.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.report.status.icon,
                          color: widget.report.status.color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'Report ID: ${widget.report.id}',
                            child: Text(
                              widget.report.id,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Semantics(
                            label: 'Status: ${widget.report.status.displayName}',
                            child: Text(
                              widget.report.status.displayName,
                              style: TextStyle(
                                color: widget.report.status.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: Colors.grey.shade200),
              
              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoSection('Shift Information', [
                      _buildInfoRow(
                        'Attendant',
                        widget.report.attendantName,
                        Icons.person_outline,
                      ),
                      _buildInfoRow(
                        'Pump',
                        widget.report.pumpName,
                        Icons.local_gas_station_outlined,
                      ),
                      _buildInfoRow(
                        'Date',
                        DateFormat('EEEE, MMMM d, yyyy').format(widget.report.shiftDate),
                        Icons.calendar_today_outlined,
                      ),
                      _buildInfoRow(
                        'Shift Time',
                        '${DateFormat('HH:mm').format(widget.report.shiftStart)} - ${DateFormat('HH:mm').format(widget.report.shiftEnd)}',
                        Icons.access_time_outlined,
                      ),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Meter Readings', [
                      _buildInfoRow(
                        'Opening',
                        '${widget.report.openingMeter.toStringAsFixed(1)} L',
                        Icons.play_arrow_outlined,
                      ),
                      _buildInfoRow(
                        'Closing',
                        '${widget.report.closingMeter.toStringAsFixed(1)} L',
                        Icons.stop_outlined,
                      ),
                      _buildInfoRow(
                        'Fuel Dispensed',
                        '${widget.report.fuelDispensed.toStringAsFixed(1)} L',
                        Icons.speed_outlined,
                        valueColor: Colors.blue,
                      ),
                    ]),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoSection('Financial Summary', [
                      _buildInfoRow(
                        'Expected Cash',
                        'KES ${NumberFormat('#,##0').format(widget.report.expectedCash)}',
                        Icons.calculate_outlined,
                      ),
                      _buildInfoRow(
                        'Actual Cash',
                        'KES ${NumberFormat('#,##0').format(widget.report.actualCash)}',
                        Icons.attach_money,
                      ),
                      _buildInfoRow(
                        'M-Pesa Total',
                        'KES ${NumberFormat('#,##0').format(widget.report.mpesaTotal)}',
                        Icons.phone_android,
                      ),
                      _buildInfoRow(
                        'Cash Total',
                        'KES ${NumberFormat('#,##0').format(widget.report.cashTotal)}',
                        Icons.money,
                      ),
                      _buildInfoRow(
                        'Variance',
                        widget.report.variance > 0 
                            ? '+${NumberFormat('#,##0').format(widget.report.variance)}'
                            : NumberFormat('#,##0').format(widget.report.variance),
                        Icons.trending_up,
                        valueColor: widget.report.varianceColor,
                      ),
                    ]),
                    
                    if (widget.report.remarks != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Attendant Remarks', [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            label: 'Remarks: ${widget.report.remarks}',
                            child: Text(
                              widget.report.remarks!,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ],
                    
                    if (widget.report.rejectionReason != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
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
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.report.rejectionReason!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (widget.report.isApproved && widget.report.approvedBy != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Approved',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By ${widget.report.approvedBy} on ${DateFormat('dd MMM yyyy, HH:mm').format(widget.report.approvedAt!)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
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
                    
                    if (_showRejectForm) ...[
                      const SizedBox(height: 16),
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
                              controller: _rejectionReasonController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter reason for rejection...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              enabled: !_isProcessing,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isProcessing ? null : () {
                                    setState(() => _showRejectForm = false);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isProcessing ? null : _handleReject,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Text('Confirm Rejection'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action Buttons
              if (widget.report.isPending)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _showRejectForm
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            // Remarks Field
                            Expanded(
                              child: TextField(
                                controller: _remarksController,
                                decoration: InputDecoration(
                                  hintText: 'Add remarks (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                enabled: !_isProcessing,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Reject Button
                            Semantics(
                              button: true,
                              label: 'Reject report',
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : () {
                                  setState(() => _showRejectForm = true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Approve Button
                            Semantics(
                              button: true,
                              label: 'Approve report',
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _handleApprove,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // REMOVED: Semantics with heading parameter
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}