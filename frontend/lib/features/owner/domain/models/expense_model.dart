// lib/features/owner/domain/models/expense_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class Expense {
  final String id;
  final String stationId;
  final String stationName;
  final String category; // Keep as String for flexibility
  final double amount;
  final String description;
  final DateTime date;
  final String? vendorName;
  final String? paymentMethod;
  final String? referenceNumber;
  final int? createdBy;
  final String? createdByName;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final String? notes;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.vendorName,
    this.paymentMethod,
    this.referenceNumber,
    this.createdBy,
    this.createdByName,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.notes,
    required this.createdAt,
  });

  // ─────────────────────────────────────────────
  // FACTORY METHODS
  // ─────────────────────────────────────────────

  /// ✅ Factory from backend JSON (snake_case response)
  factory Expense.fromBackendJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? json['station_id']?.toString() ?? '',
      stationName: json['stationName'] ?? json['station_name'] ?? '',
      category: json['category'] ?? 'other',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['expenseDate'] != null 
          ? DateTime.parse(json['expenseDate']) 
          : (json['expense_date'] != null ? DateTime.parse(json['expense_date']) : DateTime.now()),
      vendorName: json['vendorName'] ?? json['vendor_name'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      referenceNumber: json['referenceNumber'] ?? json['reference_number'],
      createdBy: json['createdBy'] ?? json['created_by'],
      createdByName: json['createdByName'] ?? json['created_by_name'],
      isRecurring: json['isRecurring'] ?? json['is_recurring'] ?? false,
      recurringIntervalDays: (json['recurringIntervalDays'] ?? json['recurring_interval_days']) as int?,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
    );
  }

  /// Factory from frontend JSON (camelCase)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? json['station_id']?.toString() ?? '',
      stationName: json['stationName'] ?? json['station_name'] ?? '',
      category: json['category'] ?? 'other',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['expenseDate'] != null 
          ? DateTime.parse(json['expenseDate']) 
          : (json['expense_date'] != null ? DateTime.parse(json['expense_date']) : DateTime.now()),
      vendorName: json['vendorName'] ?? json['vendor_name'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      referenceNumber: json['referenceNumber'] ?? json['reference_number'],
      createdBy: json['createdBy'] ?? json['created_by'],
      createdByName: json['createdByName'] ?? json['created_by_name'],
      isRecurring: json['isRecurring'] ?? json['is_recurring'] ?? false,
      recurringIntervalDays: (json['recurringIntervalDays'] ?? json['recurring_interval_days']) as int?,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
    );
  }

  // ─────────────────────────────────────────────
  // TO JSON
  // ─────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'station_name': stationName,
      'category': category,
      'amount': amount,
      'description': description,
      'expense_date': DateFormat('yyyy-MM-dd').format(date),
      'vendor_name': vendorName,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'created_by': createdBy,
      'is_recurring': isRecurring,
      'recurring_interval_days': recurringIntervalDays,
      'notes': notes,
    };
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String get formattedAmount => 'KES ${NumberFormat('#,##0.00').format(amount)}';
  
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  
  String get categoryDisplayName {
    switch (category) {
      case 'fuelPurchase': return 'Fuel Purchase';
      case 'salary': return 'Salary';
      case 'maintenance': return 'Maintenance';
      case 'utilities': return 'Utilities';
      case 'rent': return 'Rent';
      case 'supplies': return 'Supplies';
      case 'marketing': return 'Marketing';
      case 'insurance': return 'Insurance';
      default: return 'Other';
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'fuelPurchase': return Colors.orange;
      case 'salary': return Colors.purple;
      case 'maintenance': return Colors.red;
      case 'utilities': return Colors.blue;
      case 'rent': return Colors.teal;
      case 'supplies': return Colors.brown;
      case 'marketing': return Colors.pink;
      case 'insurance': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'fuelPurchase': return Icons.local_gas_station;
      case 'salary': return Icons.people;
      case 'maintenance': return Icons.build;
      case 'utilities': return Icons.electric_bolt;
      case 'rent': return Icons.home;
      case 'supplies': return Icons.inventory;
      case 'marketing': return Icons.campaign;
      case 'insurance': return Icons.security;
      default: return Icons.receipt;
    }
  }

  // ─────────────────────────────────────────────
  // CONVENIENCE GETTERS (using ExpenseCategory)
  // ─────────────────────────────────────────────

  /// Get the ExpenseCategory enum
  ExpenseCategory get expenseCategory {
    return ExpenseCategory.fromString(category);
  }

  /// Check if this is a high-value expense (≥ 50,000 KES)
  bool get isHighValue => amount >= 50000;

  /// Get the category display name with emoji
  String get categoryDisplayWithEmoji {
    final emojis = {
      'fuelPurchase': '⛽',
      'salary': '💰',
      'maintenance': '🔧',
      'utilities': '💡',
      'rent': '🏢',
      'supplies': '📦',
      'marketing': '📢',
      'insurance': '🛡️',
      'other': '📋',
    };
    return '${emojis[category] ?? '📋'} $categoryDisplayName';
  }
}

// ─────────────────────────────────────────────
// EXPENSE CATEGORY ENUM (if not in separate file)
// ─────────────────────────────────────────────

enum ExpenseCategory {
  fuelPurchase,
  salary,
  maintenance,
  utilities,
  rent,
  supplies,
  marketing,
  insurance,
  other;

  static ExpenseCategory fromString(String value) {
    switch (value) {
      case 'fuelPurchase':
        return ExpenseCategory.fuelPurchase;
      case 'salary':
        return ExpenseCategory.salary;
      case 'maintenance':
        return ExpenseCategory.maintenance;
      case 'utilities':
        return ExpenseCategory.utilities;
      case 'rent':
        return ExpenseCategory.rent;
      case 'supplies':
        return ExpenseCategory.supplies;
      case 'marketing':
        return ExpenseCategory.marketing;
      case 'insurance':
        return ExpenseCategory.insurance;
      default:
        return ExpenseCategory.other;
    }
  }

  String get key {
    switch (this) {
      case ExpenseCategory.fuelPurchase:
        return 'fuelPurchase';
      case ExpenseCategory.salary:
        return 'salary';
      case ExpenseCategory.maintenance:
        return 'maintenance';
      case ExpenseCategory.utilities:
        return 'utilities';
      case ExpenseCategory.rent:
        return 'rent';
      case ExpenseCategory.supplies:
        return 'supplies';
      case ExpenseCategory.marketing:
        return 'marketing';
      case ExpenseCategory.insurance:
        return 'insurance';
      default:
        return 'other';
    }
  }

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
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.insurance:
        return 'Insurance';
      default:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.fuelPurchase:
        return Colors.orange;
      case ExpenseCategory.salary:
        return Colors.purple;
      case ExpenseCategory.maintenance:
        return Colors.red;
      case ExpenseCategory.utilities:
        return Colors.blue;
      case ExpenseCategory.rent:
        return Colors.teal;
      case ExpenseCategory.supplies:
        return Colors.brown;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.insurance:
        return Colors.indigo;
      default:
        return Colors.grey;
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
        return Icons.home;
      case ExpenseCategory.supplies:
        return Icons.inventory;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.insurance:
        return Icons.security;
      default:
        return Icons.receipt;
    }
  }
}