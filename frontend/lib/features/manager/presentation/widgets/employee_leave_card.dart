import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/employee_leave.dart';

class EmployeeLeaveCard extends StatelessWidget {
  final EmployeeLeave leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const EmployeeLeaveCard({
    super.key,
    required this.leave,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: leave.type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(leave.type),
                    color: leave.type.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.attendantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leave.type.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: leave.type.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: leave.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    leave.status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: leave.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.date_range, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${leave.daysCount} days',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (leave.reason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${leave.reason}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
            if (leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                    ),
                    child: const Text('APPROVE'),
                  ),
                ],
              ),
            ],
            if (leave.status == LeaveStatus.approved && leave.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently on leave until ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return Icons.beach_access;
      case LeaveType.sick:
        return Icons.medical_services;
      case LeaveType.emergency:
        return Icons.warning;
      case LeaveType.unpaid:
        return Icons.money_off;
      case LeaveType.maternity:
        return Icons.pregnant_woman;
      case LeaveType.paternity:
        return Icons.family_restroom;
    }
  }
}