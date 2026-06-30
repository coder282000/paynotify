// lib/features/manager/presentation/widgets/alerts_section.dart

import 'package:flutter/material.dart';

class AlertsSection extends StatelessWidget {
  final List<String> alerts;
  final bool isDesktop;
  final bool isTablet;

  const AlertsSection({
    super.key,
    required this.alerts,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alerts & Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${alerts.length} pending ${alerts.length == 1 ? 'alert' : 'alerts'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop || isTablet)
                  TextButton.icon(
                    onPressed: () {
                      // Mark all as read
                    },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark all read'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Alerts List
            ...alerts.map((alert) => _buildAlertItem(alert, isDesktop || isTablet)),
            
            if (!isDesktop && !isTablet) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    // View all alerts
                  },
                  child: const Text('View All Alerts'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to build individual alert item
  Widget _buildAlertItem(String alert, bool isLarge) {
    // Determine alert type based on content
    IconData icon;
    Color color;
    
    if (alert.contains('maintenance')) {
      icon = Icons.build;
      color = Colors.orange;
    } else if (alert.contains('approval') || alert.contains('pending')) {
      icon = Icons.pending_actions;
      color = Colors.blue;
    } else if (alert.contains('low')) {
      icon = Icons.local_gas_station;
      color = Colors.red;
    } else {
      icon = Icons.info;
      color = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isLarge ? 20 : 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (isLarge) ...[
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                // Dismiss alert
              },
            ),
            TextButton(
              onPressed: () {
                // View details
              },
              child: const Text('View'),
            ),
          ],
        ],
      ),
    );
  }
}