// lib/features/supervisor/presentation/widgets/alert_banner.dart

import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final List<String> alerts;
  final VoidCallback? onViewAll;

  const AlertBanner({
    super.key,
    required this.alerts,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF39C12).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF39C12).withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF39C12).withAlpha(51),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: const Color(0xFFF39C12),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Alerts (${alerts.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF39C12),
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF39C12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('VIEW ALL'),
                  ),
              ],
            ),
          ),

          // Alerts List
          ...alerts.take(3).map((alert) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ),
              ],
            ),
          )),

          if (alerts.length > 3)
            Container(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  '+${alerts.length - 3} more alerts',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}