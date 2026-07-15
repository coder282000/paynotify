// lib/features/manager/presentation/widgets/customer_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_tier.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final bool canRedeemPoints;
  final VoidCallback onRedeemPoints;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.canRedeemPoints,
    required this.onRedeemPoints,
  });

  // ── Helper methods for tier properties ──
  String _getTierDisplayName(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return 'Bronze';
      case CustomerTier.silver:
        return 'Silver';
      case CustomerTier.gold:
        return 'Gold';
      case CustomerTier.platinum:
        return 'Platinum';
    }
  }

  IconData _getTierIcon(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return Icons.emoji_events;
      case CustomerTier.silver:
        return Icons.emoji_events;
      case CustomerTier.gold:
        return Icons.emoji_events;
      case CustomerTier.platinum:
        return Icons.emoji_events;
    }
  }

  Color _getTierColor(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return const Color(0xFFCD7F32);
      case CustomerTier.silver:
        return const Color(0xFFC0C0C0);
      case CustomerTier.gold:
        return const Color(0xFFFFD700);
      case CustomerTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(customer.tier);
    final tierIcon = _getTierIcon(customer.tier);
    final tierDisplayName = _getTierDisplayName(customer.tier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tierIcon,
                      color: tierColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tierDisplayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tierColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (customer.vehicleNumber != null)
                          Text(
                            customer.vehicleNumber!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spent',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KES ${NumberFormat('#,###').format(customer.totalSpent)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${customer.pointsBalance} pts',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Active',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.lastPurchaseFormatted,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                  if (canRedeemPoints && customer.pointsBalance > 0) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onRedeemPoints,
                      icon: const Icon(Icons.card_giftcard, size: 16),
                      label: const Text('Redeem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}