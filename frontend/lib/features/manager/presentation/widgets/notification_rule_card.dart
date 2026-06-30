import 'package:flutter/material.dart';
import '../../domain/models/notification_rule.dart';

class NotificationRuleCard extends StatelessWidget {
  final NotificationRule rule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const NotificationRuleCard({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onEdit,
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
                    color: rule.type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    rule.type.icon,
                    color: rule.type.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.type.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRuleDescription(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeTrackColor: const Color(0xFF2ECC71).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF2ECC71),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ...rule.channels.map((channel) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(channel.icon, size: 12, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          channel.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rule.priority.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rule.priority.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: rule.priority.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRuleDescription() {
    if (rule.thresholdValue != null) {
      if (rule.type == NotificationType.lowFuel) {
        return 'Alert when fuel level drops below ${rule.thresholdValue!.toInt()}%';
      } else if (rule.type == NotificationType.highExpense) {
        return 'Alert when expense exceeds KES ${rule.thresholdValue!.toInt()}';
      }
    }
    
    if (rule.type == NotificationType.shiftReminder) {
      return 'Reminder for shift start/end times';
    }
    
    return 'Notify on ${rule.type.displayName.toLowerCase()} events';
  }
}