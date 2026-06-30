// lib/features/supervisor/presentation/widgets/intervention_log_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InterventionType {
  final String displayName;
  final IconData icon;
  final Color color;

  const InterventionType._({
    required this.displayName,
    required this.icon,
    required this.color,
  });

  static const InterventionType sale = InterventionType._(
    displayName: 'Sale',
    icon: Icons.payment,
    color: Colors.green,
  );
  
  static const InterventionType override_ = InterventionType._(
    displayName: 'Override',
    icon: Icons.lock_open,
    color: Colors.orange,
  );
  
  static const InterventionType emergencyStop = InterventionType._(
    displayName: 'Emergency Stop',
    icon: Icons.warning,
    color: Colors.red,
  );
  
  static const InterventionType refill = InterventionType._(
    displayName: 'Fuel Refill',
    icon: Icons.local_gas_station,
    color: Colors.blue,
  );
  
  static const InterventionType reading = InterventionType._(
    displayName: 'Meter Reading',
    icon: Icons.speed,
    color: Colors.purple,
  );
  
  static const InterventionType shiftApproval = InterventionType._(
    displayName: 'Shift Approval',
    icon: Icons.approval,
    color: Colors.teal,
  );

  static List<InterventionType> get values => [
    sale, override_, emergencyStop, refill, reading, shiftApproval
  ];
}

class InterventionLogCard extends StatelessWidget {
  final String id;
  final String pumpName;
  final InterventionType type;
  final DateTime timestamp;
  final String reason;
  final double? amount;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final VoidCallback? onTap;

  const InterventionLogCard({
    super.key,
    required this.id,
    required this.pumpName,
    required this.type,
    required this.timestamp,
    required this.reason,
    this.amount,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.onTap,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatCurrency(double amount) {
    return 'KES ${NumberFormat('#,##0').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: type.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type.icon,
                  color: type.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pumpName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (amount != null)
                      Text(
                        _formatCurrency(amount!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: type.color,
                        ),
                      ),
                    if (customerName != null)
                      Text(
                        'Customer: $customerName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getTimeAgo(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}