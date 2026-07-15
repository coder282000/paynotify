// lib/features/manager/domain/models/customer_tier.dart

import 'package:flutter/material.dart';

enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum,
}

// ── Extension for instance methods ──
extension CustomerTierExtension on CustomerTier {
  String get displayName {
    switch (this) {
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

  String get emoji {
    switch (this) {
      case CustomerTier.bronze:
        return '🥉';
      case CustomerTier.silver:
        return '🥈';
      case CustomerTier.gold:
        return '🥇';
      case CustomerTier.platinum:
        return '💎';
    }
  }

  Color get color {
    switch (this) {
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

  MaterialColor get materialColor {
    switch (this) {
      case CustomerTier.bronze:
        return Colors.orange;
      case CustomerTier.silver:
        return Colors.grey;
      case CustomerTier.gold:
        return Colors.amber;
      case CustomerTier.platinum:
        return Colors.blueGrey;
    }
  }

  Color get backgroundColor => color.withOpacity(0.15);

  int get threshold {
    switch (this) {
      case CustomerTier.bronze:
        return 0;
      case CustomerTier.silver:
        return 20000;
      case CustomerTier.gold:
        return 50000;
      case CustomerTier.platinum:
        return 100000;
    }
  }

  String get description {
    switch (this) {
      case CustomerTier.bronze:
        return 'New customers starting their journey';
      case CustomerTier.silver:
        return 'Regular customers with growing loyalty';
      case CustomerTier.gold:
        return 'High-value loyal customers';
      case CustomerTier.platinum:
        return 'Premium VIP customers';
    }
  }

  String get nextTierName {
    switch (this) {
      case CustomerTier.bronze:
        return 'Silver';
      case CustomerTier.silver:
        return 'Gold';
      case CustomerTier.gold:
        return 'Platinum';
      case CustomerTier.platinum:
        return '🏆 Max Tier';
    }
  }

  int get nextTierThreshold {
    switch (this) {
      case CustomerTier.bronze:
        return 20000;
      case CustomerTier.silver:
        return 50000;
      case CustomerTier.gold:
        return 100000;
      case CustomerTier.platinum:
        return 0;
    }
  }

  bool get isMaxTier => this == CustomerTier.platinum;

  double progressToNextTier(double totalSpent) {
    if (isMaxTier) return 1.0;
    final currentThreshold = threshold;
    final nextThreshold = nextTierThreshold;
    if (nextThreshold == 0) return 1.0;
    final progress = (totalSpent - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }
}

// ── Static helper methods ──
class CustomerTierHelpers {
  static CustomerTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bronze':
        return CustomerTier.bronze;
      case 'silver':
        return CustomerTier.silver;
      case 'gold':
        return CustomerTier.gold;
      case 'platinum':
        return CustomerTier.platinum;
      default:
        return CustomerTier.bronze;
    }
  }

  static CustomerTier fromSpent(double totalSpent) {
    if (totalSpent >= 100000) return CustomerTier.platinum;
    if (totalSpent >= 50000) return CustomerTier.gold;
    if (totalSpent >= 20000) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  static List<CustomerTier> get allTiers => CustomerTier.values;
}