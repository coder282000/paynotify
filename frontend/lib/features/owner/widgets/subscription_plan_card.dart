// lib/features/owner/widgets/subscription_plan_card.dart
import 'package:flutter/material.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String description;
  final Color color;
  final List<String> features;
  final bool isCurrentPlan;
  final VoidCallback? onUpgrade;

  const SubscriptionPlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.description,
    required this.color,
    required this.features,
    this.isCurrentPlan = false,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentPlan ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlan
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    name == 'Enterprise' ? Icons.star : Icons.rocket,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (onUpgrade != null)
                  OutlinedButton(
                    onPressed: onUpgrade,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
                    child: const Text('Upgrade'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Chip(
                  label: Text(
                    feature,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: color.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}