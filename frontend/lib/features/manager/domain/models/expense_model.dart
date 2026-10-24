// lib/features/manager/domain/models/expense_model.dart
import 'expense_category.dart';

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String? vendorName;
  final String? paymentMethod;
  final String? referenceNumber;
  final String createdBy;
  final DateTime createdAt;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final String? notes;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.vendorName,
    this.paymentMethod,
    this.referenceNumber,
    required this.createdBy,
    required this.createdAt,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.notes,
  });

  // ─────────────────────────────────────────────
  // FACTORY FROM BACKEND JSON (handles both response shapes)
  // ─────────────────────────────────────────────
  //
  // expenseController.js returns two DIFFERENT shapes depending on
  // the endpoint:
  //   - GET /manager/expenses: explicitly mapped, camelCase keys,
  //     amount/etc already run through parseFloat() -> real numbers.
  //   - POST/PUT /manager/expenses: raw `RETURNING *` row, snake_case
  //     keys, and `amount` (a DECIMAL column) comes through as a
  //     STRING, not a number, since it was never parseFloat'd.
  // This factory checks both key casings AND safely parses amount
  // regardless of whether it arrives as num or String.
  factory Expense.fromBackendJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: _toDouble(json['amount']),
      description: json['description'] ?? '',
      date: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'].toString())
          : (json['expense_date'] != null
              ? DateTime.parse(json['expense_date'].toString())
              : DateTime.now()),
      vendorName: json['vendorName'] ?? json['vendor_name'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      referenceNumber: json['referenceNumber'] ?? json['reference_number'],
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
      isRecurring: json['isRecurring'] ?? json['is_recurring'] ?? false,
      recurringIntervalDays: json['recurringIntervalDays'] ?? json['recurring_interval_days'],
      notes: json['notes'],
    );
  }

  // ─────────────────────────────────────────────
  // FACTORY FROM FRONTEND JSON (camelCase) — for local/in-memory use
  // ─────────────────────────────────────────────
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: _toDouble(json['amount']),
      description: json['description'],
      date: DateTime.parse(json['date']),
      vendorName: json['vendorName'],
      paymentMethod: json['paymentMethod'],
      referenceNumber: json['referenceNumber'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      isRecurring: json['isRecurring'] ?? false,
      recurringIntervalDays: json['recurringIntervalDays'],
      notes: json['notes'],
    );
  }

  // ─────────────────────────────────────────────
  // TO JSON (camelCase) — for local/in-memory use, e.g. passing an
  // Expense between widgets. Do NOT send this directly to the
  // backend for create/update — use toBackendJson() instead.
  // ─────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
    'vendorName': vendorName,
    'paymentMethod': paymentMethod,
    'referenceNumber': referenceNumber,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'isRecurring': isRecurring,
    'recurringIntervalDays': recurringIntervalDays,
    'notes': notes,
  };

  // ─────────────────────────────────────────────
  // TO BACKEND JSON (snake_case) — use this for POST /manager/expenses
  // and PUT /manager/expenses/:id. expenseController.js destructures
  // the request body as expense_date, vendor_name, payment_method,
  // reference_number, is_recurring, recurring_interval_days — sending
  // toJson()'s camelCase keys instead means every one of those fields
  // silently arrives as undefined and gets dropped.
  // ─────────────────────────────────────────────
  Map<String, dynamic> toBackendJson() => {
    'category': category.name,
    'amount': amount,
    'description': description,
    'expense_date': date.toIso8601String().split('T').first, // DATE column, not TIMESTAMP
    'vendor_name': vendorName,
    'payment_method': paymentMethod,
    'reference_number': referenceNumber,
    'is_recurring': isRecurring,
    'recurring_interval_days': recurringIntervalDays,
    'notes': notes,
  };

  // ─────────────────────────────────────────────
  // COMPUTED PROPERTIES
  // ─────────────────────────────────────────────
  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';

  bool get isHighValue => amount >= 50000;
  bool get isMediumValue => amount >= 10000 && amount < 50000;
  bool get isLowValue => amount < 10000;

  // ─────────────────────────────────────────────
  // SAFE NUMERIC PARSING
  // ─────────────────────────────────────────────
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}