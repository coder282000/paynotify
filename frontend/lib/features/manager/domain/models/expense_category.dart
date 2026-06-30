import 'package:flutter/material.dart';

enum ExpenseCategory {
  fuelPurchase,
  salary,
  maintenance,
  utilities,
  rent,
  marketing,
  supplies,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.fuelPurchase:
        return 'Fuel Purchase';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.fuelPurchase:
        return Icons.local_gas_station;
      case ExpenseCategory.salary:
        return Icons.people;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.utilities:
        return Icons.electric_bolt;
      case ExpenseCategory.rent:
        return Icons.business;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.supplies:
        return Icons.inventory;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.fuelPurchase:
        return Colors.blue;
      case ExpenseCategory.salary:
        return Colors.green;
      case ExpenseCategory.maintenance:
        return Colors.orange;
      case ExpenseCategory.utilities:
        return Colors.yellow.shade700;
      case ExpenseCategory.rent:
        return Colors.purple;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.supplies:
        return Colors.brown;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}