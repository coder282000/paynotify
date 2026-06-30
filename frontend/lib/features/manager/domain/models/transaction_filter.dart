// lib/features/manager/domain/models/transaction_filter.dart

import 'package:flutter/material.dart';

enum TransactionType {
  all('All'),
  mpesa('M-Pesa'),
  cash('Cash'),
  card('Card');

  final String displayName;
  const TransactionType(this.displayName);
  
  IconData get icon {
    switch (this) {
      case TransactionType.all:
        return Icons.all_inclusive;
      case TransactionType.mpesa:
        return Icons.phone_android;
      case TransactionType.cash:
        return Icons.money;
      case TransactionType.card:
        return Icons.credit_card;
    }
  }
}

enum TransactionStatus {
  all('All'),
  completed('Completed'),
  pending('Pending'),
  failed('Failed');

  final String displayName;
  const TransactionStatus(this.displayName);
  
  IconData get icon {
    switch (this) {
      case TransactionStatus.all:
        return Icons.all_inclusive;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.failed:
        return Icons.error;
    }
  }
  
  Color get color {
    switch (this) {
      case TransactionStatus.all:
        return Colors.grey;
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }
}

class TransactionFilter {
  DateTimeRange? dateRange;
  TransactionType? type;
  TransactionStatus? status;
  String? pumpId;
  String? attendantId;
  double? minAmount;
  double? maxAmount;
  String? searchQuery;

  TransactionFilter({
    this.dateRange,
    this.type,
    this.status,
    this.pumpId,
    this.attendantId,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
  });

  bool get hasFilters => 
      dateRange != null ||
      type != null ||
      status != null ||
      pumpId != null ||
      attendantId != null ||
      minAmount != null ||
      maxAmount != null ||
      (searchQuery?.isNotEmpty ?? false);

  void clear() {
    dateRange = null;
    type = null;
    status = null;
    pumpId = null;
    attendantId = null;
    minAmount = null;
    maxAmount = null;
    searchQuery = null;
  }

  TransactionFilter copyWith({
    DateTimeRange? dateRange,
    TransactionType? type,
    TransactionStatus? status,
    String? pumpId,
    String? attendantId,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) {
    return TransactionFilter(
      dateRange: dateRange ?? this.dateRange,
      type: type ?? this.type,
      status: status ?? this.status,
      pumpId: pumpId ?? this.pumpId,
      attendantId: attendantId ?? this.attendantId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}