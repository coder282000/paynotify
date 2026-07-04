// lib/features/owner/widgets/recent_activity_tile.dart
import 'package:flutter/material.dart';
import '../domain/models/station_activity_model.dart';

class RecentActivityTile extends StatelessWidget {
  final StationActivity activity;

  const RecentActivityTile({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.activityColorName).withValues(alpha: 0.1),
          child: Icon(
            _getActivityIcon(activity.activityIconName),
            color: _getActivityColor(activity.activityColorName),
            size: 20,
          ),
        ),
        title: Text(
          activity.description,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            if (activity.attendantName != null) ...[
              Icon(Icons.person, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                activity.attendantName!,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
            ],
            if (activity.paymentType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPaymentColor(activity.paymentType!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activity.paymentType!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: _getPaymentColor(activity.paymentType!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              activity.formattedTime,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: activity.amount != null
            ? Text(
                'KES ${activity.amount!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : null,
      ),
    );
  }

  Color _getActivityColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.attach_money;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'stop':
        return Icons.stop;
      case 'warning':
        return Icons.warning;
      case 'build':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }

  Color _getPaymentColor(String paymentType) {
    switch (paymentType) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'mpesa':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}