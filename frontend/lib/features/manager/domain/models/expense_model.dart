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

  // Computed properties
  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  
  bool get isHighValue => amount >= 50000;
  bool get isMediumValue => amount >= 10000 && amount < 50000;
  bool get isLowValue => amount < 10000;

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

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: json['amount'].toDouble(),
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
}