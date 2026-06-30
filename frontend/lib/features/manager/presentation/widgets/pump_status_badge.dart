// lib/features/manager/presentation/widgets/pump_status_badge.dart

import 'package:flutter/material.dart';
import '../../domain/models/pump_config.dart';

class PumpStatusBadge extends StatelessWidget {
  final PumpStatus status;
  final bool compact;

  const PumpStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.color,
            size: compact ? 10 : 12,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}