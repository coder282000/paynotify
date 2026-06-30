import 'package:flutter/material.dart';

enum CustomerTier {
  bronze,
  silver,
  gold,
  platinum;

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

  IconData get icon {
    switch (this) {
      case CustomerTier.bronze:
        return Icons.emoji_events_outlined;
      case CustomerTier.silver:
        return Icons.workspace_premium;
      case CustomerTier.gold:
        return Icons.star;
      case CustomerTier.platinum:
        return Icons.diamond;
    }
  }
}