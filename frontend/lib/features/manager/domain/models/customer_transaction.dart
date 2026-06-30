import 'package:flutter/material.dart';

enum TransactionType {
  fuelPurchase,
  pointsRedemption;

  String get displayName {
    switch (this) {
      case TransactionType.fuelPurchase:
        return 'Fuel Purchase';
      case TransactionType.pointsRedemption:
        return 'Points Redemption';
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.fuelPurchase:
        return Colors.green;
      case TransactionType.pointsRedemption:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.fuelPurchase:
        return Icons.local_gas_station;
      case TransactionType.pointsRedemption:
        return Icons.card_giftcard;
    }
  }
}

class CustomerTransaction {
  final String id;
  final String customerId;
  final double amount;
  final double liters;
  final DateTime date;
  final String pumpId;
  final String attendantName;
  final int pointsEarned;
  final TransactionType type;

  CustomerTransaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.liters,
    required this.date,
    required this.pumpId,
    required this.attendantName,
    required this.pointsEarned,
    required this.type,
  });

  String get formattedAmount => 'KES ${amount.toStringAsFixed(0)}';
  String get formattedLiters => '${liters.toStringAsFixed(1)} L';
  String get formattedPoints => type == TransactionType.fuelPurchase ? '+$pointsEarned pts' : '-$pointsEarned pts';
  String get formattedDate => _formatDate(date);
  String get formattedTime => _formatTime(date);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today';
    }
    if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'amount': amount,
    'liters': liters,
    'date': date.toIso8601String(),
    'pumpId': pumpId,
    'attendantName': attendantName,
    'pointsEarned': pointsEarned,
    'type': type.name,
  };

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: json['id'],
      customerId: json['customerId'],
      amount: json['amount'],
      liters: json['liters'],
      date: DateTime.parse(json['date']),
      pumpId: json['pumpId'],
      attendantName: json['attendantName'],
      pointsEarned: json['pointsEarned'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.fuelPurchase,
      ),
    );
  }
}